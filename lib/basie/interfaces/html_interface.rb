require_relative "base_interface"
require 'haml'

#HTML intrepreter.  Translates column data into HTML partials.
class Basie::HTMLInterface < Basie::Interface

	def initialize(params={})
		@root = "/html"
		@formroot = params[:formroot] || "/htmlform"
		@multiformroot = params[:multiformroot] || "/htmlmultiform"
		params[:formroot] = params[:formroot] || @formroot

		super(params)

		#parameters has to be a class variable because it will be accessed
		#by some universal converter functions.  This is OK, though, because
		#basie interfaces are singletons.  consider fixing this to be less hacky.

		@@params = params
	end

	#################
	#ROUTE OPTIONS:
	# :all      -all routes
	# :table    -get the full table
	# :id       -get a row by id (or hash)
	# :search   -search for a row
	# :query    -search for a row by query

	#################
	#CSS-ING-OPTIONS:

	#for the table view:

	# table_id sets the id for the entire table, this should correlate to the table name
	# :table_id => (Proc) sets a procedural translation
	# :table_id => (Hash) sets a hash translation
	# :table_id => false suppresses the column header ids

	# :header_class => false suppresses the tr "header" class

	#for the single entry view:
	# entry_id sets the id for the entire list, this should correlate to the table name
	# :entry_id defaults to true
	# :entry_id => false suppresses entry id
	# :entry_id => (value) sets the id for entry view

	#for the html entry form.

	# form_id sets the id for the entire form, this should correlate to the table name
	# :form_id => (Proc) sets a procedural translation
	# :form_id => (Hash) sets a hash translation
	# :form_id => false suppresses form id

	# column_id sets the id for the div encapsulating each column, this should correlate to the column name
	# :column_id => (Proc) sets a procedural translation
	# :column_id => (Hash) sets a hash translation
	# :column_id => false suppresses form id

	#shared by all views.
	# column_class sets the class for various informational tags, this should correlate to the column name
	# :column_class => (Proc) sets a procedural translation
	# :column_class => (Hash) sets a hash translation
	# :column_class => false suppresses column class


	def self.hinsert(table, cname, val, indents)
		column = table.columns[cname]

		case column.params[:htag]
		when :url
			"\n" + "\t" * indents + "%a(href=\"#{val}\") "
		when :email
			"\n" + "\t" * indents + "%a(href=\"mailto:#{val}\") "
		when :tel
			tval = val.split(/\D/).join
			"\n" + "\t" * indents + "%a(href=\"tel:#{tval}\") "
		else
			#check to see if we're a foreign key
			if (column.params[:link]) && (column.type == :foreign_key)
				key_ref = table.foreignkeys[cname]
				"\n" + "\t" * indents + "%a(href=\"#{@@params[:root]}/#{key_ref}/#{val}\") "
			else
				""
			end
		end
	end

	################################################################
	## HELPER class functions that translate parameters to haml bits.
	def self.hml(tag, param_tag, suffix = "")
		hmfn = @@params[param_tag]

		#introspective assignment of the prefix.
		prefix = case param_tag.to_s.split("_")[1]
		when "id"
			"#"
		when "class"
			"."
		else
			raise ArgumentError, "incorrect parameter tag type"
		end

		case hmfn
		when Proc
			hmfn.call(tag) ? prefix + hmfn.call(tag) : ""
		when Hash
			hmfn[tag] ? prefix + hmfn[tag] : ""
		when FalseClass
			""
		when NilClass, TrueClass
			prefix + tag.to_s + suffix
		end
	end

	################################################################
	## HELPER class functions that translate parameters to haml bits.

	def self.to_table(data, table)

		tid = hml(table.name, :table_id)
		header = "%table" + tid

		#check to see if our table is going to be blank.
		if data.length == 0
			return header
		end

		hcs = @@params[:header_class] == false ? "" : ".header"

		#add the header row which contains all of the common keys.
		header += "\n\t%tr#{hcs}"

		#add the header rows.
		header += data[0].keys.map{|k| "\n\t\t%th#{hml(k, :column_class)} #{k}"}.join

		#then add all of the data rows.
		header + data.each.map {|h| "\n\t%tr" + h.keys.map {|k|"\n\t\t%td#{hml(k, :column_class)} #{hinsert(table,k,h[k],3)} #{h[k]}"}.join}.join
	end

	def self.to_dl(data, table)
		#convert a single hash data into a dl.

		#set up the output.
		dlid = hml(table.name, :entry_id, "_data")
		"%dl#{dlid}" + data.keys.map{|k| "\n\t%dt#{hml(k, :column_class)} #{k}\n\t%dd#{hml(k, :column_class)} #{hinsert(table,k,data[k],2)} #{data[k]}"}.join
	end

	##############################################################
	## INPUT FORMS

	#blank input form
	def self.to_if(table, data={})
		fid = hml(table.name, :form_id, "_input")
		actionsuffix = data[:id] ? "/#{data[:id]}" : ""

		o = "%form#{fid}(action=\"/data#{actionsuffix}\" method=\"post\")\n"

		table.columns.each_key do |column|

			cid = hml(column, :column_id, "_input")
			ccs = hml(column, :column_class)

			htag = table.columns[column].params[:htag]

			dtxt = data[column] ? "value=\"#{data[column]}\"" : ""

			case (htag)
			when :suppress, :hash, :primary_key #do nothing
			when :textarea
				o += "\t%div#{cid}\n"
				o += "\t\t%label#{ccs} #{column}\n"
				o += "\t\t%textarea#{ccs}(name=\"#{column}\" #{dtxt})\n"
			else
				o += "\t%div#{cid}\n"
				o += "\t\t%label#{ccs} #{column}\n"
				o += "\t\t%input#{ccs}(name=\"#{column}\" type=\"#{htag}\" #{dtxt})\n"
			end
		end
		o
	end

	def self.to_mfr(table)
		#note that this uses extensive 'internally-hosted' javascript.  Also, this isn't jQuery-dependent.
		substitution = {}

		names = table.columns.keys.reject{|k| table.suppresslist.include? k}.map{|k| k.to_s}
		titles = names.map{|name| substitution[name] || name}
		types = table.columns.values.map{|c| c.params[:htag]}

