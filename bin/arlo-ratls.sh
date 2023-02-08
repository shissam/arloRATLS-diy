#!/bin/bash

#
#
#

processVideo()
{
  _d="${1}"
  _vidd=$(echo "${_d}" | egrep -o ".*/metadata" | sed 's^/metadata^^g')
  _f="${2}"

  #
  # is the file named .meta, fail if not
  #
  echo ${_f} | egrep -q -o "(_[[:digit:]]*_[[:digit:]]*\.meta$)"
  if [ ${?} -eq 1 ]; then
    echo 
    echo "${_f}": NG
    echo 
    return 1
  fi

  #
  # does the file exist, fail if not
  #
  if [ ! -f "${_d}/${_f}" ]; then
    echo 
    echo "${_d}/${_f}": not found
    echo 
    return 1
  fi

  #
  # is the file a properly formatted Arlo json object, fail if not
  #
  _presignedContentUrl="$(jq -r .presignedContentUrl < ${_d}/${_f})"
  if [ -z "${_presignedContentUrl}" -o "${_presignedContentUrl}" = "null" ]; then
    echo 
    echo "${_d}/${_f}": not an Arlo meta file
    echo 
    return 1
  fi
  _videoFile=$(basename "${_presignedContentUrl}")
  if [ ! -s "${_vidd}/${_presignedContentUrl}" ]; then
    _presignedContentUrl=$(echo "${_presignedContentUrl}" | sed 's^arlo/^^g')
    [ ! -s "${_vidd}/${_presignedContentUrl}" ] && \
	"${_logger}" \
	-t "${_logname}" \
	-i "ERROR: cannot find ${_videoFile} at ${_vidd}/${_presignedContentUrl}" && \
        return 1
  fi

  #
  # this could be potentially noisy
  # TODO: consider throttling, do only when testing, or adding verbose levels
  #
  ${verbose} && ${testing} && "${_logger}" -t "${_logname}" -i "${_f} has appeared in ${_d}"

  #
  # create a thumbnail of the new video
  # symlink video in Arlo store to library
  # create/update video index for that day
  #

  _presignedThumbnailUrl="$(jq -r .presignedThumbnailUrl < ${_d}/${_f})"
  #
  # mangle the thumbnail name for our purpose
  #
  _th="$(echo ${_presignedThumbnailUrl} | sed 's/metadata/library/g;s/jpeg/jpg/g')"
  _thumbnailFile=$(basename "${_th}")

  # changes arlo/library/20230108 to arlo/library/2023-01-08
  _datedLibdir=$(dirname $(dirname "${_th}") | sed 's^.^&-^19' | sed 's^.^&-^17')

  ${verbose} && ${testing} && "${_logger}" -t "${_logname}" -i "${_presignedThumbnailUrl} is now ${_thumbnailFile} in ${_datedLibdir}"

  mkdir -p "${_localdir}/${_datedLibdir}"
  ln -s "${_vidd}/${_presignedContentUrl}" "${_localdir}/${_datedLibdir}" 2>/dev/null

  #
  # really: https://stackoverflow.com/questions/55682533/why-read-command-in-shell-script-is-missing-initial-characters
  # and https://mywiki.wooledge.org/BashFAQ/089
  #
  [ -f "${_localdir}/${_datedLibdir}/${_videoFile}" ] && \
    [ ! -f "${_localdir}/${_datedLibdir}/${_thumbnailFile}" ] && \
      ffmpeg -y \
        -hide_banner \
        -loglevel error \
        -ss 00:00:03 \
        -i "${_localdir}/${_datedLibdir}/${_videoFile}" \
        -filter:v scale="640:-1" \
        -frames:v 1 \
        "${_localdir}/${_datedLibdir}/${_thumbnailFile}" < /dev/null

  makeURLs "${_datedLibdir}/${_videoFile}" \
           "${_datedLibdir}/${_thumbnailFile}" \
           "$(findCamName $(jq -r .createdBy < ${_d}/${_f}))" \
           "$(jq -r .lastModified < ${_d}/${_f})" \
           "$(jq -r .mediaDuration < ${_d}/${_f})" \
           "$(jq -r .reason < ${_d}/${_f})"

  return 0
}

# ls -1 | sort -k1.24,1.38 will produce a list sorted by 
# date identified in the filename of the pattern 
# 55W1777UA375D_00000055_20230108_141148.meta
#          1         2   4     3       8
# 123456789^123456789^123456789^12345678^1234

