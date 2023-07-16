#!/bin/bash

if [ -f ./target/release/oledprint ]; then
    cp ./target/release/oledprint /usr/bin/oledprint
else
    echo 'build the project first!'
fi