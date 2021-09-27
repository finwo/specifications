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
  while read line; do
    key=${line%%=*}
    value=${line#*=}
    if [ -z "$key" ]; then continue; fi
    DATA["$key"]="$value"
  done <<< "$(tool/ini.sh ${spec}/data.ini)"

  # Show we're actually working
  echo "  ${DATA[identifier]}: ${DATA[title]}"

  # Render readme & html entries
  tool/template.sh -c ${spec}/data.ini src/html/index.html.entry >> docs/index.html
  tool/template.sh -c ${spec}/data.ini src/markdown/README.md.entry >> README.md

  # Skip rendering already-existing files
  if [ -f "${SPECDIR}/${DATA[identifier]}.pdf" ]; then
    continue;
  fi

  # Check how to render the document itself
  filename=$(ls ${spec}/document.* | head -1)
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
      tool/template.sh -c ${spec}/data.ini ${filename} > ${filename}.rendered

      # Font: Courier
      # 10pt font
      # 12pt line height
      # 80 characters per line
      # 8 spaces per tab
      # Based on A4 paper

      # <0003 = 60 lines per page
      # >=0003 = 63 lines per page
      LPP=60
      if [ "${DATA[identifier]}" -ge "3" ]; then
        LPP=63
      fi

      # -c 81 because of a minor bug in text2pdf
      text2pdf -f Courier -s 10 -v 12 -l $LPP -c 81 -t 8 -A 4 -T "${DATA[identifier]} - ${DATA[title]}" < ${filename}.rendered > ${SPECDIR}/${DATA[identifier]}.pdf

      # Remove rendered version
      rm ${filename}.rendered
      ;;
    md)
      tool/template.sh -c ${spec}/data.ini ${filename} | smu > ${filename}.html
      htmldoc --webpage --textfont sans --size A4 -f ${SPECDIR}/${DATA[identifier]}.pdf ${filename}.html
      rm ${filename}.html
      ;;
    hbs)
      # Include render data
      tool/template.sh -c ${spec}/data.ini ${filename} > ${filename}.html
      htmldoc --webpage --textfont sans --size A4 -f ${SPECDIR}/${DATA[identifier]}.pdf ${filename}.html
      rm ${filename}.html
      ;;
    rendered)
      # Skip
      ;;
    *)
      # echo "Unknown document type: ${filename##*.}" 1>&2
      # exit 1
  esac
done

# Write readme & html footers
cat src/html/index.html.tail >> docs/index.html
cat src/markdown/README.md.tail >> README.md
