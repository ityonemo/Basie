require 'scrypt'
require_relative "base_interface"

enable :sessions

class Basie::UserInterface < Basie::Interface

	def initialize(params={})
		@@host_table = nil

		#register the JSON mime type with the application.
		app.configure do
  			app.mime_type :plain, 'text/plain'
  		end

  		#use a universal salt for the entire application.
  		@@univ_salt = params[:salt].to_s || "basie"

		super(params)
	end

	##########################################################################
	## UTILITY FUNCTIONS
	## these are kept as class functions so that they can be easily used outside of a class object.

	def self.hashstring(plaintext, salt)
		#generates the salted password from the plaintext password, the universal salt, and the individual salt.
		saltedtext = @@univ_salt + salt.to_s + plaintext
	end

	def self.check(password, plaintext, salt)
		#checks a password - should be a string against plaintext, salt pair.
		SCrypt::Password.new(password) == hashstring(plaintext, salt)
	end

	def self.encrypt(plaintext, salt)
		#encrypts the plaintext with the given salt (which also gets the universal salt appended)
		SCrypt::Password.create(hashstring(plaintext, salt))
	end

	def self.logincolumn
		@@logincolumn
	end

	#######################################################################################3
	## class functions

	def parse_for_table(table, table_comment)
		if (table_comment[0..9] == "user_table")
			#we can only have one user_table directive.
			if @@host_table
				raise(Basie::UserTableError, "can't have more than one user tables")
			end

			#assign a login column, if that's defined as a part of the user_table directive
			logincolumn = table_comment[10..-1].strip

			@@logincolumn = (logincolumn == "" ? :login : logincolumn.to_sym)

			#store the table as our class variable.
			@@host_table = table
		end
	end

	def setup_paths(table)
		#only set up paths once, and only relative to the appropriate host table.

		if (table == @@host_table)
			#produce a login form.
			#TODO:  Make HTML/CSS optional here.
			route_check(:loginform) do
				app.get("/loginform") do
					#loginforms has several options that are overrideable by passing parameters to the GET route

					#form_id:   overrides the form id (default: "login_form")
					#title:    overrides lname.capitalize for the title of the form.
					#
					#redirect:  instructs the resulting POST statement to redirect to a particular path afterwards.
					#    - "", <nil>: (default) creates a javascript statement that correctly fills in the path from the browser
					#    - "none", "false": passes a nil redirect path.
					#    - <any other string>: a path that is the passed string. 

					#OVERRIDE THE FORM'S ID
					form_id = params["form_id"] || "login_form"
					#SET THE NAME AND TITLE
					login_name = Basie::UserInterface.logincolumn.to_s
					login_title = params["title"] || login_name.capitalize

					#HANDLE A REDIRECT OPTION.
					#the redirect path to start off with.
					rd_string = ""
					#javascript to handle the redirect string.
					rd_js = ""
					case params["redirect"]
					when "", nil
						rd_js = ":javascript\n\tdocument.getElementById('redirect').value = window.location"
					when "none", "false"
						#do nothing.
					else
						rd_string = params["redirect"]
					end

					o = "%form##{form_id}(action='/login' method='POST')\n"
					o += "\t#form_#{login_name}\n"
					o += "\t\t%label(for='login_field')"
					o += "\t\t\t#{login_title}\n"
					o += "\t\t%input#login_field(type='text' name='#{login_name}')\n"
					o += "\t#form_password\n"
					o += "\t\t%label(for='password_field')"
					o += "\t\t\tPassword\n"
					o += "\t\t%input#password_field(type='password' name='password')\n"
					o += "\t#form_submit\n"
					o += "\t\t%input(type='submit' value='login')\n"
					o += "\t\t%input#redirect(type='hidden' name='redirect' value='#{rd_string}')\n"
					o += rd_js

					haml o
				end
			end

			#produce a way to log in.  should use HTML POST technique, for security reasons.
			route_check(:login) do
				app.post("/login") do
					#TODO:
					#check for an adversarial null login.

					begin
						#first retrieve the user name from the user table.
						q = table.data_by_query(Basie::UserInterface.logincolumn, params[Basie::UserInterface.logincolumn.to_s])
					rescue => c
						puts c.inspect
					end

					unless q
						403
					end

					#load up the passhash from the table into SCrypt and check it against the supplied password.
					if Basie::UserInterface.check(q[:passhash], params["password"], params[Basie::UserInterface.logincolumn.to_s])
						#set the login cookie

						session[:login] = params[Basie::UserInterface.logincolumn.to_s]

						#look to see if we have a redirect element.
						if params["redirect"]
							#then redirect
							redirect params["redirect"]
						else
							#or do nothing.
							200
						end
					else
						403
					end
				end
			end

			#produce a way to clear out the logout.
			route_check(:logout) do
				app.get("/logout") do
					session[:login] = nil
					if params["redirect"]
						redirect params["redirect"]
					else
						200
					end
				end
			end

			#produce a way to retrieve the login name from the session cookie
			#as validated by the server.
			route_check(:name) do
				app.get("/login") do
					content_type :plain
					body session[:login]
					200
				end
			end
		end
	end
end

