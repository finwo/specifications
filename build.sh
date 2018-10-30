#!/usr/bin/env bash

#echo "Updating gitignore"
#curl -s https://www.gitignore.io/api/osx,linux,windows,intellij,composer > .gitignore
#echo /.gtm/ >> .gitignore
#echo /.idea/ >> .gitignore
#echo composer.lock >> .gitignore
#echo 'src/*/*.pdf' >> .gitignore
#echo '*.aux' >> .gitignore
#echo '*.log' >> .gitignore
#echo '*.toc' >> .gitignore
#
#echo "Updating PHP dependencies"
#composer install &>/dev/null

echo "(Re)building generated specs"
ORGDIR=$(pwd)
SPECDIR=$(pwd)/spec
cd src
for f in $(find . -type f -regextype posix-egrep -regex '\./[0-9]{4}.*\.tex'); do
  pdflatex ${f}
  pdflatex ${f}
  cp ${f%.*}.pdf ${SPECDIR}
  rm -f *.pdf
  rm -f *.aux
  rm -f *.log
  rm -f *.toc
done
