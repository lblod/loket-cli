require 'linkeddata'
require 'csv'
require 'securerandom'

class Personeelsdatabank
  MU = RDF::Vocabulary.new("http://mu.semte.ch/vocabularies/core/")
  RDFS = RDF::Vocab::RDFS
  EMPL = RDF::Vocabulary.new("http://lblod.data.gift/vocabularies/employee/")
  SDMXDIM = RDF::Vocabulary.new("http://purl.org/linked-data/sdmx/2009/dimension#")
  QB = RDF::Vocabulary.new("http://purl.org/linked-data/cube#")
  DCT = RDF::Vocabulary.new("http://purl.org/dc/terms/")

  TIME_PERIOD_LABEL = "2019"  # update if time_peridod changes
  TIME_PERIOD = RDF::URI.new("http://data.lblod.info/employee-time-periods/88260830-7a2f-45b4-a262-b1e46ed303d1")

  EDUCATIONAL_LEVELS = [
    RDF::URI.new("http://lblod.data.gift/concepts/53abea92-8a33-4d6c-8813-6e3a0d8c70e5"),
    RDF::URI.new("http://lblod.data.gift/concepts/fe0c5ed6-ee8e-466e-b4eb-4e1a580c2133"),
    RDF::URI.new("http://lblod.data.gift/concepts/ce9f9a39-ded6-4920-8c69-d2d3ea75b8f6"),
    RDF::URI.new("http://lblod.data.gift/concepts/78ae17dd-45f6-40d4-ab03-729231c1071e"),
    RDF::URI.new("http://lblod.data.gift/concepts/92bbd6c5-acee-43ac-9462-f5e260e2b900")
  ]

  EMPLOYEE_LEGAL_STATUSES = [
    RDF::URI.new("http://lblod.data.gift/concepts/5ac28613-801b-4b2e-ab79-68a6ad0a584d"),
    RDF::URI.new("http://lblod.data.gift/concepts/a29dd9d3-f0a2-4e40-b19a-dbc0ffd6f682")
  ]

  WORKING_TIME_CATEGORIES = [
    RDF::URI.new("http://lblod.data.gift/concepts/58c0fc8f-1ec9-469d-a13d-87a0e48fc0a3"),
    RDF::URI.new("http://lblod.data.gift/concepts/00b0467e-4dac-42ff-a5be-2892f0e6eca5")
  ]

  GENDERS = [
    RDF::URI.new("http://publications.europa.eu/resource/authority/human-sex/MALE"),
    RDF::URI.new("http://publications.europa.eu/resource/authority/human-sex/FEMALE")
  ]

  def create_personeelsaantallen_for_csv(csv_path)
    rows = CSV.read(csv_path, encoding: 'utf-8')
    puts "Retrieved #{rows.length} rows from CSV"
    rows.each do |row|
      bestuurseenheid = RDF::URI.new(row[0])
      uuid = row[3]
      name = row[2]
      classification = row[1]
      begin
        create_personeelsaantallen_for_bestuurseenheid(bestuurseenheid, uuid, name, classification)
      rescue StandardError => e
        puts e
        puts "Failed to create personeelsaantallen for #{classification} #{name}. Skipping this one."
      end
    end
  end

  def create_personeelsaantallen_for_bestuurseenheid(bestuurseenheid, uuid, name, classificationLabel)
    graph = "http://mu.semte.ch/graphs/organizations/#{uuid}/LoketLB-personeelsbeheer"
    dataset_label = "Personeelsaantallen #{classificationLabel} #{name}"
    slice_label = "#{dataset_label} #{TIME_PERIOD_LABEL}"

    triples = RDF::Repository.new

    dataset_uuid = SecureRandom.uuid
    dataset = RDF::URI.new("http://data.lblod.info/employee-datasets/#{dataset_uuid}")

    triples << [dataset, RDF.type, EMPL.EmployeeDataset]
    triples << [dataset, MU.uuid, dataset_uuid]
    triples << [dataset, RDFS.label, dataset_label]
    triples << [dataset, DCT.creator, bestuurseenheid]

    period_slice_uuid = SecureRandom.uuid
    period_slice = RDF::URI.new("http://data.lblod.info/employee-period-slices/#{period_slice_uuid}")

    triples << [dataset, QB.slice, period_slice]
    triples << [period_slice, RDF.type, EMPL.EmployeePeriodSlice]
    triples << [period_slice, MU.uuid, period_slice_uuid]
    triples << [period_slice, RDFS.label, slice_label]
    triples << [period_slice, SDMXDIM.timePeriod, TIME_PERIOD]

    EDUCATIONAL_LEVELS.each do |educational_level|
      EMPLOYEE_LEGAL_STATUSES.each do |legal_status|
        WORKING_TIME_CATEGORIES.each do |working_time_category|
          GENDERS.each do |gender|
            observation_uuid = SecureRandom.uuid
            observation = RDF::URI.new("http://data.lblod.info/employee-observations/#{observation_uuid}")

            triples << [observation, RDF.type, EMPL.EmployeeObservation]
            triples << [observation, MU.uuid, observation_uuid]
            triples << [observation, SDMXDIM.sex, gender]
            triples << [observation, EMPL.workingTimeCategory, working_time_category]
            triples << [observation, EMPL.legalStatus, legal_status]
            triples << [observation, SDMXDIM.educationLev, educational_level]
            triples << [period_slice, QB.observation, observation]
          end
        end
      end
    end

    write_to_files(slice_label, graph, triples)
  end

  def write_to_files(name, graph, triples)
    name = name.gsub(/[^a-zA-Z\d-]/,'-')
    timestamp = DateTime.now.strftime("%Y%m%d%H%M%S")
    export_path = ENV["EXPORT_PATH"] ||= './'
    begin
      output = Tempfile.new(name)
      output.puts "# started #{name} at #{DateTime.now}"
      output.write triples.dump(:ntriples)
      output.puts "# finished #{name} at #{DateTime.now}"
      output.close
      ttl_path = File.join(export_path,"#{timestamp}-#{name}.ttl")
      FileUtils.copy(output, ttl_path)
      puts "output written to #{ttl_path}"
      output.unlink

      output = Tempfile.new(name)
      output.puts "#{graph}"
      output.close
      graph_path = File.join(export_path,"#{timestamp}-#{name}.graph")
      FileUtils.copy(output, graph_path)
      puts "graph written to #{graph_path}"
      output.unlink

    rescue StandardError => e
      puts e
      puts "failed to successfully write #{name}"
      output.close
      output.unlink
      throw e
    end
  end
end
