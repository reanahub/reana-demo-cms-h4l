#!/bin/bash
# Walk an HTCondor job through everything a real analyze_chunk job needs,
# reporting each stage separately and always exiting successfully, so that
# the logs come back even when a stage fails. Queue time on the farm is
# tens of minutes per submission, which makes one job that tests every
# stage far cheaper than bisecting one factor at a time.
#
# Deliberately does not use `set -e`: a failing stage must not stop the
# ones after it.

WORKDIR=$(pwd)
echo "=== 1. node and workspace ==="
hostname
id
echo "PWD: $WORKDIR"
ls -la

echo "=== 2. cvmfs ==="
if ls /cvmfs/ 2>&1; then
    ls /cvmfs/cms.cern.ch/ 2>&1 | head -3
    echo "STAGE2 OK"
else
    echo "STAGE2 FAILED"
fi

echo "=== 3. cms environment ==="
# shellcheck disable=SC1091  # lives inside the CMSSW image, not in this repo
if source /opt/cms/cmsset_default.sh; then
    echo "STAGE3 OK"
else
    echo "STAGE3 FAILED"
fi

echo "=== 4. scram project area ==="
if scramv1 project CMSSW CMSSW_5_3_32; then
    echo "STAGE4 OK"
else
    echo "STAGE4 FAILED"
fi

echo "=== 5. build the analyzer ==="
if cd "$WORKDIR/CMSSW_5_3_32/src" &&
    eval "$(scramv1 runtime -sh)" &&
    cp -r "$WORKDIR/code/HiggsExample20112012" . &&
    cd HiggsExample20112012/HiggsDemoAnalyzer &&
    scram b; then
    echo "STAGE5 OK"
else
    echo "STAGE5 FAILED"
fi

echo "=== 6. xrootd reach to eos ==="
FILE=root://eospublic.cern.ch//eos/opendata/cms/Run2012C/DoubleMuParked/AOD/22Jan2013-v1/10000/0002ACB4-C96C-E211-A96F-20CF3027A628.root
if xrdfs eospublic.cern.ch stat "${FILE#root://eospublic.cern.ch/}" 2>&1; then
    echo "STAGE6 OK"
else
    echo "STAGE6 FAILED"
fi

echo "=== done ==="
mkdir -p "$WORKDIR/results"
echo "diagnose finished" >"$WORKDIR/results/diagnose.txt"
exit 0
