cwlVersion: v1.0
class: CommandLineTool

baseCommand: /bin/zsh

requirements:
  DockerRequirement:
    dockerPull:
      clelange/cmssw:5_3_32
  InitialWorkDirRequirement:
    listing:
      - $(inputs.code)
      - $(inputs.inputs)

inputs:
  inputs:
    type: Directory
  code:
    type: Directory

stdout: step1mc.log

outputs:
  step1mc.log:
    type: stdout
  Higgs4L1file.root:
    type: File
    outputBinding:
       glob: "outputs/Higgs4L1file.root"

arguments:
  - prefix: -c
    valueFrom: |
      source /opt/cms/cmsset_default.sh; \
      scramv1 project CMSSW CMSSW_5_3_32; \
      cd CMSSW_5_3_32/src; \
      eval `scramv1 runtime -sh`; \
      cd ../..; \
      cp -r ../../code/HiggsExample20112012 .; \
      scram b; \
      cd HiggsExample20112012/Level3; \
      mkdir -p ../../../../outputs; \
      cmsRun demoanalyzer_cfg_level3MC.py
