# Tests for the expected workflow log messages

Feature: Log messages

    As a researcher,
    I want to be able to see the log messages of my workflow execution,
    So that I can verify that the workflow ran correctly.

    Scenario: The workflow start has produced the expected messages
        When the workflow is finished
        Then the engine logs should contain "snakemake.logging | MainThread | WARNING | Building DAG of jobs..."

    Scenario: The SCRAM step has produced the expected messages
        When the workflow is finished
        Then the engine logs should contain "reana-workflow-engine-snakemake | MainThread | INFO | Job 'scram' received"
        And the job logs for the "scram" step should contain
            """
            Registered EDM Plugin: HiggsExample20112012HiggsDemoAnalyzer
            """
        And the job logs for the "scram" step should contain
            """
            >> Done generating edm plugin poisoned information
            """
        And the engine logs should contain
            """
            reana-workflow-engine-snakemake | MainThread | INFO | scram job is finished
            """

    Scenario: The data analysis step has produced the expected messages
        When the workflow is finished
        Then the engine logs should contain
            """
            reana-workflow-engine-snakemake | MainThread | INFO | Job 'analyze_data' received
            """
        And the job logs for the "analyze_data" step should contain
            """
            Successfully opened file root://eospublic.cern.ch//eos/opendata/cms/Run2012C/DoubleMuParked/AOD/22Jan2013-v1/10000/F2878994-766C-E211-8693-E0CB4EA0A939.root
            """
        And the job logs for the "analyze_data" step should contain
            """
            TrigReport ---------- Event  Summary ------------
            TrigReport Events total = 9058 passed = 9058 failed = 0

            TrigReport ---------- Path   Summary ------------
            TrigReport  Trig Bit#        Run     Passed     Failed      Error Name
            TrigReport     1    0       9058       9058          0          0 p
            """
        And the engine logs should contain "reana-workflow-engine-snakemake | MainThread | INFO | analyze_data job is finished"

    Scenario: The montecarlo analysis step has produced the expected messages
        When the workflow is finished
        Then the engine logs should contain "reana-workflow-engine-snakemake | MainThread | INFO | Job 'analyze_mc' received"
        And the job logs for the "analyze_mc" step should contain
            """
            Successfully opened file root://eospublic.cern.ch//eos/opendata/cms/MonteCarlo2012/Summer12_DR53X/SMHiggsToZZTo4L_M-125_8TeV-powheg15-JHUgenV3-pythia6/AODSIM/PU_S10_START53_V19-v1/10000/029D759D-6CD9-E211-B3E2-1CC1DE041FD8.root
            """
        And the job logs for the "analyze_mc" step should contain
            """
            TrigReport ---------- Event  Summary ------------
            TrigReport Events total = 7499 passed = 7499 failed = 0

            TrigReport ---------- Path   Summary ------------
            TrigReport  Trig Bit#        Run     Passed     Failed      Error Name
            TrigReport     1    0       7499       7499          0          0 p
            """
        And the engine logs should contain "reana-workflow-engine-snakemake | MainThread | INFO | analyze_mc job is finished"

    Scenario: The data plotting step has produced the expected messages
        When the workflow is finished
        Then the engine logs should contain
            """
            reana-workflow-engine-snakemake | MainThread | INFO | Job 'make_plot' received
            """
        And the job logs for the "make_plot" step should contain
            """
            pdf file ../../../../results/mass4l_combine_userlvl3.pdf has been created
            """
        And the engine logs should contain "reana-workflow-engine-snakemake | MainThread | INFO | make_plot job is finished"

    Scenario: The workflow completion has produced the expected messages
        When the workflow is finished
        Then the engine logs should contain "snakemake.logging | MainThread | INFO | 5 of 5 steps (100%) done"
