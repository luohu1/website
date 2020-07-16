#!/usr/bin/env sh

# abort on errors
set -e

# build
rm -rf public
hugo --gc  # -b https://www.ipyth.com/website/


cd public

git init
git add -A
git commit -m "@website"

git push -f https://github.com/luohu1/luohu1.github.io.git master

cd -
