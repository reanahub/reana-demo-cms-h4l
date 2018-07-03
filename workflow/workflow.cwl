#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow

inputs:
  BuildFile: File
  HiggsDemoAnalyzerGit: File
  Cert_190456-208686_8TeV_22Jan2013ReReco_Collisions12_JSON: File
  demoanalyzer_cfg_level3MC: File
  demoanalyzer_cfg_level3data: File
  M4Lnormdatall_lvl3: File

outputs:
  output_txt:
    type: File
#     outputSource:
#       fitdata/result


steps:
  step1:
    run: step1.cwl
    in:
      BuildFile: BuildFile
      HiggsDemoAnalyzerGit: HiggsDemoAnalyzerGit
  #     events: events
    out: [output_txt]
  # fitdata:
  #   run: fitdata.cwl
  #   in:
  #     fitdata: fitdata_tool
  #     data: gendata/data
  #   out: [result]