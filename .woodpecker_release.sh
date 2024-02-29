#!/usr/bin/env sh

set -euxo pipefail

# build a release
mkdir schmu-latest
opam exec -- dune install --relocatable --prefix schmu-latest
tar cavf schmu-latest.tbz schmu-latest

# delete old release file
dd of=auth <<< "Authorization: Bearer $RELEASE"
curl -sS -X 'GET' 'https://codeberg.org/api/v1/repos/tjammer/schmu/releases/1933295/assets' -H 'accept: application/json' | jq '.[] | .id' | xargs -I{} curl -X 'DELETE' 'https://codeberg.org/api/v1/repos/tjammer/schmu/releases/1933295/assets/{}'  -H 'accept: application/json' -H @auth

# add new one
curl -sS -X 'POST' 'https://codeberg.org/api/v1/repos/tjammer/schmu/releases/1933295/assets?name=schmu-latest.tbz' -H 'accept: application/json' -H 'Content-Type: multipart/form-data' -F 'attachment=@schmu-latest.tbz;type=application/x-bzip-compressed-tar' -H @auth

# update release commit
curl -sS -X 'PATCH' \
  'https://codeberg.org/api/v1/repos/tjammer/schmu/releases/1933295' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -H @auth \
  -d "{ \"target_commitish\": \"$(git rev-parse HEAD)\"}"
