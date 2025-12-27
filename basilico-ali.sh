### local interface for BaSiLiCo w/sequence alignment

echo
echo "Info: BaSiLiCo ali v1, copyright 2019 Andrey Ilatovskiy"
### confirm that the script is being executed with bash 
if [ -n "$BASH_VERSION" ]; then
    echo "Info: Executed with bash version $BASH_VERSION"
else
    echo "Error: this script invokes bash-specific commands, please execute using bash"
    echo
    exit 1
fi

export BASILICO_ROOT="$(dirname "$(readlink -f -n "$0")")"

### default values for input arguments
ALIFILE=
ODIR=

function show_help {
  set +x
  echo
  echo 'Usage:'
  echo '  bash '$BASILICO_ROOT'/basilico-ali.sh -a msa.ali -d BaSiLiCo_ali_output/ BaSiLiCo_output/*_stre.icb'
  echo '  bash '$BASILICO_ROOT'/basilico-ali.sh -h'
  echo
  echo 'Requirements:'
  echo '* BaSiLiCo_output/*_stre.icb files which are outputs of basilico.sh'
  echo '* Each must contain one or more full-length (usually SwissProt) amino-acid sequences matching the objects'
  echo '* Molecules in the objects must be tagged (set swiss) with the names of the corresponding sequences'
  echo '* msa.ali must be an alignment of these very sequences'
  echo
  echo 'Output:'
  echo '* a set of BaSiLiCo fingerprint .svg files for each input *_stre.icb where the fingerprints are spaced to account for alignment gaps'
  echo '* these .svg files can be combined in Adobe Illustrator to produce an MSA-guided fingerprint map'
  echo
  exit $1
}

### parse arguments
while getopts ":a:d:h" opt; do
  case $opt in
    a) ALIFILE=$OPTARG ;;
    d) ODIR=$OPTARG ;;
    h) show_help 0 ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      show_help 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      show_help 1
      ;;
  esac
done
shift $((OPTIND - 1)) # pop parsed arguments, leave the remaining arguments

### confirm that ALIFILE and ODIR are defined
[ "x${ALIFILE}" == 'x' ] && show_help 0
[ "x${ODIR}"  == 'x' ] && show_help 0
ALIFILE="$(readlink -f -n "$ALIFILE")"
ODIR="$(readlink -f -n "$ODIR")"

### remaining positional args are interpreted as *_stre.icb files
STREFILES=""
for f in "$@"
do
  STREFILES="${STREFILES}$(readlink -f -n $f) "
done

mkdir -p -- ${ODIR}
TFILE="${ODIR}/tf.tab"

# similar to the Pocketome web server
ulimit -v 6000000 ### 2025-12-26 IK - used to be 600000 but this is not enough to start icm resulting in a segfault on the next command

### execute
set -x
icm $BASILICO_ROOT/scripts/basilico/ali.icm ali=${ALIFILE} of=${TFILE} ${STREFILES} || show_help 1 
[ -e ${TFILE} ] || show_help 1
set +x

for f in $(sed '1,2d;s/^ \+//;s/ \+/%/' ${TFILE})
do
  STRE=$(echo ${f} | cut -d'%' -f 1)
  NAME=$(basename "${STRE}" _stre.icb)
  SVGROOT="${ODIR}/${NAME}.svg"
  HTML="${ODIR}/${NAME}.html"
  TSV="${ODIR}/${NAME}.tsv"
  RSEL="${ODIR}/${NAME}_rsel.txt"
  echo ${f} | cut -d'%' -f 2 > ${RSEL}
  rm -f -- ${SVGROOT} ${HTML} ${TSV}
  set -x
  icm $BASILICO_ROOT/scripts/basilico/mkweb.icm if=${STRE} osvg=${SVGROOT} ohtml=${HTML} otsv=${TSV} rsel=${RSEL}
  set +x
done

