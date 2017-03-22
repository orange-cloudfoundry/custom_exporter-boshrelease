#!/bin/bash

git pull --all --prune --verbose --force
git submodule init
git submodule sync --recursive
git submodule foreach sync
git submodule update --recursive
git status

