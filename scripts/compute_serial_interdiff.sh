#!/bin/sh

# ${1} - footprints directory
# ${2} - image directory

for FILE in $(find ${1} -name "*.shp" -type f); do

  TAG=$(basename ${FILE} .shp)

  BASE1=$(echo ${TAG} | cut -d+ -f1)
  BASE2=$(echo ${TAG} | cut -d+ -f2)

  IMG1=${2}"/"${BASE1}".tif"
  IMG2=${2}"/"${BASE2}".tif"

  TMP1="/tmp/A.tif"
  TMP2="/tmp/B.tif"

  gdalwarp -q -cutline ${FILE} -crop_to_cutline -r near -multi ${IMG1} ${TMP1}
  gdalwarp -q -cutline ${FILE} -crop_to_cutline -r near -multi ${IMG2} ${TMP2}

  TARGET=${TAG}".tif"

  gdal_calc.py -A ${TMP1} --allBands=A \
               -B ${TMP2} --allBands=B \
               --NoDataValue=255 --outfile=${TARGET} \
               --calc="numpy.abs( A - B )" --overwrite 2>&1 1>/dev/null

  gdal_edit.py -stats ${TARGET}

  gdaladdo -q -r average -ro ${TARGET} 2 4 8 16

  rm -f ${TMP1} ${TMP2}

done
