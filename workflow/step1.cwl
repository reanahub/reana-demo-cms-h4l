cwlVersion: v1.0
class: CommandLineTool

requirements:
  DockerRequirement:
    dockerPull:
      clelange/cmssw:5_3_32
  InitialWorkDirRequirement:
    listing:
      - $(inputs.BuildFile)
      - $(inputs.HiggsDemoAnalyzerGit)

inputs:
  BuildFile: File
  HiggsDemoAnalyzerGit: File
  # outfile:
    # type: stdout
  #   default: plot.png

baseCommand: /bin/zsh
stdout: output_txt

outputs:
  output_txt:
    type: stdout

arguments:
  - prefix: -c
    valueFrom: |
      echo "::: Setting up CMS environment...";
      source /opt/cms/cmsset_default.sh;
      echo "::: Setting up CMS environment... [done]";
      scramv1 project CMSSW_5_3_32;
      cd CMSSW_5_3_32/src || exit;
      eval `scramv1 runtime -sh`;
      ls;
      # git clone git://github.com/cms-opendata-analyses/HiggsExample20112012.git || exit
      # scram b || exit
      # cd HiggsExample20112012/Level3 || exit
      # cmsRun {{inputs.parameters.command}} || exit
      # cp *.root /mnt/vol
      # ls -l /mnt/vol

# outputs:
#   result:
#     type: File
#     outputBinding:
#       glob: $(inputs.outfile)