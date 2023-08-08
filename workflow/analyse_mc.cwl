cwlVersion: v1.0
class: CommandLineTool

baseCommand: /bin/zsh

requirements:
  DockerRequirement:
    dockerPull:
      docker.io/cmsopendata/cmssw_5_3_32
  InitialWorkDirRequirement:
    listing:
      - $(inputs.code)
      - $(inputs.data)

inputs:
  data:
    type: Directory
  code:
    type: Directory

stdout: analyse_mc.log

outputs:
  analyse_mc.log:
    type: stdout
  Higgs4L1file.root:
    type: File
    outputBinding:
       glob: "results/Higgs4L1file.root"

arguments:
  - prefix: -c
    valueFrom: |
      source /opt/cms/cmsset_default.sh
      scramv1 project CMSSW CMSSW_5_3_32
      cd CMSSW_5_3_32/src
      eval `scramv1 runtime -sh`
      cp -r ../../../../code/HiggsExample20112012 .
      cd HiggsExample20112012/HiggsDemoAnalyzer
      scram b
      cd ../Level3
      mkdir -p ../../../../results
      cmsRun demoanalyzer_cfg_level3MC.py
