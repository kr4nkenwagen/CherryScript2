#!/bin/bash
# 1. Ensure the C code is generated
npx tree-sitter generate

# 2. Compile it using gcc (or clang on macOS)
gcc -shared -o cherry.so -fPIC src/parser.c -I src

# 3. Create the native Neovim parser directory if it doesn't exist
mkdir -p ~/.config/nvim/parser

# 4. Move the compiled parser into Neovim's path
mv cherry.so ~/.config/nvim/parser/
