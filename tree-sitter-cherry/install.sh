#!/bin/bash
npx tree-sitter generate

gcc -shared -o cherry.so -fPIC src/parser.c -I src

mkdir -p ~/.config/nvim/parser
mv cherry.so ~/.config/nvim/parser/

mkdir -p ~/.config/nvim/queries/
mkdir -p ~/.config/nvim/queries/cherry/
cp highlights.scm ~/.config/nvim/queries/cherry/
