# Loket-cli
Loket cli provides some basic tooling to generate data for the digitaal-loket application

## running loket-cli

```
docker run -v $PWD/data:/data --rm -it lblod/loket-cli create_admin_unit
```

## development
```
git clone https://github.com/lblod/loket-cli
pushd loket-cli
docker run -v "$PWD":/app  -v $PWD/data:/data --rm -it lblod/loket-cli create_admin_unit 
```
