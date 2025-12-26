#!/bin/sh

# arguments:
# 1  :: alignment file
# 2  :: output directory
# 3- :: _stre.icb files

if [ "(x$1x)" == "(xx)" ]
then
  echo './tools/basilico-ali.sh alignment.ali output/ file1_stre.icb ... fileN_stre.icb'
  exit
fi

SCRIPTDIR="$(dirname "$(readlink -f -n "$0")")"
ALIFILE="$(readlink -f -n "$1")"
DIR="$(readlink -f -n "$2")"
shift 2

STREFILES=""
for f in "$@"
do
  STREFILES="${STREFILES}$(readlink -f -n $f) "
done

mkdir -p -- ${DIR}
TFILE="${DIR}/tf.tab"

# similar to the Pocketome web server
#ulimit -v 600000

cd ${SCRIPTDIR}/..

/local/icm/icm-3.9-2e//icm -p/local/icm/icm-3.9-2e/ scripts/basilico/ali.icm ali=${ALIFILE} of=${TFILE} ${STREFILES}

for f in $(sed '1,2d;s/^ \+//;s/ \+/%/' ${TFILE})
do
  STRE=$(echo ${f} | cut -d'%' -f 1)
  NAME=$(basename "${STRE}" _stre.icb)
  SVGROOT="${DIR}/${NAME}.svg"
  HTML="${DIR}/${NAME}.html"
  TSV="${DIR}/${NAME}.tsv"
  RSEL="${DIR}/${NAME}_rsel.txt"
  echo ${f} | cut -d'%' -f 2 > ${RSEL}
  rm -f -- ${SVGROOT} ${HTML} ${TSV}
  set -x
  icm ./scripts/basilico/mkweb.icm if=${STRE} osvg=${SVGROOT} ohtml=${HTML} otsv=${TSV} rsel=${RSEL}
  set +x
done

