#!/usr/bin/env bash

CURR_COLOR=`curl \
    http://localhost:8500/v1/kv/books-ms/color?raw`

if [ "$CURR_COLOR" == "blue" ]; then
    echo "green"
else
    echo "blue"
fi
