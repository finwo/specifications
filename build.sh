#!/usr/bin/env bash

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
    txt)
      # Font: Courier
      # 10pt font
      # 12pt line height
      # 60 lines per page
      # 80 characters per line
      # 8 spaces per tab
      # Based on A4 paper

      # -c81 because of a minor bug in text2pdf
      text2pdf -fCourier -s10 -v12 -l60 -c81 -t8 -A4 ${filename} > ${SPECDIR}/${filename%.*}.pdf
      ;;
  esac
done
