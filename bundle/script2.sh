#!/bin/bash

set -x
echo $1

source $1/venv/uwtools/bin/activate
cd $2/src
pip install .