makeURLs()
{
  _fqpn="${_localdir}/$(dirname ${1})"
  _libn="$(basename ${_fqpn})"
  _vid="$(echo ${1} | sed 's^arlo/^^g')" 
  _thb="$(echo ${2} | sed 's^arlo/^^g')" 
  _anc="$(basename ${2} | sed 's/\.jpg//g')"
  _name="$(echo ${3} | sed 's^ ^<br>^g')"
  _time="$(date --date=@${4} '+%I:%M %p')"
  _dura=${5}
  _reas=${6}

  ${verbose} && ${rebuild} && ${testing} && "${_logger}" -t "${_logname}" -i "working with: ${_fqpn}: as lib=${_libn} vid=${_vid} thb=${_thb} anc=${_anc}"

  #
  # https://www.w3schools.com/tags/tag_video.asp
  #
# cat <<URL
# <a href="#${_anc}"><p id="${_anc}"><img width=640 height=360 src="${_thb}" onclick="playVideo('${_anc}','${_vid}');" alt="Cannot Show Video">&nbsp;</img></p></a>
# URL

  # needs to be one line as this line will be use to sort

  if [ -f "${_fqpn}/lib${_libn}.txt" ]; then
     egrep -v "(^<)" ${_fqpn}/lib${_libn}.txt > ${_fqpn}/lib${_libn}.txt.raw
  fi

  #
  # append the video as a table-row (do not assume it is the newest, as in a rebuild)
  #
  cat <<ROW >> ${_fqpn}/lib${_libn}.txt.raw
    <div style="display: table-row;"> <div style="width: 75%; display: table-cell;border: 5px outset white;"> <a href="#${_anc}"></a><p id="${_anc}"><img width="100%" src="${_thb}" onclick="playVideo('${_anc}','${_vid}');" alt="Cannot Show Video">&nbsp;</img></p> </div> <div style="display: table-cell;border: 5px outset black; vertical-align: top; padding: 15px;"> <p style="font-size:30px;">${_name}</p> <p style="font-size:30px;">${_time}</p> <p style="font-size:30px;">${_dura} ${_reas}</p> </div> </div>
ROW

  #
  # put the div at the top of the (new) table
  #
  cat <<PRETABLE > ${_fqpn}/lib${_libn}.txt.new
<div id="lib$(echo ${_thb} | cut -d/ -f2 | sed 's/-//g')" style="width: 100%; display: table;">
PRETABLE

  #
  # sort this mess based on the character col positions of the table rows
  # which represent the date time stamps
  #
  sort -r -k1.144,1.158 < ${_fqpn}/lib${_libn}.txt.raw | uniq >> ${_fqpn}/lib${_libn}.txt.new

  #
  # put the div close at the bottom of the (new) table
  #
  cat <<POSTTABLE >> ${_fqpn}/lib${_libn}.txt.new
</div>
POSTTABLE

  #
  # deploy the new table
  #
  mv ${_fqpn}/lib${_libn}.txt.new ${_fqpn}/lib${_libn}.txt
  rm ${_fqpn}/lib${_libn}.txt.raw
}

findCamName()
{
  #
  # if no device map, simply reflect back arg
  #
  [[ ! -v DEVICEMAP[@] ]] && echo "${1}" && return

  if [ ${DEVICEMAP[$1]+_} ]; then
    echo ${DEVICEMAP[$1]};
  else
    echo ${1};
  fi

  return
}

check_requirements()
{
[ -z "$(which jq)" ] && \
  "${_logger}" \
    -t "${_logname}" \
    -i "jq: not found, cannot parse Arlo metadata, exiting..." \
  && exit 1

[ -z "$(which ffmpeg)" ] && \
  "${_logger}" \
    -t "${_logname}" \
    -i "ffmpeg: not found, cannot generate thumbnails, exiting..." \
  && exit 1

[ -z "$(which inotifywait)" ] && \
  "${_logger}" \
    -t "${_logname}" \
    -i "inotifywait: not found: cannot watch for new metafiles, exiting..." \
  && exit 1

[ ! -s "${_ratls_conf}" ] && \
  "${_logger}" \
    -t "${_logname}" \
    -i "${_ratls_conf}: not found or empty: defaults will likely not work"

[ ! -d "${RATLS_LIB}" ] && \
  "${_logger}" \
    -t "${_logname}" \
    -i "ERROR: no RATLS_LIB=${RATLS_LIB}"

[ ! -d "${RATLS_LIB}/arlo/metadata" ] && \
  "${_logger}" \
    -t "${_logname}" \
    -i "ERROR: no Arlo metadir ${RATLS_LIB}/arlo/metadata, too many errors, exiting..." \
  && exit 1

[[ ! -v DEVICEMAP[@] ]] && \
  "${_logger}" \
  -t "${_logname}" \
  -i "WARNING: no DEVICEMAP found in ARLO_CAMS=${ARLO_CAMS}, will use device serial numbers"

}

#
# main
#

