#!/usr/bin/env bash

### BaSiLiCo for sequence alignment

echo
echo 'BaSiLiCo ali v1 (C) 2014-2018, 2026 Andrey Ilatovskiy'
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
ALIFILE=
ODIR=

function show_help {
  set +x
  echo
  echo 'Usage:'
  echo "./${BASILICO_ROOT}/basilico-ali.sh -a msa.ali -d BaSiLiCo_ali_output/ BaSiLiCo_output/*_stre.icb"
  echo "./${BASILICO_ROOT}/basilico-ali.sh -h"
  echo
  echo 'Requirements:'
  echo '* BaSiLiCo_output/*_stre.icb files which are outputs of basilico.sh'
  echo '* Each must contain one or more full-length (usually SwissProt) amino-acid sequences matching the objects'
  echo '* Molecules in the objects must be tagged (set swiss) with the names of the corresponding sequences'
  echo '* msa.ali must be an alignment of these very sequences'
  echo
  echo 'Output:'
  echo '* a set of BaSiLiCo fingerprint .svg files for each input *_stre.icb where the fingerprints are spaced to account for alignment gaps'
  echo '* these .svg files can be combined in a graphics editor to produce an MSA-guided fingerprint map'
  echo
  exit "$1"
}

### parse arguments
while getopts ":a:d:h" OPT; do
  case "${OPT}" in
    'a') ALIFILE="${OPTARG}" ;;
    'd') ODIR="${OPTARG}" ;;
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

### remaining positional args are interpreted as *_stre.icb files

### confirm that ALIFILE and ODIR are defined
[[ "${ALIFILE}" == '' ]] && show_help 0
[[ "${ODIR}"  == '' ]] && show_help 0

ALIFILE="$(readlink -f -n "${ALIFILE}")"
ODIR="$(readlink -f -n "${ODIR}")"

mkdir -p -- "${ODIR}" || exit 1
TFILE="${ODIR}/tf.tab"

### execute
set -x
icm "${BASILICO_ROOT}/scripts/basilico/ali.icm" ali="${ALIFILE}" of="${TFILE}" "$@" || show_help 1 
[[ -e ${TFILE} ]] || show_help 1
set +x

for f in $(sed '1,2d;s/^ \+//;s/ \+/%/' "${TFILE}")
do
  STRE="$(echo "${f}" | cut -d'%' -f 1)"
  NAME="$(basename "${STRE}" _stre.icb)"
  SVGROOT="${ODIR}/${NAME}.svg"
  HTML="${ODIR}/${NAME}.html"
  TSV="${ODIR}/${NAME}.tsv"
  RSEL="${ODIR}/${NAME}_rsel.txt"
  echo "${f}" | cut -d'%' -f 2 > "${RSEL}"
  rm -f -- "${SVGROOT}" "${HTML}" "${TSV}" || exit 1
  set -x
  icm "${BASILICO_ROOT}/scripts/basilico/mkweb.icm" if="${STRE}" osvg="${SVGROOT}" ohtml="${HTML}" otsv="${TSV}" rsel="${RSEL}"
  set +x
done

