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
    fi
  done

  echo $listAllpkg | tr " " "\n" | sort -u | grep -v '^$'
}

filterAll() {
  local listPackage=$(echo $@ | tr "\n" " " | sort -u | grep -v '^$')
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

  echo $listAllpkg | tr " " "\n" | sort -u | grep -v '^$'
}

printAllPkg () {
  echo -e "\n\n\n\n"
  echo $@ | tr " " "\n" | sort -u | grep -v '^$'
  echo -e "\n\n\n\n"
}

listAll=$(getAllImports github.com/orange-cloudfoundry/custom_exporter github.com/orange-cloudfoundry/custom_exporter/config github.com/orange-cloudfoundry/custom_exporter/collector) #&& printAllPkg $listAll
listAll=$(getAllImports $listAll) #&& printAllPkg $listAll
listAll=$(getAllImports $listAll) #&& printAllPkg $listAll
listAll=$(getAllImports $listAll) 

#listAll=$(filterAll $listAll)

filterAll $listAll

