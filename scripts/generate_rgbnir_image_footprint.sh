#!/bin/sh

function help {

  printf "\nUsage:\n\t$(basename ${0}) [ -h | -f ]"
  printf " <IMAGE_FILE> <NODATA_VALUE> <OUT_DIR>\n"
  exit ${1}
}

F="numpy.logical_or"

while getopts "fh" OPT; do
  case ${OPT} in
    f) F="numpy.logical_and";;
    h) help 0;;
  esac
done

shift $((${OPTIND} - 1))

if [ ${#} -ne 3 ]; then

  help 1

fi

if [ ! -f ${1} ]; then

  echo "First input argument must be an image file (GDAL supported format)"
  exit 1

fi

echo ${2} | egrep -q '^[+|-]?[0-9]+$'

if [ ${?} -ne 0 ]; then

  echo "Second argument must be a valid number"
  exit 1

fi

if [ ! -d ${3} ]; then

  echo "Third input argument must be a directory"
  exit 1

fi

LOGICAL=$(printf "%s( %s( %s( A!=%s, B!=%s ), C!=%s ), D!=%s )" \
                 ${F} ${F} ${F} ${2} ${2} ${2} ${2})

TAG=$(printf "image_mask_%d" $(shuf -i 0-1000 -n 1))

TEMP1="${TMP}/${TAG}.tif"
TEMP2="${TMP}/${TAG}.shp"

gdal_calc.py -A ${1} --A_band=1 \
             -B ${1} --B_band=2 \
             -C ${1} --C_band=3 \
             -D ${1} --D_band=4 \
             --calc="${LOGICAL}" --NoDataValue=0 --type=Byte --format=GTiff \
             --overwrite --quiet --outfile=${TEMP1}

gdal_polygonize.py -q ${TEMP1} -f "ESRI Shapefile" ${TEMP2}

TARGET=${3}"/"$(basename ${1} | cut -d. -f1)".shp"

ogr2ogr ${TARGET} ${TEMP2} -f "ESRI Shapefile" -where "DN=127" -overwrite

LAYER=$(basename ${TARGET} .shp)

SQL=$(printf "ALTER TABLE %s ADD COLUMN SOURCE VARCHAR(64)" ${LAYER})

ogrinfo -q ${TARGET} -sql "${SQL}"

SQL=$(printf "UPDATE '%s' SET SOURCE = '%s'" ${LAYER} $(basename ${1}))

ogrinfo -q ${TARGET} -dialect SQLite -sql "${SQL}"

find ${TMP} -maxdepth 1 -name "${TAG}.*" -type f -delete
