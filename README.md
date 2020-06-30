# rdf-pubmed

## Installation 

```bash
$ docker build --tag rdf-pubmed .
```

## Run

```bash
$ docker run --rm -v [WORK]:/work -v [DATA]:/data rdf-pubmed [OPTION]
```
[WORK]: Download file location

[DATA]: Converted file location

[OPTION]:  
-f Convert local files when no new remote files are available.  
-i Run first and at the beginning of the year.
