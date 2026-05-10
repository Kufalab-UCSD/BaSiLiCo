#!/usr/bin/env bash

### BaSiLiCo local interface

echo
echo 'BaSiLiCo v1 (C) 2014-2018, 2026 Andrey Ilatovskiy'
echo
echo 'THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW.'
echo 'EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES'
echo 'PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,'
echo 'INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS'
echo 'FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE'
echo 'PROGRAM IS WITH YOU. SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL'
echo 'NECESSARY SERVICING, REPAIR OR CORRECTION.'
echo
echo 'IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT'
echo 'HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS THE PROGRAM AS PERMITTED ABOVE,'
echo 'BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL'
echo 'DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT'
echo 'LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU'
echo 'OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS), EVEN'
echo 'IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.'
echo

### confirm that the script is being executed with bash
if [ -n "${BASH_VERSION}" ] ; then
    echo "Info: bash version: ${BASH_VERSION}"
else
    echo 'Error: this script invokes bash-specific commands, please execute using bash'
    exit 1
fi

BASILICO_ROOT="$(dirname "$(readlink -f -n "$0")")"
export BASILICO_ROOT

### default values for input arguments
IFILE=
ODIR=
OBJECTMODE=
GENERATEWEB='true'

echo

function show_help {
  echo 'Usage:'
  echo "./${BASILICO_ROOT}/basilico.sh -i input.icb -d output/ [-o -w]"
  echo "./${BASILICO_ROOT}/basilico.sh -h"
  echo '  -o = object mode [default: ensemble mode]'
  echo '  -w = do not generate web files'
  echo '  -h = show this help message'
  echo
  exit "$1"
}

### parse arguments
while getopts ":i:d:owh" OPT; do
  case "${OPT}" in
    'i') IFILE="${OPTARG}" ;;
    'd') ODIR="${OPTARG}" ;;
    'o') OBJECTMODE='ob' ;;
    'w') GENERATEWEB='false' ;;
    'h') show_help 0 ;;
    '?')
      echo "Invalid option: -${OPTARG}" >&2
      show_help 1
      ;;
    ':')
      echo "Option -${OPTARG} requires an argument." >&2
      show_help 1
      ;;
  esac
done
shift $((OPTIND - 1)) # pop parsed arguments, leave the remaining arguments

### confirm that IFILE and ODIR are defined
[[ "${IFILE}" == '' ]] && show_help 0
[[ "${ODIR}"  == '' ]] && show_help 0

### canonicalize paths, resolve symlinks for the input file and output dir
IFILE="$(readlink -f -n "${IFILE}")"
ODIR="$(readlink -m -n "${ODIR}")"

### define the names for the output files
NAME="$(basename "${IFILE}" .icb)"
TAGGED="${ODIR}/${NAME}_tag.icb"
TLIG="${ODIR}/${NAME}_tlig.icb"
STRE="${ODIR}/${NAME}_stre.icb"
SVGROOT="${ODIR}/${NAME}.svg"
HTML="${ODIR}/${NAME}.html"
TSV="${ODIR}/${NAME}.tsv"

### execute
(

mkdir -pv -- "${ODIR}" || exit 1

rm -f -- "${TAGGED}" "${TLIG}" "${STRE}" "${SVGROOT}" "${HTML}" "${TSV}" || exit 1

set -x

echo
icm "${BASILICO_ROOT}/scripts/basilico/settags.icm" if="${IFILE}" of="${TAGGED}" || exit 1
[[ -e "${TAGGED}" ]] || exit 1

echo
icm "${BASILICO_ROOT}/scripts/basilico/ligclustering.icm" if="${TAGGED}" of="${TLIG}" "${OBJECTMODE}" || exit 1
[[ -e "${TLIG}" ]] || exit 1

echo
icm "${BASILICO_ROOT}/scripts/basilico/stre.icm" if="${TAGGED}" tlig="${TLIG}" of="${STRE}" "${OBJECTMODE}" || exit 1
[[ -e "${STRE}" ]] || exit 1

echo
[[ "${GENERATEWEB}" == 'false' ]] && exit 0

echo
icm "${BASILICO_ROOT}/scripts/basilico/mkweb.icm" if="${STRE}" osvg="${SVGROOT}" ohtml="${HTML}" otsv="${TSV}" || exit 1
[[ -e "${SVGROOT}" ]] || exit 1

set +x

) || exit 1

echo
echo 'Info: BaSiLiCo completed successfully'
echo

