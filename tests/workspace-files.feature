# Tests for the presence of files in the workspace

Feature: Workspace files

    As a researcher,
    I want to make sure that my Snakemake workflow produces expected files,
    and that the files fetched from the remote locations are not corrupted,
    so that I can be sure that the workflow outputs are correct.

    Scenario: The workspace contains all the relevant input files
        When the workflow execution completes
        Then the workspace should contain "data/DoubleE11.root"
        And the workspace should include "data/DoubleE12.root"
        And the workspace should include "data/DoubleMu11.root"
        And the workspace should include "data/DoubleMu12.root"
        And the workspace should include "data/DY1011.root"
        And the workspace should include "data/DY1012.root"
        And the workspace should include "data/DY101Jets12.root"
        And the workspace should include "data/DY50Mag12.root"
        And the workspace should include "data/DY50TuneZ11.root"
        And the workspace should include "data/DY50TuneZ12.root"
        And the workspace should include "data/DYTo2mu12.root"
        And the workspace should include "data/HZZ11.root"
        And the workspace should include "data/HZZ12.root"
        And the workspace should include "data/TTBar11.root"
        And the workspace should include "data/TTBar12.root"
        And the workspace should include "data/TTJets11.root"
        And the workspace should include "data/TTJets12.root"
        And the workspace should include "data/ZZ2mu2e11.root"
        And the workspace should include "data/ZZ2mu2e12.root"
        And the workspace should include "data/ZZ4e11.root"
        And the workspace should include "data/ZZ4e12.root"
        And the workspace should include "data/ZZ4mu11.root"
        And the workspace should include "data/ZZ4mu12.root"


    Rule: The output files and reports are generated correctly

        Scenario: The analysis of the real data set produces the expected file
            When the workflow is finished
            Then the workspace should contain "results/Higgs4L1file.root"
            And the size of the file "results/Higgs4L1file.root" should be exactly 59770

        Scenario: The analysis of the simulated data set produces the expected file
            When the workflow is finished
            Then the workspace should contain "results/DoubleMuParked2012C_10000_Higgs.root"
            And the size of the file "results/DoubleMuParked2012C_10000_Higgs.root" should be exactly 54181

        Scenario: The Higgs signal plot is correctly generated
            When the workflow is finished
            Then the workspace should contain "results/mass4l_combine_userlvl3.pdf"
            And all the outputs should be included in the workspace

        Scenario: The Snakemake report is correctly generated
            When the workflow is finished
            Then the workspace should contain "report.html"
