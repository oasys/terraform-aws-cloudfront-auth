#!/bin/bash
#
# download source and dependencies for inclusion into the repository

set -euxo pipefail
DIR="cloudfront-auth"

rm -rf cloudfront-auth-master "$DIR"
curl -s -L https://github.com/Widen/cloudfront-auth/archive/master.zip -o master.zip
unzip -q master.zip
rm master.zip
mv cloudfront-auth-master "$DIR"
(cd "$DIR" && npm install --silent)
