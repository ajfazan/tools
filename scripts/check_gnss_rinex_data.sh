#!/bin/sh

if [ ! -d ${1} ]; then

  echo "${1} is not a GNSS RINEX data directory"
  exit 1

fi

cd ${1}

STATION=$(basename ${1})

ls *.* > collection.dat

if [ $(cat collection.dat | wc -l) -ne 3 ]; then

  echo "WARNING: Check RINEX data files for point ${STATION}"
  exit 2

fi

if [ $(egrep -i 'O$' collection.dat | wc -l) -lt 1 ]; then

  echo "Missing GNSS observation data for point ${STATION}"

fi

if [ $(egrep -i 'N$' collection.dat | wc -l) -lt 1 ]; then

  echo "Missing GPS navigation data for point ${STATION}"

fi

if [ $(egrep -i 'G$' collection.dat | wc -l) -lt 1 ]; then

  echo "Missing GLONASS navigation data for point ${STATION}"

fi

rm -f collection.dat

cd - 1>/dev/null