_logger=/usr/bin/logger
_logname=${RATLS_NAME:-"arlo-ratls.sh"}

#_ratls_conf="${RATLSCONF:-/etc/arlo-ratls/arlo-ratls.conf}"
_ratls_conf="${RATLSCONF:-/home/pi/prod/etc/arlo-ratls/arlo-ratls.conf}"

#
# get DEVICEMAP and other config values (bash vars)
#
[ -s "${_ratls_conf}" ] && source "${_ratls_conf}"

[ ! -z "${ARLO_CAMS}" ] && source "${ARLO_CAMS}"

check_requirements

#
# sub-structure is like
# RATLS_LIB
#   |-- arlo
#        |-- 000xxx   (where recording from the USB are sync'ed to)
#        |-- metadata (where metadata from the USB are sync'ed to)
#        |-- library  (where arlo-ratls manages symlinks/thumbnails)
#
_localdir=${RATLS_LIB}
_metadir=${_localdir}/arlo/metadata
#
# this is writeable where symlinks and thumbnails are maintained
#
_libdir=${_localdir}/arlo/library

rebuild="false"
testing="false"
testobj=""
verbose="false"

while getopts “l:m:nrt:v” opt; do
  case $opt in
    l) logging="true"; _logname="${OPTARG}" ;;
    m) logging="true"; _logmesg="${OPTARG}" ;;
    n) dryrun="echo +" ;;
    r) rebuild="true" ;;
    t) testing="true"; _testobj="${OPTARG}" ;;
    v) verbose="true" ;;
    *) cat <<-OPTSEOF
	USAGE: ${0} [OPTIONS]

	OPTIONS

	-l:     log action and syslog name for logging
	-m:     log action and syslog message for logging
	-r:     rebuild all databases
	-t:	test (single file or folder) (for rebuild cmd only)
	-v:	additional messages to log

	OPTSEOF
       exit 1
  esac
done
shift $((OPTIND-1))


${verbose} && "${_logger}" -t "${_logname}" -i "RATLS_LIB=${RATLS_LIB}"
${verbose} && "${_logger}" -t "${_logname}" -i "All keys: ${!DEVICEMAP[@]}"
${verbose} && "${_logger}" -t "${_logname}" -i "Key count: ${#DEVICEMAP[@]}"
${verbose} && "${_logger}" -t "${_logname}" -i "test ok cam: $(findCamName 33W1701UF001A)"
${verbose} && "${_logger}" -t "${_logname}" -i "test ng cam: $(findCamName NCC1701UFP01A)"

mkdir -p "${_libdir}"

#
# inotifywait pattern
#
# ${RATLS_LIB}/arlo/metadata/YYYYMMDD/<cam serial num>/ MOVED TO <cam serial num>_<8hexdigits>_YYYYMMDD_HHmmss.meta
# as in:
# /media/nas/arlo/metadata/20230108/33W1701UF001A/ MOVED_TO 33W1701UF001A_0000005c_20230108_172737.meta

#
# rebuild pattern (based on output from 'find'
#
# /media/nas/arlo/metadata/20230114/33W1701UF001A/33W1701UF001A_0000015f_20230114_053945.meta

_cmdpump="inotifywait -m -e moved_to -r "${_metadir}"/"
${rebuild} && _cmdpump="find "${_metadir}"/ -type f -print"
${rebuild} && ${testing} && _cmdpump="echo "${_testobj}""
${rebuild} && ${testing} && [ -d "${_testobj}" ] && _cmdpump="find "${_testobj}"/ -type f -print"

${verbose} && "${_logger}" -t "${_logname}" -i "Cmd mode: ${_cmdpump}"

${_cmdpump} | \
while read line
do
  if [ ${rebuild} == true ]; then
    DIR="$(dirname ${line})"
    EVENT="MOVED_TO"
    FILE="$(basename ${line})"
  else
    DIR="$(echo ${line} | cut -d\  -f1)"
    EVENT="$(echo ${line} | cut -d\  -f2)"
    FILE="$(echo ${line} | cut -d\  -f3)"
  fi

  case ${EVENT} in
     MOVED_TO)
       ${dryrun} processVideo "${DIR}" "${FILE}"
       if [ "${?}" -eq "1" ]; then
          "${_logger}" -t "${_logname}" -i  "retry processVideo on ${FILE} at ${DIR}"
          ${dryrun} processVideo "${DIR}" "${FILE}"
          if [ "${?}" -eq "1" ]; then
             "${_logger}" -t "${_logname}" -i  "processVideo Failed"
          fi
       fi
       ;;
     *) "${_logger}" -t "${_logname}" -i  "some else, ${EVENT}, occurred with ${FILE}" ;;
  esac
done
