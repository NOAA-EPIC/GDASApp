#!/bin/bash

set -x
echo $1
unset PYTHONPATH
python -m venv $1/venv/uwtools
