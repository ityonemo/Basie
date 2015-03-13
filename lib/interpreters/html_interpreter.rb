require_relative "base_interpreter"
require 'haml'

#JSON intrepreter, should be the root class for all Basie interpreters.
class Basie::HTMLInterpreter < Basie::Interpreter

	def initialize(params={})
		@route = "/html"
		super(params)

		@@params = params
	end

	#################
	#CSS-ING-OPTIONS:

	#for the table view:

	# :no_table_id => true suppresses table id
	# :table_id => (value) sets table id

	# :no_header_class => true suppresses header class
	# :header_class => (value) sets header class

	# :header_id => (Proc) sets a procedural translation
	# :header_id => (Hash) sets a hash translation
	# :header_id => false suppresses the column header ids

	#for the single entry view:
	# :no_entry_id => true suppresses entry id
	# :entry_id => (value) sets the id for entry view

	#shared by both views.
	# :column_class => (Proc) sets a procedural translation
	# :column_class => (Hash) sets a hash translation
	# :column_class => false suppresses column class

	def self.hinsert(table, cname, val, indents)
		case table.columns[cname].params[:htag]
		when :url
			"\n" + "\t" * indents + "%a(href=\"#{val}\") "
		when :email
			"\n" + "\t" * indents + "%a(href=\"mailto:#{val}\") "
		when :tel
			tval = val.split(/\D/).join
			"\n" + "\t" * indents + "%a(href=\"tel:#{tval}\") "
		else
			""
		end
	end

	################################################################
	## HELPER class functions that translate parameters to haml bits.
	def self.ccs(col)
		ccfn = @@params[:column_class]
		case ccfn
		when Proc
			ccfn.call(col) ? "." + ccfn.call(col) : ""
		when Hash
			ccfn[col] ? "." + ccfn[col] : ""
		when FalseClass
			""
		when NilClass
			"." + col.to_s
		end
	end

	def self.hid(col)
		hifn = @@params[:header_id]
		case hifn
		when Proc
			hifn.call(col) ? "#" + hifn.call(col) : ""
		when Hash
			hifn[col] ? "#" + hifn[col] : ""
		when FalseClass
			""
		when NilClass
			"#" + col.to_s + "_header"
		end
	end

	def self.to_table(data, table)

		tid = @@params[:table_id] || table.name
		tid = @@params[:no_table_id] ? "" : "#" + tid.to_s

		hid = @@params[:header_class] || "header"
		hid = @@params[:no_header_class] ? "" : "." + hid.to_s

		header = "%table" + tid

		#check to see if our table is going to be blank.
		if data.length == 0 
			return header
		end

		#add the header row which contains all of the common keys.
		header += "\n\t%tr#{hid}" 

		header += data[0].keys.map{|k| "\n\t\t%th#{ccs(k)}#{hid(k)} #{k}"}.join
		#then add all of the data rows.

		header + data.each.map {|h| "\n\t%tr" + h.keys.map {|k|"\n\t\t%td#{ccs(k)} #{hinsert(table,k,h[k],3)} #{h[k]}"}.join}.join
	end

	def self.to_dl(data, table)
		#convert a single hash data into a dl.

		eid = @@params[:entry_id] || (table.name.to_s + "_data")
		eid = @@params[:no_entry_id] ? "" : "#" + eid.to_s

		#set up the output.
		"%dl#{eid}" + data.keys.map{|k| "\n\t%dt#{ccs(k)} #{k}\n\t%dd#{ccs(k)} #{hinsert(table,k,data[k],2)} #{data[k]}"}.join
	end

	@@htaghash = {
		#custom htags as defined by comments
		"tel" 			=> :tel,
		"url" 			=> :url,
		"email" 		=> :email,
		"suppress" 		=> :suppress,	#note that there is no "suppress" type in the standard HTML lexicon.
		"hash" 			=> :suppress,
		"options" 		=> :option,
		"picker" 		=> :picker,
		#as defined by type
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

		columnsettings.each do |statement|
			#check to see if this is an htag statement.
			if @@htaghash.has_key?(statement)
				column.params[:htag] = @@htaghash[statement]
			end
		end

		#set a default htag parameter based on the current type of the object.
		column.params[:htag] = column.params[:htag] || @@htaghash[column.type]
	end

	def setup_paths(table)
		#table should be a symbol to the name of the table.
		fullroute = "#{@route}/#{table.name}"

		##############################################################
		## HTML-BASED data access.
		## /html/[name] - the entire table
		## /html/[name]/[query] - queries searchable, or id/hash
		## /html/[name]/[column]/[match] - queries all database rows that match expected

		#register a path to the table.
		app.get (fullroute) do
			#get the data
			res = table.entire_table
			haml Basie::HTMLInterpreter.to_table(res, table)
		end

		app.get (fullroute + "/:query") do |query|
			#get the data
			res = table.data_by_id(query)
			haml Basie::HTMLInterpreter.to_dl(res, table)
		end

		app.get (fullroute + "/:column/:query") do |column, query|
			#get the data
			res = table.data_by_query(column, query)
			haml Basie::HTMLInterpreter.to_dl(res, table)
		end
	end
end

