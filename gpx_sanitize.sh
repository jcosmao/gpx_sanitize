#!/bin/bash

# GPX sanitizer
# https://oleb.net/2020/sanitizing-gpx/
#
# It remove useless infos to have a minimal gpx (no time, speed)
# it also rename gpx from filename
# GPX are now compatible with Bryton GPS

SCRIPT=$(readlink -f $0)
SCRIPTPATH=$(dirname $SCRIPT)

gpx="$1"

[[ -z $gpx ]] && echo "$SCRIPT <gpx>" && exit 1

which xmlstarlet &> /dev/null
[[ $? -ne 0 ]] && echo "Need xmlstarlet binary" && exit 1

which gpsbabel &> /dev/null
[[ $? -ne 0 ]] && echo "Need gpsbabel binary" && exit 1

filename=$(basename "$gpx")
name=${filename%.*}
tmp=$(mktemp)

# Simplify gpx
gpsbabel -i gpx -o gpx -f "$gpx" -x simplify,crosstrack,error=0.001k -F $tmp && mv $tmp "$gpx"

xmlstarlet ed \
  -d "//_:extensions" \
  -d "/_:gpx/_:metadata" \
  -d "/_:gpx/_:trk/_:type" \
  -u "/_:gpx/_:trk/_:name" -v "$name" \
  -d "//_:trkpt/_:time" \
  -d "//_:trkpt/_:hdop" \
  -d "//_:trkpt/_:vdop" \
  -d "//_:trkpt/_:pdop" \
  -u "/_:gpx/@creator" -v "$(basename $SCRIPT)" \
  "$gpx" | \
  xmlstarlet tr $SCRIPTPATH/remove_useless.xslt - | \
  xmllint --c14n11 --pretty 2 -  | \
  sed 1i'<?xml version="1.0" standalone="yes"?>' > "$name.sanitized.gpx"
