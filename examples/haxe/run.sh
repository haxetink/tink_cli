#!/bin/bash

set -x

echo "### Basic"
./haxe.sh -js bin/run.js -main Main

echo "### Without main"
./haxe.sh -js bin/run.js Api

echo "### With libaries and defines"
./haxe.sh -js bin/run.js -D release -D mobile -lib tink_core -lib tink_json -main Main

echo "### Flags"
./haxe.sh --help
./haxe.sh --help-defines