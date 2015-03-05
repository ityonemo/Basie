Gem::Specification.new do |s|
  s.name    = 'basie'
  s.version = '0.0.1'
  s.summary = 'A gem that enhances Sinatra with DB support'

  s.author   = 'Isaac Yonemoto'
  s.email    = 'isaac@indysci.org'
  s.homepage = 'https://github.com/ityonemo/Basie'

  # Include everything in the lib folder
  s.files = Dir['lib/**/*']

  # Supress the warning about no rubyforge project
  s.rubyforge_project = 'nowarning'
end
