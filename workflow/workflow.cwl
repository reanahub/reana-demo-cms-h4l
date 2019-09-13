#!/usr/bin/env cwl-runner

# Note that if you are working on the analysis development locally, i.e. outside
# of the REANA platform, you can proceed as follows:
#
#   $ cd reana-demo-cms-h4l
#   $ mkdir cwl-local-run
#   $ cd cwl-local-run
#   $ cp -a ../code ../data ../workflow/input.yaml .
#   $ cwltool --quiet --outdir="../results" ../workflow/workflow.cwl input.yaml
#   $ firefox ../results/plot.png


cwlVersion: v1.0
class: Workflow

requirements:
  InitialWorkDirRequirement:
    listing:
      - $(inputs.code)
      - $(inputs.data)

inputs:
  data:
    type: Directory
  code:
    type: Directory

outputs:
  mass4l_combine_userlvl3.pdf:
    type: File
    outputSource:
      make_plot/mass4l_combine_userlvl3.pdf

steps:
  analyse_data:
    run: analyse_data.cwl
    in:
      code: code
      data: data
    out: [DoubleMuParked2012C_10000_Higgs.root, analyse_data.log]
  analyse_mc:
    run: analyse_mc.cwl
    in:
      code: code
      data: data
    out: [Higgs4L1file.root, analyse_mc.log]
  make_plot:
    run: make_plot.cwl
    in:
      code: code
      data: data
      DoubleMuParked2012C_10000_Higgs: analyse_data/DoubleMuParked2012C_10000_Higgs.root
      Higgs4L1file: analyse_mc/Higgs4L1file.root
    out: [mass4l_combine_userlvl3.pdf, make_plot.log]