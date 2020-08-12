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

  # Skip rendering already-existing files
  if [ -f "${SPECDIR}/${DATA[identifier]}.pdf" ]; then
    continue;
  fi

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
      script/template.sh -c ${spec}/data.ini ${filename} > ${filename}.rendered

      # <0003 = 60 lines per page
      # >=0003 = 63 lines per page
      LPP=60
      if [ "${DATA[identifier]}" -ge "3" ]; then
        LPP=63
      fi
      echo "LPP: ${LPP}"

      # Font: Courier
      # 10pt font
      # 12pt line height
      # 60 lines per page
      # 80 characters per line
      # 8 spaces per tab
      # Based on A4 paper

      # -c 81 because of a minor bug in text2pdf
      text2pdf -f Courier -s 10 -v 12 -l $LPP -c 81 -t 8 -A 4 -T "${DATA[identifier]} - ${DATA[title]}" < ${filename}.rendered > ${SPECDIR}/${DATA[identifier]}.pdf

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