%(:javascript
	var input_titles = #{titles.to_json};
	var input_names = #{names.to_json};
	var input_types = #{types.to_json};

%form
	%label(for="#{table.name}count")
		number of #{table.name}
	%input##{table.name}count(name="#{table.name}count" type="number" min="1" step="1" value="1")

	%table##{table.name}table
		%thead##{table.name}titles
		%tbody##{table.name}data

	%input(type="submit")

:javascript
#{Basie::HTMLInterface.mlfhtml(table.name)}
)
	end

	##########################################################################
	## PARSING OPTIONS IN THE TABLE

	@@htaghash = {
		#custom htags as defined by comments
		"tel" 			=> :tel,
		"url" 			=> :url,
		"email" 		=> :email,
		"suppress" 		=> :suppress,	#note that there is no "suppress" type in the standard HTML lexicon.
		"hash" 			=> :hash,		#this exists to be able to suppress hashes in input forms, but they should be displayed.
		#"options" 		=> :option,		#TO BE IMPLEMENTED
		#as defined by type
		:primary_key	=> :primary_key,#this exists to be able to suppress primary_key in input form, but they should be displayed.
		:integer		=> :number,
        :bigint			=> :number,
        :numeric		=> :number,
        :date			=> :date,
        :timestamp		=> :datetime,
        :varchar		=> :text,
        :char			=> :text,
        :foreign_key	=> :text,
        :text			=> :textarea,
        :boolean		=> :checkbox,
        :blob			=> :file
	}
	def parse_for_column(column, columnsettings)

		#set this to be initially true.
		column.params[:link] = true

		columnsettings.each do |statement|
			#check to see if this is an htag statement.
			if @@htaghash.has_key?(statement)
				column.params[:htag] = @@htaghash[statement]
			end

			#check to see if this is a no_link statement
			if statement == "nolink"
				column.params[:link] = false
			end
		end

		#set a default htag parameter based on the current type of the object.
		column.params[:htag] = column.params[:htag] || @@htaghash[column.type]
	end

	#################################################################

	def setup_paths(table)

		#table should be a symbol to the name of the table.
		tableroot = "#{@root}/#{table.name}"

		##############################################################
		## HTML-BASED data access.
		## /html/[name] - the entire table
		## /html/[name]/[query] - queries searchable, or id/hash
		## /html/[name]/[column]/[match] - queries all database rows that match expected

		#register a path to the table.
		route_check(:table) do
			app.get (tableroot) do
				begin
					#get the data
					res = table.entire_table(:session => session)
					haml Basie::HTMLInterface.to_table(res, table)
				rescue SecurityError
					403
				end
			end
		end

		route_check(:id) do
			#register for id-based searching.
			app.get (tableroot + "/:query") do |query|

				#get the data
				begin

					res = table.data_by_id(query, :session => session)

					haml Basie::HTMLInterface.to_dl(res, table)
				rescue SecurityError
					403
				rescue ArgumentError
					400
				rescue Basie::NoEntryError
					404
				end
			end
		end

		#register a path for querying
		route_check(:query) do
			app.get(tableroot + "/:cstr/:qry") do |cstr, qry|
				#get the data
				begin
					res = table.data_by_query(cstr, qry, :session => session)
					case res
					when Array
						return 404 if res.length == 0
						haml Basie::HTMLInterface.to_table(res, table)
					when Hash; haml Basie::HTMLInterface.to_dl(res, table)
					end
				rescue SecurityError
					403
				rescue ArgumentError
					400
				rescue Basie::NoEntryError
					404
				end
			end
		end

		#register a path for inputting and modifying data
		route_check(:forms) do
			tableformroot = "#{@formroot}/#{table.name}"

			app.get (tableformroot) do
				haml Basie::HTMLInterface.to_if(table)
			end

			app.get (tableformroot + "/:query") do |query|
				res = table.data_by_id(query, :session => session)
				haml Basie::HTMLInterface.to_if(table, res)
			end
		end

		#create a path for a multiple data form.
		route_check(:multiform) do
			multiformroot = "#{@multiformroot}/#{table.name}"

			app.get (multiformroot) do
				haml Basie::HTMLInterface.to_mfr(table)
			end
		end
	end
