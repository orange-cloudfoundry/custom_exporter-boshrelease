#!/bin/bash

if [ -e src/ ];
then
  GOPATH=$(pwd -P)
else
  echo "Error : run this script from bosh release root folder"
  exit 1
fi

getAllImports () {
  local listPackage=$(echo $@)
  local listAllpkg=""

  for file in $listPackage;
  do
    if [ -e $GOROOT/src/$file ];
    then
      continue
    fi

    if [[ $file == *"/"* ]];
    then
      listAllpkg+=$(echo "$file ")
      listAllpkg+=$(echo "$(go list -f '{{ join .Imports "\n" }}' $file | tr "\n" " ") ")
      listAllpkg+=$(echo "$(go list $file/... | tr "\n" " ") ")
    fi
  done

  echo $listAllpkg | tr " " "\n" | sort -u | grep -v '^$' | grep -v 'golang\.org/x'
}

filterAll() {
  local listPackage=$(echo $@ | tr "\n" " " | sort -u | grep -v '^$' | grep -v 'golang\.org/x')
  local listAllpkg=""

  for file in $listPackage;
  do
    local basepath=$(echo $file | grep -oP '^([\w/]*)/')

    if [ -e $(dirname $GOROOT/src/$file) ];
    then
      find=$(grep -r "package $(basename $file)" $(dirname $GOROOT/src/$file) | grep -c $(dirname $file))
      if [ "$find" != "0" ];
      then 
        continue
      fi
    fi

    if [[ $file == *"/"* ]];
    then
      listAllpkg+=$(echo "$file ")
    fi
  done

  echo $listAllpkg | tr " " "\n" | sort -u | grep -v '^$' | grep -v 'golang\.org/x'
}

printAllPkg () {
  echo -e "\n\n\n\n"
  echo $@ | tr " " "\n" | sort -u | grep -v '^$' | grep -v 'golang\.org/x'
  echo -e "\n\n\n\n"
}

listAll=$(getAllImports github.com/orange-cloudfoundry/custom_exporter github.com/orange-cloudfoundry/custom_exporter/config github.com/orange-cloudfoundry/custom_exporter/collector) 
listAll=$(getAllImports $listAll) #&& printAllPkg $listAll
listAll=$(getAllImports $listAll) #&& printAllPkg $listAll
listAll=$(getAllImports $listAll) 

echo "---" > packages/custom_exporter/spec
echo "name: custom_exporter" >> packages/custom_exporter/spec
echo "dependencies:" >> packages/custom_exporter/spec
echo "- golang" >> packages/custom_exporter/spec
echo "- promu" >> packages/custom_exporter/spec
echo "files:" >> packages/custom_exporter/spec
echo "- custom_monitoring_scripts/*.sh" >> packages/custom_exporter/spec
echo "- github.com/orange-cloudfoundry/custom_exporter/Makefile" >> packages/custom_exporter/spec
echo "- github.com/orange-cloudfoundry/custom_exporter/.promu.yml" >> packages/custom_exporter/spec
echo "- github.com/orange-cloudfoundry/custom_exporter/VERSION" >> packages/custom_exporter/spec

for file in $(filterAll $listAll);
do 
  echo "Add into packages/custom_exporter/spec : $file"
  echo "- $file/*.go" >> packages/custom_exporter/spec
done

listAll=$(getAllImports github.com/prometheus/promu)
listAll=$(getAllImports $listAll) #&& printAllPkg $listAll
listAll=$(getAllImports $listAll) #&& printAllPkg $listAll
listAll=$(getAllImports $listAll)

echo "---" > packages/promu/spec
echo "name: promu" >> packages/promu/spec
echo "dependencies:" >> packages/promu/spec
echo "- golang" >> packages/promu/spec
echo "files:" >> packages/promu/spec
echo "- github.com/prometheus/promu/Makefile" >> packages/promu/spec
echo "- github.com/prometheus/promu/.promu.yml" >> packages/promu/spec
echo "- github.com/prometheus/promu/VERSION" >> packages/promu/spec

for file in $(filterAll $listAll);
do
  echo "Add into packages/promu/spec : $file"
  echo "- $file/*.go" >> packages/promu/spec
done

