#!/usr/bin/env bash

echo "Updating gitignore"
curl -s https://www.gitignore.io/api/osx,linux,windows,intellij,composer > .gitignore
echo /.gtm/ >> .gitignore
echo /.idea/ >> .gitignore
echo composer.lock >> .gitignore
echo 'src/*/*.pdf' >> .gitignore
echo '*.aux' >> .gitignore
echo '*.log' >> .gitignore
echo '*.toc' >> .gitignore

echo "Updating PHP dependencies"
composer install &>/dev/null

echo "(Re)building generated specs"
SPECDIR=$(pwd)/spec
for d in $(find $(pwd)/src -mindepth 1 -maxdepth 1 -type d); do
  cd $d
  pdflatex content.tex && cp content.pdf ${SPECDIR}/$(basename $d).pdf
done
#pdflatex -output-directory=src/0002 -aux-directory=aux src/0002/content.tex && cp src/0002/content.pdf spec/0002.pdf
#pandoc -f latex -o spec/spec0002.pdf src/0002.tex