end

################################################################################
## THIS IS WHERE WE STORE THE JAVASCRIPT.

class Basie::HTMLInterface
	def self.mlfhtml(tname)
%(
	window.addEventListener("load", initialize);
	document.getElementById("#{tname}count").addEventListener("change", matchcount);
	//we expect the following variables to be set elsewhere in the script.
	//input_titles (Array of strings, determines the labels)
	//input_names (Array of strings, determines the names)
	//input_types (Array, determines the input field types)
	//these two arrays should have the same number of indices, but the templating
	//procedure will use the names array.

	function initialize(){
		headerline();
		matchcount();
	}

	function countrows(){
		return document.getElementById("#{tname}data").children.length
	}

	function matchcount(){
		var count = parseInt(document.getElementById("#{tname}count").value)

		if (count < countrows()){
			//nuke the rows that are too many.
			for (var idx = countrows()-1; idx >= count; idx--){
				var oldrow = document.getElementById("rowindex" + idx);
				document.getElementById("#{tname}data").removeChild(oldrow);
			}
		}
		else if (count > countrows()){
			//add rows
			for (var idx = countrows(); idx < count; idx++){
				var newrow = document.createElement("tr");
				newrow.id = "rowindex" + idx;
				newrow.innerHTML = bodyline(idx);
				document.getElementById("#{tname}data").appendChild(newrow);
			}
		}
	}

	function headerline(){
		//scan through the input names array
		var thline = "";
		for (var jdx = 0; jdx < input_titles.length; jdx++){
			thline += "<th>" + input_titles[jdx] + "</th>";
		}

		var headrow = document.createElement("tr")
		headrow.innerHTML = thline;
		document.getElementById("#{tname}titles").appendChild(headrow);
	}

	function bodyline(idx){
		//scan through the input names array
		var tdline = "";
		for (var jdx = 0; jdx < input_names.length; jdx++){
			tdline += "<td><input name='" + input_names[jdx] + "'" +
			(input_types[jdx] ? " type='" + input_types[jdx] + "'": "") + "></input></td>";
		}
		return tdline;
	}
)
	end
end