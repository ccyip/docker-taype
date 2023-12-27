#!/bin/bash

cd ~/taype-pldi
./bench.sh

cd ~/taype-sa
./bench.sh

cd ~/taypsi
./bench.sh
cd examples
cp -r ~/taype-pldi/examples/output-old .
cp -r ~/taype-sa/examples/output-old-sa .
python3 figs.py
