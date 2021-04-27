# Loket-cli
Loket cli provides some basic tooling to generate data for the digitaal-loket application

## running loket-cli

There are two ways of running loket-cli. You can either generate an admin unit,
its bestuursorganen, bestuursfuncties, mock-user and personeelsaantallen all at
once or generate them separately.

Some tasks are interactive and others are constructing data from csv files.
In the `data` folder are two example csv files for the tasks
`create_full_units_from_csv` and `create_personeelsaantallen_for_csv`.

## Generating everything all at once

The following command will generate all the needed data from a csv input with name `bestuurseenheden.csv`

```
docker run -v $PWD/data:/data --rm -it lblod/loket-cli create_full_units_from_csv
```

The following columns are requested for the input csv (in the same order) :
- KBO number
- Name
- Afkortings
- Classification
- Provincie
- Werkingsgebied

#### Precisions

- KBO needs to be only numbers (no "." between numbers, be sure the 0 at the beggining is in the data)
- Afkortings need to be separated by ";" if there are several of them
- You should provide a URI as werkingsgebied

#### Possible values

Classification should be in the following list :
- Autonoom gemeentebedrijf
- Autonoom provinciebedrijf
- Hulpverleningszone
- Politiezone
- OCMW vereniging
- Dienstverlenende vereniging
- Opdrachthoudende vereniging
- Projectvereniging
- Provincie
- Gemeente
- OCMW
- District
- Vlaamse gemeenschapscommissie

Provincie should be in the following list :
- Antwerpen
- Limburg
- Oost-Vlaanderen
- Vlaams-Brabant
- West-Vlaanderen

### Generate data task by task

Three tasks:
- create_admin_unit creates the bestuurseenheid and related bestuursorganen / bestuursfuncties
- create_mock_user creates the mock user for a bestuurseenheid
- create_personeelsaantallen_for_csv creates the datasets for personeelsaantallen. The input is `personeelsaantallen.csv`
- create_bulk_message_from_abb creates a bulk message from abb. The input is `bestuurseenheden.csv` which needs a column `unit` (the uri of the bestuurseenheid) and a column `graph` (the graph to write messages to)

```
docker run -v $PWD/data:/data --rm -it lblod/loket-cli create_admin_unit
docker run -v $PWD/data:/data --rm -it lblod/loket-cli create_mock_user
docker run -v $PWD/data:/data --rm -it lblod/loket-cli create_personeelsaantallen_for_csv
docker run -v $PWD/data:/data --rm -it lblod/loket-cli create_bulk_message_from_abb
```

## development
```
git clone https://github.com/lblod/loket-cli
pushd loket-cli
docker run -v "$PWD":/app  -v $PWD/data:/data --rm -it lblod/loket-cli create_full_units_from_csv
docker run -v "$PWD":/app  -v $PWD/data:/data --rm -it lblod/loket-cli create_admin_unit
docker run -v "$PWD":/app  -v $PWD/data:/data --rm -it lblod/loket-cli create_mock_user
docker run -v "$PWD":/app  -v $PWD/data:/data --rm -it lblod/loket-cli create_personeelsaantallen_for_csv
```
