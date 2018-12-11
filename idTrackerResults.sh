#!/bin/sh
exe_name=$0
exe_dir=`dirname "$0"`

MATLAB_ROOT=/misc/local/matlab-2018a

${exe_dir}/bin/run_idTrackerResults.sh ${MATLAB_ROOT} $*
