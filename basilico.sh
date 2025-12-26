### BaSiLiCo local interface

echo
echo "Info: BaSiLiCo v1, copyright 2019 Andrey Ilatovskiy"
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
IFILE=
ODIR=
OBJECTMODE=
LIMITMEMORY='true'
GENERATEWEB='true'

echo

function show_help {
  echo 'Usage:'
  echo 'bash '$BASILICO_ROOT'/tools/basilico.sh -i input.icb -d output/ [-o -w]'
  echo 'bash '$BASILICO_ROOT'/tools/basilico.sh -h'
  echo '  -o = object mode [default: ensemble mode]'
  echo '  -w = do not generate web files'
  echo '  -h = show this help message'
  echo
  exit $1
}

### parse arguments
while getopts ":i:d:oMwh" opt; do
  case $opt in
    i) IFILE=$OPTARG ;;
    d) ODIR=$OPTARG ;;
    o) OBJECTMODE='ob' ;;
    M) LIMITMEMORY='false' ;;
    w) GENERATEWEB='false' ;;
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
shift $((OPTIND - 1)) # Leave behind remaining arguments.

### confirm that IFILE and ODIR are defined
[ "x${IFILE}" == 'x' ] && show_help 0
[ "x${ODIR}"  == 'x' ] && show_help 0

### canonicalize paths, resolve symlinks for the input file and output dir
IFILE="$(readlink -f -n "${IFILE}")"
ODIR="$(readlink -m -n "${ODIR}")"

### define the names for the output files
NAME=$(basename "${IFILE}" .icb)
TAGGED="${ODIR}/${NAME}_tag.icb"
TLIG="${ODIR}/${NAME}_tlig.icb"
STRE="${ODIR}/${NAME}_stre.icb"
SVGROOT="${ODIR}/${NAME}.svg"
HTML="${ODIR}/${NAME}.html"
TSV="${ODIR}/${NAME}.tsv"

### execute
(

# similar to the Pocketome web server
[ "x${LIMITMEMORY}" == 'xtrue' ] && ulimit -m 600000

mkdir -pv -- ${ODIR} || exit 1

rm -f -- ${TAGGED} ${TLIG} ${STRE} ${SVGROOT} ${HTML} ${TSV}

set -x

echo
icm $BASILICO_ROOT/scripts/basilico/settags.icm if=${IFILE} of=${TAGGED} || exit 1
[ -e ${TAGGED} ] || exit 1

echo
icm $BASILICO_ROOT/scripts/basilico/ligclustering.icm if=${TAGGED} of=${TLIG} ${OBJECTMODE} || exit 1
[ -e ${TLIG} ] || exit 1

echo
icm $BASILICO_ROOT/scripts/basilico/stre.icm if=${TAGGED} tlig=${TLIG} of=${STRE} ${OBJECTMODE} || exit 1
[ -e ${STRE} ] || exit 1

echo
[ "x${GENERATEWEB}" == 'xfalse' ] && exit 0

echo
icm $BASILICO_ROOT/scripts/basilico/mkweb.icm if=${STRE} osvg=${SVGROOT} ohtml=${HTML} otsv=${TSV} || exit 1
[ -e ${SVGROOT} ] || exit 1

set +x

) || exit 1

echo
echo 'Info: BaSiLiCo completed successfuflly'
echo
