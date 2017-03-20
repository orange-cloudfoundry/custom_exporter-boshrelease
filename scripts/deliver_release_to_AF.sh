#/bin/bash

CUR_DIR=$(pwd)
CUR_TS=$(date +%s)
RELEASE_NAME=custom_exporter-${CUR_TS}+alpha.tgz
AF_URL=""
##release generator for custom_exporter
rm -Rf tmp_custom_exporter
git clone https://github.com/orange-cloudfoundry/custom_exporter-boshrelease.git tmp_custom_exporter

cd tmp_custom_exporter

git pull --force --all --verbose --prune && git submodule init && git submodule sync && git submodule foreach git submodule sync && git submodule update --recursive

##add blob
wget https://storage.googleapis.com/golang/go1.7.linux-amd64.tar.gz
bosh add-blob go1.7.linux-amd64.tar.gz go1.7.linux-amd64.tar.gz

##creating release
bosh create-release --tarball=${CUR_DIR}/${RELEASE_NAME} --version ${CUR_TS}+alpha --force

##uploading release
curl -u ${USER} -T ${CUR_DIR}/${RELEASE_NAME} "${AF_URL}/${RELEASE_NAME}"

