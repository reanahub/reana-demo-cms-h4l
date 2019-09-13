cwlVersion: v1.0
class: CommandLineTool

baseCommand: /bin/zsh

requirements:
  DockerRequirement:
    dockerPull:
      cmsopendata/cmssw_5_3_32
  InitialWorkDirRequirement:
    listing:
      - $(inputs.code)
      - $(inputs.data)

inputs:
  data:
    type: Directory
  code:
    type: Directory
  DoubleMuParked2012C_10000_Higgs:
    type: File
  Higgs4L1file:
    type: File

stdout: make_plot.log

outputs:
  make_plot.log:
    type: stdout
  mass4l_combine_userlvl3.pdf:
    type: File
    outputBinding:
      glob: "results/mass4l_combine_userlvl3.pdf"

arguments:
  - prefix: -c
    valueFrom: |
      source /opt/cms/cmsset_default.sh
      scramv1 project CMSSW CMSSW_5_3_32
      cd CMSSW_5_3_32/src
      eval `scramv1 runtime -sh`
      cp -r ../../../../code/HiggsExample20112012 .
      cd HiggsExample20112012/Level3
      mkdir -p ../../../../results
      cp $(inputs.DoubleMuParked2012C_10000_Higgs.path) ../../../../results
      cp $(inputs.Higgs4L1file.path) ../../../../results
      root -b -l -q ./M4Lnormdatall_lvl3.cc
