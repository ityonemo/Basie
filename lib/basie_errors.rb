#forward the definition of the Basie class
class Basie
end

#creates an error which happens when there is a problem in Basie definition
class Basie::DefinitionError < StandardError  
end  

#creates an error when an object that should be a hash is malformed.
class Basie::HashError < ArgumentError
end

#errors that happen when access fails
class Basie::NoEntryError < StandardError
end

#an error for when a hash doesn't exist
class Basie::NoHashError < Basie::NoEntryError
end

#an error for when a hash doesn't exist
class Basie::NoIdError < Basie::NoEntryError
end