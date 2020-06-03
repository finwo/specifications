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

echo "Building..."
ORGDIR=$(pwd)
SPECDIR=$(pwd)/docs/spec

cd src
for filename in $(find . -type f -regextype posix-egrep -regex '\./[0-9]{4}.*\.(tex|txt)'); do
  echo $f
  case "${filename##*.}" in
    tex)
      pdflatex ${filename}
      pdflatex ${filename}
      cp ${filename%.*}.pdf ${SPECDIR}
      rm -f *.pdf
      rm -f *.aux
      rm -f *.log
      rm -f *.toc
      ;;
    txt) # Font: Courier
# 10pt font
# 12pt line height
# 60 lines per page
# 72 characters per line
# 8 spaces per tab
# Based on A4 paper
      text2pdf -fCourier -s10 -v12 -l60 -c72 -t8 -A4 ${filename} > ${SPECDIR}/${filename%.*}.pdf
      ;;
  esac
done
