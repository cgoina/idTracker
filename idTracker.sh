#!/bin/sh
exe_name=$0
exe_dir=`dirname "$0"`

MATLAB_ROOT=/misc/local/matlab-2018a
FFMPEG=/misc/local/ffmpeg-3.1.4/bin/ffmpeg

if [ "x$1" = "x-h" ]; then
  echo Usage:
  echo "$0 [-convert] <video-file> [<results-dir> [<number-of-individuals>]]"
  exit 1
elif [ "x$1" = "x-convert" ]; then
  shift
  input_file="$1"
  mv "${input_file}" "${input_file}.bak"
  ${FFMPEG} -i "${input_file}.bak" -vcodec mjpeg "${input_file}"
fi
${exe_dir}/bin/run_idTracker_nogui.sh ${MATLAB_ROOT} $*
