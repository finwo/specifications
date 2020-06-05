#!/usr/bin/env bash

echo "Building specifications"
ORGDIR=$(pwd)/src/spec
SPECDIR=$(pwd)/docs/spec

# Write readme & html headers
cat src/html/index.html.head > docs/index.html
cat src/markdown/README.md.head > README.md

find ${ORGDIR} -maxdepth 1 -type d -regextype posix-egrep -regex '.*[0-9]{4}' | sort | while read spec; do

  # Read specification document data
  declare -A DATA
  while IFS='=' read key value; do
    DATA["$key"]="$value"
  done <<< "$(script/ini.sh ${spec}/data.ini)"

  # Show we're actually working
  echo "  ${DATA[identifier]}: ${DATA[title]}"

  # Render readme & html entries
  script/template.sh -c ${spec}/data.ini src/html/index.html.entry >> docs/index.html
  script/template.sh -c ${spec}/data.ini src/markdown/README.md.entry >> README.md

  # Check how to render the document itself
  filename=$(echo ${spec}/document.*)
  case "${filename##*.}" in
    tex)
      pdflatex ${filename} >/dev/null
      pdflatex ${filename} >/dev/null
      cp document.pdf ${SPECDIR}/${DATA[identifier]}.pdf
      rm -f *.pdf
      rm -f *.aux
      rm -f *.log
      rm -f *.toc
      ;;
    txt)
      # Include render data
      script/template.sh -c ${spec}/data.ini ${filename} >> ${filename}.rendered

      # Font: Courier
      # 10pt font
      # 12pt line height
      # 60 lines per page
      # 80 characters per line
      # 8 spaces per tab
      # Based on A4 paper

      # -c81 because of a minor bug in text2pdf
      text2pdf -fCourier -s10 -v12 -l60 -c81 -t8 -A4 ${filename}.rendered > ${SPECDIR}/${DATA[identifier]}.pdf

      # Remove rendered version
      rm ${filename}.rendered
      ;;
    *)
      echo "Unknown document type: ${filename##*.}" 1>&2
      exit 1
  esac
done

# Write readme & html footers
cat src/html/index.html.tail >> docs/index.html
cat src/markdown/README.md.tail >> README.md
