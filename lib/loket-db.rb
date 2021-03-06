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
  LBLODLG = RDF::Vocabulary.new('http://data.lblod.info/vocabularies/leidinggevenden/')
  SCHEMA = RDF::Vocab::SCHEMA
  NIE = RDF::Vocabulary.new("http://www.semanticdesktop.org/ontologies/2007/01/19/nie#")
  NFO = RDF::Vocabulary.new("http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#")
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

  def create_administrative_unit(name, code, area, classification, provincie, afkortings)
    triples = RDF::Repository.new
    uuid = SecureRandom.uuid
    iri = RDF::URI.new("http://data.lblod.info/id/bestuurseenheden/#{uuid}")
    triples << [iri, RDF.type, RDF::URI.new('http://data.vlaanderen.be/ns/besluit#Bestuurseenheid') ]
    triples << [iri, MU.uuid, uuid]
    triples << [iri, SKOS.prefLabel, name ]
    triples << [iri, BESLUIT.classificatie, classification]
    triples << [iri, EXT.inProvincie, provincie]
    triples << [iri, BESLUIT.werkingsgebied, area]
    triples << [iri, EXT.kbonummer, code]
    triples << [iri, DC.identifier, code]
    afkortings.each { |afkorting| triples << [iri, SKOS.altLabel, afkorting] }
    return [uuid, iri, triples]
  end

  def create_administrative_body(unit, name, classification, start_date = Date.parse("2019-01-01"), bestuursfunctierol = nil)
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

    if bestuursfunctierol
      bestuursfunctie_uuid = SecureRandom.uuid
      bestuursfunctie = RDF::URI.new("http://data.lblod.info/id/bestuursfuncties/#{bestuursfunctie_uuid}")
      triples << [tijdsorgaan, LBLODLG.heeftBestuursfunctie, bestuursfunctie]
      triples << [bestuursfunctie, RDF.type, LBLODLG.Bestuursfunctie]
      triples << [bestuursfunctie, MU.uuid, bestuursfunctie_uuid]
      triples << [bestuursfunctie, SKOS.prefLabel, bestuursfunctierol[1]]
      triples << [bestuursfunctie, ORG.role, bestuursfunctierol[0]]
    end

    triples
  end

  def unit_classifications
    [
      { id: 1, name: "Autonoom gemeentebedrijf", uri: RDF::URI.new('http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/36a82ba0-7ff1-4697-a9dd-2e94df73b721')},
      { id: 2, name: "Autonoom provinciebedrijf", uri: RDF::URI.new('http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/80310756-ce0a-4a1b-9b8e-7c01b6cc7a2d')},
      { id: 3, name: "Hulpverleningszone", uri: RDF::URI.new('http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/ea446861-2c51-45fa-afd3-4e4a37b71562')},
      { id: 4, name: "Politiezone", uri: RDF::URI.new('http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/a3922c6d-425b-474f-9a02-ffb71a436bfc') },
      { id: 5, name: "OCMW vereniging", uri: RDF::URI.new('http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/cc4e2d67-603b-4784-9b61-e50bac1ec089')},
      { id: 6, name: "Dienstverlenende vereniging", uri: RDF::URI.new('http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/d01bb1f6-2439-4e33-9c25-1fc295de2e71')},
      { id: 7, name: "Opdrachthoudende vereniging", uri: RDF::URI.new('http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/cd93f147-3ece-4308-acab-5c5ada3ec63d')},
      { id: 8, name: "Projectvereniging", uri: RDF::URI.new('http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/b156b67f-c5f4-4584-9b30-4c090be02fdc')},
      { id: 9, name: "Provincie", uri: RDF::URI.new('http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/5ab0e9b8a3b2ca7c5e000000')},
      { id: 10, name: "Gemeente", uri: RDF::URI.new('http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/5ab0e9b8a3b2ca7c5e000001')},
      { id: 11, name: "OCMW", uri: RDF::URI.new('http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/5ab0e9b8a3b2ca7c5e000002')},
      { id: 12, name: "District", uri: RDF::URI.new('http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/5ab0e9b8a3b2ca7c5e000003')},
      { id: 13, name: "Vlaamse gemeenschapscommissie", uri: RDF::URI.new('http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/d90c511e-f827-488c-84ba-432c8f69561c')}

    ]
  end

  def unit_provincies
    [
      { id: 1, name: "Antwerpen", uri: RDF::URI.new('http://data.lblod.info/id/werkingsgebieden/f2bda6eb42c1ab85c4ef36588a043ac2bfeffa31bfb88bb7abc597f01efe270b')},
      { id: 2, name: "Limburg", uri: RDF::URI.new('http://data.lblod.info/id/werkingsgebieden/b6868be9ca6881b1020e6cff8d431531a1cff64b39dc92646a5173b3ee144516')},
      { id: 3, name: "Oost-Vlaanderen", uri: RDF::URI.new('http://data.lblod.info/id/werkingsgebieden/a9a0cabd376a2b3a8eb838f15f6aeb1b63ffe49d527598994962e0d15ad2081c')},
      { id: 4, name: "Vlaams-Brabant", uri: RDF::URI.new('http://data.lblod.info/id/werkingsgebieden/60a52229c92c1407e0549a573f820fb8a1f9fab5c82654b4b3493bc81be365de')},
      { id: 5, name: "West-Vlaanderen", uri: RDF::URI.new('http://data.lblod.info/id/werkingsgebieden/9c503a712d448bc8b89c1f8802c207e30bd192bc8da3bf22509a547949a45301') }
    ]
  end


  def body_classifications_for_unit(unit_klass)
    gemeente = {
     'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/4955bd72cd0e4eb895fdbfab08da0284': 'Burgemeester',
     'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/5ab0e9b8a3b2ca7c5e000005': 'Gemeenteraad',
     'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/5ab0e9b8a3b2ca7c5e000006': "College van Burgemeester en Schepenen",
     'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/39854196-f214-4688-87a1-d6ad12baa2fa': "Algemeen directeur",
     'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/11f0af9e-016c-4e0b-983a-d8bc73804abc': "Adjunct-algemeen directeur",
     'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/62644b9c-4514-41dd-a660-4c35257f2b35': "Financieel directeur",
     'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/ed40469e-3b6f-4f38-99ba-18912ee352b0': "Adjunct-financieel directeur",
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
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/5ab0e9b8a3b2ca7c5e00000d':  "Deputatie",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/5ab19107-82d2-4273-a986-3da86fda050d': "Griffier",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/3e9f22c1-0d35-445b-8a37-494addedf2d8': "Financieel beheerder"
    }
    district = {
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/5ab0e9b8a3b2ca7c5e00000a':    "Districtsraad",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/9314533e-891f-4d84-a492-0338af104065':    "Districtsburgemeester",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/5ab0e9b8a3b2ca7c5e00000b':    "Districtscollege"
    }
    agb = {
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/013cc838-173a-4657-b1ae-b00c048df943':    "Raad van bestuur",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/0dbc70ec-6be9-4997-b8e1-11b6c0542382':    "Bevoegd beslissingsorgaan",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/b52094ff-21a2-4da8-8dbe-f513365d1528':    "Algemene vergadering",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/41caf7e6-b040-4720-9cc2-a96cfffed5b4':  "Leidend Ambtenaar"
    }
    apb = {
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/013cc838-173a-4657-b1ae-b00c048df943':    "Raad van bestuur",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/0dbc70ec-6be9-4997-b8e1-11b6c0542382':    "Bevoegd beslissingsorgaan",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/b52094ff-21a2-4da8-8dbe-f513365d1528':    "Algemene vergadering",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/41caf7e6-b040-4720-9cc2-a96cfffed5b4':  "Leidend Ambtenaar"
    }
    dienstverlenende_vereniging = {
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/5733254e-73ff-4844-8d43-7afb7ec726e8':    "Directiecomité",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/013cc838-173a-4657-b1ae-b00c048df943':    "Raad van bestuur",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/17e76b36-64a1-4db1-8927-def3064b4bf1':    "Regionaal bestuurscomité",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/b52094ff-21a2-4da8-8dbe-f513365d1528':    "Algemene vergadering",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/41caf7e6-b040-4720-9cc2-a96cfffed5b4':  "Leidend Ambtenaar"
    }
    opdrachthoudende_vereniging = {
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/5733254e-73ff-4844-8d43-7afb7ec726e8':    "Directiecomité",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/013cc838-173a-4657-b1ae-b00c048df943':    "Raad van bestuur",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/17e76b36-64a1-4db1-8927-def3064b4bf1':    "Regionaal bestuurscomité",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/b52094ff-21a2-4da8-8dbe-f513365d1528':    "Algemene vergadering",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/41caf7e6-b040-4720-9cc2-a96cfffed5b4':  "Leidend Ambtenaar"
    }
    projectvereniging = {
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/5733254e-73ff-4844-8d43-7afb7ec726e8':    "Directiecomité",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/013cc838-173a-4657-b1ae-b00c048df943':    "Raad van bestuur",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/17e76b36-64a1-4db1-8927-def3064b4bf1':    "Regionaal bestuurscomité",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/b52094ff-21a2-4da8-8dbe-f513365d1528':    "Algemene vergadering",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/41caf7e6-b040-4720-9cc2-a96cfffed5b4':  "Leidend Ambtenaar"
    }
    hulpverleningszone = {
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/a9e30e31-0cd2-4f4a-9352-545c5d43be83': "Zoneraad"
    }
    politiezone = {
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/a9e30e31-0cd2-4f4a-9352-545c5d43be83': "Politieraad"
    }
    ocmw_vereniging = {
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/013cc838-173a-4657-b1ae-b00c048df943':  "Raad van bestuur",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/b52094ff-21a2-4da8-8dbe-f513365d1528':  "Algemene vergadering",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/41caf7e6-b040-4720-9cc2-a96cfffed5b4': "Leidend Ambtenaar"
    }
    vgc = {
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/7148e12a-ae03-4a7b-bb16-7b6269b84175': "College",
      'http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/ff20fa3e-806b-4160-b74b-7483fe3a6ecd': "Collegelid"
    }
    map = {
      'http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/5ab0e9b8a3b2ca7c5e000000': provincie,
      'http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/5ab0e9b8a3b2ca7c5e000003': district,
      'http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/5ab0e9b8a3b2ca7c5e000001': gemeente,
      'http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/5ab0e9b8a3b2ca7c5e000002': ocmw,
      'http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/36a82ba0-7ff1-4697-a9dd-2e94df73b721': agb,
      'http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/80310756-ce0a-4a1b-9b8e-7c01b6cc7a2d': apb,
      'http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/d01bb1f6-2439-4e33-9c25-1fc295de2e71': dienstverlenende_vereniging,
      'http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/cd93f147-3ece-4308-acab-5c5ada3ec63d': opdrachthoudende_vereniging,
      'http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/b156b67f-c5f4-4584-9b30-4c090be02fdc': projectvereniging,
      'http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/ea446861-2c51-45fa-afd3-4e4a37b71562': hulpverleningszone,
      'http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/a3922c6d-425b-474f-9a02-ffb71a436bfc': politiezone,
      'http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/cc4e2d67-603b-4784-9b61-e50bac1ec089': ocmw_vereniging,
      'http://data.vlaanderen.be/id/concept/BestuurseenheidClassificatieCode/d90c511e-f827-488c-84ba-432c8f69561c': vgc
    }
    map[unit_klass.to_sym].map{ |k, v| [RDF::URI.new(k), v] }.to_h
  end

  def get_bestuursfunctie_for_classification(classificatie_uri)
    case classificatie_uri
    when "http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/39854196-f214-4688-87a1-d6ad12baa2fa" # algemeen directeur
      ["http://data.vlaanderen.be/id/concept/BestuursfunctieCode/39e08271-68db-4282-897f-5cba88c71862", "Algemeen directeur"]
    when "http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/11f0af9e-016c-4e0b-983a-d8bc73804abc" # adjunct algemeen directeur
      ["http://data.vlaanderen.be/id/concept/BestuursfunctieCode/f7b4e17b-6f4e-48e7-a558-bce61669f59a", "Adjunct algemeen directeur"]
    when "http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/62644b9c-4514-41dd-a660-4c35257f2b35" # financieel directeur
      ["http://data.vlaanderen.be/id/concept/BestuursfunctieCode/6d4cf4dd-2080-4752-8733-d02a036b2df0", "Financieel directeur"]
    when "http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/ed40469e-3b6f-4f38-99ba-18912ee352b0" # adjunct financieel directeur
      ["http://data.vlaanderen.be/id/concept/BestuursfunctieCode/3200ffc1-bb72-4235-a81c-64aa578b0789", "Adjunct financieel directeur"]
    when "http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/5ab19107-82d2-4273-a986-3da86fda050d" # griffier
      ["http://data.vlaanderen.be/id/concept/BestuursfunctieCode/63195ec6-02cb-4f86-ac8e-29c5183a11dc", "Griffier"]
    when "http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/3e9f22c1-0d35-445b-8a37-494addedf2d8" # financieel beheerder
      ["http://data.vlaanderen.be/id/concept/BestuursfunctieCode/b213c870-c762-4e39-9f78-3abdeda4b64a", "Financieel beheerder"]
    when "http://data.vlaanderen.be/id/concept/BestuursorgaanClassificatieCode/41caf7e6-b040-4720-9cc2-a96cfffed5b4" # leidend ambtenaar
      ["http://data.vlaanderen.be/id/concept/BestuursfunctieCode/855489b9-b584-4f34-90b2-39aea808cd9f", "Leidend ambtenaar"]
    else
      nil
    end
  end


  def write_units_to_file(bestuurseenheid)
    begin
      # Create units and functies
      (unit_uuid, unit_uri, triples) = create_administrative_unit(bestuurseenheid[:name], bestuurseenheid[:kbo], bestuurseenheid[:werkingsgebied_uri], bestuurseenheid[:classification][:uri], bestuurseenheid[:provincie][:uri], bestuurseenheid[:afkortings])
      unit_classifications = body_classifications_for_unit(bestuurseenheid[:classification][:uri].value.to_s)
      unit_classifications.each do |unit_classification_uri, unit_classification_name|
        bestuursfunctierol = get_bestuursfunctie_for_classification(unit_classification_uri)
        triples << create_administrative_body(unit_uri, "#{unit_classification_name} #{bestuurseenheid[:name]}", unit_classification_uri, Date.parse("2019-01-01"), bestuursfunctierol)
      end

      # Prepare paths to write files
      export_path = ENV["EXPORT_PATH"] ||= './'
      now = DateTime.now
      now_plus_one_second = now + Rational(1, 86400) #  Will add 1 second to now (since there are 86400 seconds in a day).
      core_path = "#{now.strftime("%Y%m%d%H%M%S")}-#{bestuurseenheid[:classification][:name]}-#{bestuurseenheid[:name]}"
      core_path_plus_one_second = "#{now_plus_one_second.strftime("%Y%m%d%H%M%S")}-#{bestuurseenheid[:classification][:name]}-#{bestuurseenheid[:name]}"
      ttl_path = File.join(export_path, "#{core_path.gsub(/[^a-zA-Z\d-]/,'-')}.ttl")
      graph_path = File.join(export_path, "#{core_path.gsub(/[^a-zA-Z\d-]/,'-')}.graph")
      sparql_path = File.join(export_path, "#{core_path_plus_one_second.gsub(/[^a-zA-Z\d-]/,'-')}-mock-user.sparql")

      # Write units and functies to file
      write_ttl_to_file(ttl_path, graph_path) do |file|
        file.write triples.dump(:ntriples)
      end

      # Write mock users to files
      write_mock_user_to_file(unit_uuid, sparql_path)
      [unit_uri, unit_uuid]
    end
  end

  def create_conversation(number: , about:, time:, type:)
    uuid = SecureRandom.uuid
    conversatie = RDF::URI.new("http://data.lblod.info/id/conversaties/#{uuid}")
    graph = RDF::Repository.new
    graph << [ conversatie, RDF.type, SCHEMA.Conversation]
    graph << [ conversatie, MU.uuid, uuid]
    graph << [ conversatie, SCHEMA.identifier, number]
    graph << [ conversatie, SCHEMA.about, about]
    graph << [ conversatie, EXT.currentType, type]
    graph << [ conversatie, SCHEMA.processingTime, time]
    [conversatie, graph]
  end

  def create_message(conversatie: nil , type: nil, recipient: nil, dateReceived: nil, dateSent: nil, author: nil, sender: nil, isLastMessage: nil)
    uuid = SecureRandom.uuid
    message = RDF::URI.new("http://data.lblod.info/id/berichten/#{uuid}")
    graph = RDF::Repository.new
    graph << [ message, RDF.type, SCHEMA.Message]
    graph << [ message, MU.uuid, uuid]
    graph << [ message, DC.type, type]
    graph << [ message, SCHEMA.dateSent, RDF::Literal::DateTime.new(dateSent)] if dateSent
    graph << [ message, SCHEMA.dateReceived, RDF::Literal::DateTime.new(dateReceived)] if dateReceived
    graph << [ message, SCHEMA.recipient, recipient] if recipient
    graph << [ message, SCHEMA.sender, sender] if sender
    graph << [ conversatie, SCHEMA.author, author ] if author
    graph << [ conversatie, SCHEMA.hasPart, message] if conversatie
    graph << [ conversatie, EXT.lastMessage, message] if isLastMessage and conversatie
    [message, graph]
  end

  def create_message_attachment(message, file_path, date, format)
    uuid = SecureRandom.uuid
    logical_file_uri = RDF::URI.new("http://mu.semte.ch/services/file-service/files/#{uuid}")
    filename = File.basename(file_path)
    file_extension = filename.split('.').last
    file_size = File.size(file_path)
    physical_uuid = SecureRandom.uuid
    physical_file_name = "#{physical_uuid}.#{file_extension}"
    physical_file_uri = RDF::URI.new("share://#{physical_file_name}")
    graph = RDF::Repository.new
    graph << [message, NIE.hasPart, logical_file_uri]
    graph << [logical_file_uri, RDF.type, NFO.FileDataObject]
    graph << [logical_file_uri, MU.uuid, uuid]
    graph << [logical_file_uri, DC.created, RDF::Literal::DateTime.new(date)]
    graph << [logical_file_uri, DC.modified, RDF::Literal::DateTime.new(date)]
    graph << [logical_file_uri, DC.format, format]
    graph << [logical_file_uri, NFO.fileSize, file_size]
    graph << [logical_file_uri, NFO.fileName, filename]
    graph << [logical_file_uri, RDF::URI.new("http://dbpedia.org/ontology/fileExtension"), file_extension]
    graph << [physical_file_uri, NIE.dataSource, logical_file_uri]
    graph << [physical_file_uri, RDF.type, NFO.FileDataObject]
    graph << [physical_file_uri, MU.uuid, physical_uuid]
    graph << [physical_file_uri, NFO.fileName, physical_file_name]
    graph << [physical_file_uri, DC.created, RDF::Literal::DateTime.new(DateTime.now)]
    graph << [physical_file_uri, DC.modified, RDF::Literal::DateTime.new(DateTime.now)]
    graph << [physical_file_uri, DC.format, format]
    graph << [physical_file_uri, NFO.fileSize, file_size]
    graph << [physical_file_uri, RDF::URI.new("http://dbpedia.org/ontology/fileExtension"), file_extension]
    return [physical_file_name, graph]
  end

  def write_ttl_to_file(ttl_path, graph_path = nil)
    begin
      output = Tempfile.new(ttl_path)
      output.puts "# started #{ttl_path} at #{DateTime.now}"
      yield output
      output.puts "# finished #{ttl_path} at #{DateTime.now}"
      output.close
      FileUtils.copy(output, ttl_path)
      puts "output written to #{ttl_path}"
      output.unlink

      if graph_path
        output = Tempfile.new(graph_path)
        output.puts "http://mu.semte.ch/graphs/public"
        output.close
        FileUtils.copy(output, graph_path)
        puts "graph written to #{graph_path}"
        output.unlink
      end
    rescue StandardError => e
      puts e
      puts "failed to successfully write #{ttl_path} or #{graph_path}"
      output.close
      output.unlink
    end
  end

  def write_mock_user_to_file(bestuurseenheid_uuid, path)
    begin
      content = "PREFIX mu: <http://mu.semte.ch/vocabularies/core/>
      PREFIX ext: <http://mu.semte.ch/vocabularies/ext/>
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
      PREFIX dcterms: <http://purl.org/dc/terms/>
      PREFIX besluit: <http://data.vlaanderen.be/ns/besluit#>
      PREFIX mandaat: <http://data.vlaanderen.be/ns/mandaat#>
      PREFIX foaf: <http://xmlns.com/foaf/0.1/>

      INSERT {
        GRAPH ?g {
           ?persoon a foaf:Person;
                 mu:uuid ?uuidPersoon;
                 foaf:firstName ?classificatie;
                 foaf:familyName ?naam;
                 foaf:member <http://data.lblod.info/id/bestuurseenheden/#{bestuurseenheid_uuid}> ;
                 foaf:account ?account.
           ?account a foaf:OnlineAccount;
                 mu:uuid ?uuidAccount;
                 foaf:accountServiceHomepage <https://github.com/lblod/mock-login-service>;
                 ext:sessionRole \"LoketLB-toezichtGebruiker\", \"LoketLB-bbcdrGebruiker\", \"LoketLB-mandaatGebruiker\", \"LoketLB-berichtenGebruiker\", \"LoketLB-leidinggevendenGebruiker\", \"LoketLB-personeelsbeheer\", \"LoketLB-subsidies\".
        }
      } WHERE {
           <http://data.lblod.info/id/bestuurseenheden/#{bestuurseenheid_uuid}> a besluit:Bestuurseenheid;
           skos:prefLabel ?naam;
           besluit:classificatie/skos:prefLabel ?classificatie.
           BIND(CONCAT(?classificatie, \" \", ?naam) as ?volledigeNaam)
           BIND(MD5(?volledigeNaam) as ?uuidPersoon)
           BIND(MD5(CONCAT(?volledigeNaam,\"ACCOUNT\")) as ?uuidAccount)
           BIND(IRI(CONCAT(\"http://data.lblod.info/id/persoon/\", ?uuidPersoon)) AS ?persoon)
           BIND(IRI(CONCAT(\"http://data.lblod.info/id/account/\", ?uuidAccount)) AS ?account)

           VALUES ?g {
              <http://mu.semte.ch/graphs/organizations/#{bestuurseenheid_uuid}>
              <http://mu.semte.ch/graphs/public>
           }
      }"
      File.write(path, content)
      puts "mock user written to #{path}"
    rescue StandardError => e
      puts e
      puts "failed to successfully write #{name}"
    end
  end
end
