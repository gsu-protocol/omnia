## Base image for omnia Docker images

Contains list of preinstalled tools required for building and running omnia Docker images.

List of preinstalled tools:
 - bash 
 - jq 
 - curl 
 - git 
 - nodejs 
 - python3 
 - make 
 - jshon
 - hevm v0.48.1
 - solc v0.5.12
 - ethsign v0.17.0
 - dapp v0.34.1
 - seth 

### Prebuilding image locally

```bash
$ docker build -t ghcr.io/chronicleprotocol/base -f ./docker/base/Dockerfile .
```