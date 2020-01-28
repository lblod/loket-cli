# Loket-cli
Loket cli provides some basic tooling to generate data for the digitaal-loket application

## running loket-cli

Three tasks:
- create_admin_unit creates the bestuurseenheid and related bestuursorganen / bestuursfuncties

If we create a new bestuurseenheid we should also generate the two following:
- create_mock_user creates the mock user for a bestuurseenheid
- create_personeelsaantallen_for_csv creates  the datasets for personeelsaantallen.

```
docker run -v "$PWD":/app  -v $PWD/data:/data --rm -it lblod/loket-cli create_admin_unit
docker run -v "$PWD":/app  -v $PWD/data:/data --rm -it lblod/loket-cli create_mock_user
docker run -v "$PWD":/app  -v $PWD/data:/data --rm -it lblod/loket-cli create_personeelsaantallen_for_csv
```

## development
```
git clone https://github.com/lblod/loket-cli
pushd loket-cli
docker run -v "$PWD":/app  -v $PWD/data:/data --rm -it lblod/loket-cli create_admin_unit
docker run -v "$PWD":/app  -v $PWD/data:/data --rm -it lblod/loket-cli create_mock_user
docker run -v "$PWD":/app  -v $PWD/data:/data --rm -it lblod/loket-cli create_personeelsaantallen_for_csv
```

## Everything from csv :

The following columns are requested for the input csv :
- Classification
- Provincie
- KBO number
- Name
- Afkortings
- Werkingsgebied

### Precisions

- KBO needs to be only numbers (no "." between numbers)
- Afkortings need to be separated by ";" if there are several of them
- You should provide a URI as werkingsgebied

### Possible values

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

Provincie should be in the following list :
- Antwerpen
- Limburg
- Oost-Vlaanderen
- Vlaams-Brabant
- West-Vlaanderen
