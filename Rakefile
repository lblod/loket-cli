require 'rubygems'
require 'optparse'
require 'linkeddata'
require 'uri'
require_relative 'lib/loket-db'
require_relative 'lib/personeelsdatabank'

task :default => :create_admin_unit

def until_valid(question, options = nil, &block)
  if options
    puts question
    options.each do |option|
      puts "[#{option[:id]}] #{option[:name]}"
    end
    print "please specify your choice: "
  else
    print "#{question}: "
  end
  STDOUT.flush
  klass_input = STDIN.gets.chomp
  verified = block.call(klass_input)
  if verified
    return klass_input
  else
    puts "invalid input"
    until_valid(question, options, &block)
  end
end

desc "Create a new administrative unit"
task :create_admin_unit do
  puts "generating a new administrative unit"
  loket_db = LoketDb.new
  eenheid_classificaties = loket_db.unit_classifications.sort_by{ |kl| kl[:id] }
  klass_input = until_valid("Select classification of the administrative unit", eenheid_classificaties) do |input|
    eenheid_classificaties.find{ |kl| kl[:id] == input.to_i }
  end
  klass = eenheid_classificaties.find{ |kl| kl[:id] == klass_input.to_i }
  eenheid_provincies = loket_db.unit_provincies.sort_by{ |kl| kl[:id] }
  klass_input = until_valid("Select provincie of the administrative unit", eenheid_provincies) do |input|
    eenheid_provincies.find{ |kl| kl[:id] == input.to_i }
  end
  klass_provincie = eenheid_provincies.find{ |kl| kl[:id] == klass_input.to_i }
  kbonumber = until_valid("KBO number") do |input|
    input.length == 10
  end
  name = until_valid("Name") do |input|
    input.length > 0
  end
  number_afkortings = until_valid("How many afkortings ?") do |input|
    input.length > 0
  end
  afkortings = []
  for x in 0..number_afkortings.to_i-1
    afkortings << until_valid("Afkorting #{x+1} ?") do |input|
      input.length > 0
    end
  end
  werkingsgebied = until_valid("Werkingsgebied (URI)") do |input|
    input =~ URI.regexp
  end
  (unit, triples) = loket_db.create_administrative_unit(name, kbonumber, RDF::URI.new(werkingsgebied), klass[:uri], klass_provincie[:uri], afkortings)
  classifications = loket_db.body_classifications_for_unit(klass[:uri].value.to_s)
  classifications.each do |klass_uri, klass_name|
    triples << loket_db.create_administrative_body(unit, "#{klass_name} #{name}", klass_uri)
  end
  loket_db.write_ttl_to_file(name.gsub(/\s/,'-')) do |file|
    file.write triples.dump(:ntriples)
  end
end

task :create_mock_user do
  puts "generating mock user"
  loket_db = LoketDb.new
  bestuurseenheid_uuid = until_valid("Bestuurseenheid uuid") do |input|
    input.length > 0
  end
  filename = until_valid("Filename (without the extension)") do |input|
    input.length > 0
  end
  loket_db.write_mock_user_to_file(bestuurseenheid_uuid, filename)
end

# CSV structure: bestuurseenheid URI, classificatie label, pref label, uuid
desc "Create personeelsaantallen for administrative unit"
task :create_personeelsaantallen_for_csv do
  puts "generating personeelsaantallen for besturseenheden from CSV"
  personeelsdb = Personeelsdatabank.new
  personeelsdb.create_personeelsaantallen_for_csv("/data/bestuurseenheden.csv")

end
