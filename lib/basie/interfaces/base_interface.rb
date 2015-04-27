#basic interface, should be the root class for all Basie interfaces.
#an interface is a singleton object that returns Basie data
#or accepts basie data.
class Basie::Interface

	attr_reader :route 	#this is the url route

	def app
		Sinatra::Application
	end

	#a skeleton constructor makes sure this winds up in the interpreter list.
	def initialize(params = {})
		#allow the user to set the root as an override to whatever default is set by the constructor
		if params[:root]
			@root = params[:root]
		else
			params[:root] = @root
		end
		
		#allow the user to set an array of routes, but if this is omitted, then set it to the token "all"
		@routes = params[:routes] || :all

		#check to see if we've already registered this interpreter.
		unless Basie.interfaces.any?{|i| self.class === i}
			Basie.interfaces.push self
		end
		#otherwise silently fail.
	end

	#encapsulates boilerplate for if the developer has specified
	#we should use this route, in case the developer only wants to provide access
	#to a limited number of data pathways.
	def route_check(route)
		if (@routes == :all) || (@routes.include?(route))
			yield
		end
	end

	#gives you a context in which you can parse parameters given to a table setting.
	#this will only give you the comment part of any given table parameter line.
	def parse_for_table(table, table_comment); end

	#gives you a context in which you can parse a column's content
	def parse_for_column(column, column_comments); end

	def setup_paths(table); end
end
