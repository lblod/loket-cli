# coding: utf-8
require 'linkeddata'
require 'date'
require 'securerandom'
require 'tempfile'

class LoketDb
  ORG = RDF::Vocab::ORG
  FOAF = RDF::Vocab::FOAF
  SKOS = RDF::Vocab::SKOS
  DC = RDF::Vocab::DC
  PROV = RDF::Vocab::PROV
  RDFS = RDF::Vocab::RDFS
  MU = RDF::Vocabulary.new("http://mu.semte.ch/vocabularies/core/")
  PERSON = RDF::Vocabulary.new("http://www.w3.org/ns/person#")
  PERSOON = RDF::Vocabulary.new("http://data.vlaanderen.be/ns/persoon#")
  MANDAAT = RDF::Vocabulary.new("http://data.vlaanderen.be/ns/mandaat#")
  BESLUIT = RDF::Vocabulary.new("http://data.vlaanderen.be/ns/besluit#")
  EXT = RDF::Vocabulary.new("http://mu.semte.ch/vocabularies/ext/")
  ADMS = RDF::Vocabulary.new('http://www.w3.org/ns/adms#')
  BASE_IRI='http://data.lblod.info/id'

  def create_gebied(naam)
    triples = RDF::Repository.new
    gebied_uuid = SecureRandom.uuid
    gebied = RDF::URI.new("http://data.lblod.info/id/bestuurseenheden/#{gebied_uuid}")
    triples << [gebied, RDF.type, PROV.Location]
    triples << [gebied, MU.uuid, gebied_uuid]
    triples << [gebied, EXT.werkingsgebiedNiveau, "Gemeente"]
    triples << [gebied, RDFS.label, naam]
    [gebied, triples]
  end

  def create_administrative_unit(name, code, area, classification)
    triples = RDF::Repository.new
    uuid = SecureRandom.uuid
    iri = RDF::URI.new("http://data.lblod.info/id/bestuurseenheden/#{uuid}")
    triples << [iri, RDF.type, RDF::URI.new('http://data.vlaanderen.be/ns/besluit#Bestuurseenheid') ]
    triples << [iri, MU.uuid, uuid]
    triples << [iri, SKOS.prefLabel, name ]
    triples << [iri, BESLUIT.classificatie, classification]
    triples << [iri, BESLUIT.werkingsgebied, area]
    triples << [iri, EXT.kbonummer, code]
    triples << [iri, DC.identifier, code]
    return [iri, triples]
  end

  def create_administrative_body(unit, name, classification, start_date = Date.parse("2019-01-01"))
    triples = RDF::Repository.new
    orgaan_uuid = SecureRandom.uuid
    orgaan = RDF::URI.new("http://data.lblod.info/id/bestuursorganen/#{orgaan_uuid}")
    triples << [orgaan, RDF.type, BESLUIT.Bestuursorgaan ]
    triples << [orgaan, SKOS.prefLabel, name ]
    triples << [orgaan, MU.uuid, orgaan_uuid]
    triples << [orgaan, BESLUIT.bestuurt, unit]
    triples << [orgaan, BESLUIT.classificatie, classification]
    tijdsorgaan_uuid = SecureRandom.uuid
    tijdsorgaan = RDF::URI.new("http://data.lblod.info/id/bestuursorganen/#{tijdsorgaan_uuid}")
    triples << [tijdsorgaan, RDF.type, BESLUIT.Bestuursorgaan ]
    triples << [tijdsorgaan, MU.uuid, tijdsorgaan_uuid]
    triples << [tijdsorgaan, MANDAAT.isTijdspecialisatieVan, orgaan]
    triples << [tijdsorgaan, MANDAAT.bindingStart, start_date]
    triples
  end

  def unit_classifications
    [
      { id: 6, name: "Intercommunale", uri: RDF::URI.new('http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/5ab0e9b8a3b2ca7c5e000004')},
      { id: 1, name: "Autonoom gemeentebedrijf", uri: RDF::URI.new('http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/36a82ba0-7ff1-4697-a9dd-2e94df73b721')},
      { id: 2, name: "Autonoom provinciebedrijf", uri: RDF::URI.new('http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/80310756-ce0a-4a1b-9b8e-7c01b6cc7a2d')},
      { id: 3, name: "Hulpverleningszone", uri: RDF::URI.new('http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/ea446861-2c51-45fa-afd3-4e4a37b71562')},
      { id: 4, name: "Politiezone", uri: RDF::URI.new('http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/a3922c6d-425b-474f-9a02-ffb71a436bfc') },
      { id: 5, name: "OCMW vereniging", uri: RDF::URI.new('http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/cc4e2d67-603b-4784-9b61-e50bac1ec089')},
      { id: 7, name: "Provincie", uri: RDF::URI.new('http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/5ab0e9b8a3b2ca7c5e000000')},
      { id: 8, name: "Gemeente", uri: RDF::URI.new('http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/5ab0e9b8a3b2ca7c5e000001')},
      { id: 9, name: "OCMW", uri: RDF::URI.new('http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/5ab0e9b8a3b2ca7c5e000002')},
      { id: 10, name: "District", uri: RDF::URI.new('http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/5ab0e9b8a3b2ca7c5e000003')}

    ]
  end

  def body_classifications_for_unit(unit_klass)
    gemeente = {
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/4955bd72cd0e4eb895fdbfab08da0284': 'Burgemeester',
     'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/5ab0e9b8a3b2ca7c5e000005': 'Gemeenteraad',
                'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/5ab0e9b8a3b2ca7c5e000006': "College van Burgemeester en Schepenen"
    }
    ocmw = {
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/53c0d8cd-f3a2-411d-bece-4bd83ae2bbc9': "Voorzitter van het Bijzonder Comité voor de Sociale Dienst",
                'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/5ab0e9b8a3b2ca7c5e000007': "Raad voor Maatschappelijk Welzijn",
                'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/5ab0e9b8a3b2ca7c5e000008': "Vast Bureau",
                'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/5ab0e9b8a3b2ca7c5e000009': "Bijzonder Comité voor de Sociale Dienst"
    }
    provincie = {
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/5ab0e9b8a3b2ca7c5e00000c':  "Provincieraad",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/180a2fba-6ca9-4766-9b94-82006bb9c709':  "Gouverneur",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/5ab0e9b8a3b2ca7c5e00000d':  "Deputatie"
    }
    district = {
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/5ab0e9b8a3b2ca7c5e00000a':    "Districtsraad",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/9314533e-891f-4d84-a492-0338af104065':    "Districtsburgemeester",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/5ab0e9b8a3b2ca7c5e00000b':    "Districtscollege"
    }
    agb = {
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/013cc838-173a-4657-b1ae-b00c048df943':    "Raad van bestuur",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/0dbc70ec-6be9-4997-b8e1-11b6c0542382':    "Bevoegd beslissingsorgaan",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/b52094ff-21a2-4da8-8dbe-f513365d1528':    "Algemene vergadering"
    }
    apb = {
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/013cc838-173a-4657-b1ae-b00c048df943':    "Raad van bestuur",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/0dbc70ec-6be9-4997-b8e1-11b6c0542382':    "Bevoegd beslissingsorgaan",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/b52094ff-21a2-4da8-8dbe-f513365d1528':    "Algemene vergadering"
    }
    intergemeentelijk_samenwerkingsverband = {
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/5733254e-73ff-4844-8d43-7afb7ec726e8':    "Directiecomité",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/013cc838-173a-4657-b1ae-b00c048df943':    "Raad van bestuur",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/17e76b36-64a1-4db1-8927-def3064b4bf1':    "Regionaal bestuurscomité",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/b52094ff-21a2-4da8-8dbe-f513365d1528':    "Algemene vergadering"
    }
    hulpverleningszone = {
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/a9e30e31-0cd2-4f4a-9352-545c5d43be83': "Zoneraad"
    }
    politiezone = {
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/a9e30e31-0cd2-4f4a-9352-545c5d43be83': "Politieraad"
    }
    ocmw_vereniging = {
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/013cc838-173a-4657-b1ae-b00c048df943':    "Raad van bestuur",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/b52094ff-21a2-4da8-8dbe-f513365d1528':  "Algemene vergadering"
    }
    map = {
      'http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/5ab0e9b8a3b2ca7c5e000000': provincie,
      'http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/5ab0e9b8a3b2ca7c5e000003': district,
      'http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/5ab0e9b8a3b2ca7c5e000001': gemeente,
      'http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/5ab0e9b8a3b2ca7c5e000002': ocmw,
     'http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/36a82ba0-7ff1-4697-a9dd-2e94df73b721': agb,
     'http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/80310756-ce0a-4a1b-9b8e-7c01b6cc7a2d': apb,
     'http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/5ab0e9b8a3b2ca7c5e000004': intergemeentelijk_samenwerkingsverband,
     'http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/ea446861-2c51-45fa-afd3-4e4a37b71562': hulpverleningszone,
     'http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/a3922c6d-425b-474f-9a02-ffb71a436bfc': politiezone,
     'http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/cc4e2d67-603b-4784-9b61-e50bac1ec089': ocmw_vereniging
    }
    map[unit_klass.to_sym].map{ |k, v| [RDF::URI.new(k), v] }.to_h
  end

  def write_ttl_to_file(name)
    output = Tempfile.new(name)
    export_path = ENV["EXPORT_PATH"] ||= './'
    begin
      output.puts "# started #{name} at #{DateTime.now}"
      yield output
      output.puts "# finished #{name} at #{DateTime.now}"
      output.close
      path = File.join(export_path,"#{DateTime.now.strftime("%Y%m%d%H%M%S")}-#{name}.ttl")
      FileUtils.copy(output, path)
      puts "output written to #{path}"
      output.unlink
    rescue StandardError => e
      puts e
      puts "failed to successfully write #{name}"
      output.close
      output.unlink
    end
  end
end
