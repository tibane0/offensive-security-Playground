#!/bin/bash

REPO=https://github.com/sajjadium/ctf-archives.git
DIR=ctf-partial

git clone --depth 1 --filter=blob:none --no-checkout "$REPO" "$DIR"
cd "$DIR" || exit

# Find all directories named 'pwn' under 'ctfs' at any depth
folders=$(git ls-tree -d -r --name-only origin/main | grep '/pwn$')

# Checkout each 'pwn' directory individually
for folder in $folders; do
    echo "Checking out $folder"
    git checkout origin/main -- "$folder"
done

