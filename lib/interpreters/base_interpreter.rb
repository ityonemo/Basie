#basic intrepreter, should be the root class for all Basie interpreters.
#an interpreter is a singleton object that returns Basie data
#or accepts basie data.
class Basie::Interpreter

	attr_reader :route 	#this is the url route

	def app
		Sinatra::Application
	end

	#a skeleton constructor makes sure this winds up in the interpreter list.
	def initialize(params = {})
		#allow the user to set the route as an override to whatever default is set by the constructor
		if params.has_key?(:route)
			@route = params[:route]
		end

		#check to see if we've already registered this interpreter.
		unless Basie.interpreters.any?{|i| self.class === i}
			Basie.interpreters.push self
		end
		#otherwise silently fail.
	end

	#gives you a context in which you can parse parameters given to a table setting.
	#this will only give you the comment part of any given table parameter line.
	def parse_for_table(table, table_comment); end

	#gives you a context in which you can parse a column's content
	def parse_for_column(column, column_comments); end

	def setup_paths(table); end
end

#####################################################################
## ALSO WE WILL DEFINE A USEFUL FUNCTION HERE FOR ALL TO SHARE.

def Basie::rec_encode(ah)
	# a recursive encoding function that works on arrays and hashes.
	# designed to fix: strings to be UTF-8, BigDecimals to be strings.
	if Array === ah
		ah.map{|e| Basie::rec_encode(e)}
	elsif Hash === ah
		t = Hash.new
		ah.each{|k,v| t[k] = Basie::rec_encode(v)}
		t
	elsif String === ah
		ah.force_encoding(Encoding::UTF_8)
	elsif BigDecimal === ah
		format("%.2f", ah)
	else
		ah
	end
end