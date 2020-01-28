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

desc "Create a new administrative unit from console"
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
    bestuursfunctierol = loket_db.get_bestuursfunctie_for_classification(klass_uri)
    triples << loket_db.create_administrative_body(unit, "#{klass_name} #{name}", klass_uri, bestuursfunctierol)
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
  personeelsdb.create_personeelsaantallen_for_csv("/data/personeelsaantallen.csv")

end

# CSV structure: KBO number | Name | Afkortings | Classification | Provincie | Werkingsgebied
desc "Create administrative units as well as its organen, bestuursfuncties, mock users and personeelsaantallen"
task :create_full_units_from_csv do
  puts "generating administrative units, organen, bestuursfuncties, mock users and personeelsaantallen from CSV"
  loket_db = LoketDb.new

  csv_path = "/data/bestuurseenheden.csv"
  rows = CSV.read(csv_path, encoding: 'utf-8')
  puts "Retrieved #{rows.length} rows from CSV"
  rows.each do |row|
    # Initialize URI database
    classifications = loket_db.unit_classifications.sort_by{ |kl| kl[:name] }
    provincies = loket_db.unit_provincies.sort_by{ |kl| kl[:name] }

    # Parse CSV
    kbo = row[0]
    name = row[1]
    if (row[2] != nil)
      afkortings = row[2].split(";")
    else
      afkortings = []
    end
    classification = classifications.find{ |kl| kl[:name] == row[3] }
    provincie = provincies.find{ |kl| kl[:name] == row[4] }
    werkingsgebied_uri = RDF::URI.new(row[5])

    (unit, triples) = loket_db.create_administrative_unit(name, kbo, werkingsgebied_uri, classification[:uri], provincie[:uri], afkortings)
    unit_classifications = loket_db.body_classifications_for_unit(classification[:uri].value.to_s)
    unit_classifications.each do |unit_classification_uri, unit_classification_name|
      bestuursfunctierol = loket_db.get_bestuursfunctie_for_classification(unit_classification_uri)
      triples << loket_db.create_administrative_body(unit, "#{unit_classification_name} #{name}", unit_classification_uri, bestuursfunctierol)
    end
    loket_db.write_ttl_to_file(name.gsub(/\s/,'-')) do |file|
      file.write triples.dump(:ntriples)
    end

    begin
      # UNIT_MEASURES.each do |unit_measure|
      #   create_personeelsaantallen_for_bestuurseenheid(bestuurseenheid, uuid, name, classification, unit_measure)
      # end
    rescue StandardError => e
      puts e
      puts "Failed to create unit for #{classification} #{name}. Skipping this one."
    end
  end


  #personeelsdb = Personeelsdatabank.new
  #personeelsdb.create_full_units_from_csv("/data/bestuurseenheden.csv")

end
