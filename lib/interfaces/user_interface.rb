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

	#######################################################################################3
	## class functions

	def parse_for_table(table, table_comment)
		if (table_comment[0..9] == "user_table")
			#we can only have one user_table directive.
			if @@host_table
				raise(Basie::UserTableError, "can't have more than one user tables")
			end

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

					#PARAMETER HANDLING

					#HANDLE A REDIRECT OPTION.
					#the redirect path to start off with.
					rd_string = ""
					#javascript to handle the redirect string.
					rdj_string = ""
					case params[:redirect]
					when "", nil
						rdj_string = ":javascript\n\tdocument.getElementById('redirect').value = window.location"
					when "none", "false"
						#do nothing.
					else
						rd_string = params[:redirect]
					end

					o = "%form(action='/login' method='POST')\n"
					o += "\t#login_name\n"
					o += "\t\t%label Login\n"
					o += "\t\t%input#login(type='text' name='login')\n"
					o += "\t#login_password\n"
					o += "\t\t%label Password\n"
					o += "\t\t%input#password(type='password' name='password')\n"
					o += "\t#login_submit\n"
					o += "\t\t%input(type='submit' value='login')\n"
					o += "\t\t%input#redirect(type='hidden' name='redirect' value='#{rd_string}')\n"
					o += rdj_string

					haml o
				end
			end

			#produce a way to log in.  should use HTML POST technique, for security reasons.
			route_check(:login) do
				app.post("/login") do
					#TODO:
					#check for an adversarial null login.

					#first retrieve the user name from the user table.
					q = table.data_by_query(:login, params[:login])

					#load up the passhash from the table into SCrypt and check it against the supplied password.
					if Basie::UserInterface.check(q[:password], params[:password], params[:login])
						#set the login cookie.
						session[:login] = params[:login]

						#look to see if we have a redirect element.
						if params[:redirect]
							#then redirect
							redirect params[:redirect]
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
					200
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

