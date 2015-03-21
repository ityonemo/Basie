#forward the definition of the Basie class
class Basie; end

#creates an error which happens when there is a problem in Basie definition
class Basie::DefinitionError < StandardError; end

#for when you make a primary key not called "id"
class Basie::PrimaryKeyError < Basie::DefinitionError; end

#for when you don't have a foreign key that you're looking for
class Basie::NoTableError < Basie::DefinitionError; end

#for when you have a wierd type definition
class Basie::BadTypeError < Basie::DefinitionError; end


###############################################
## OTHER OOPSES

#creates an error when an object that should be a hash is malformed.
class Basie::HashError < ArgumentError; end


###############################################
## ACCESS FAILS

#errors that happen when access fails
class Basie::NoEntryError < StandardError; end

#an error for when a hash doesn't exist
class Basie::NoHashError < Basie::NoEntryError; end

#an error for when a hash doesn't exist
class Basie::NoIdError < Basie::NoEntryError; end