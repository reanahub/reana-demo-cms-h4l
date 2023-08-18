# Tests for the workflow execution duration time

Feature: Run duration

    As a researcher,
    I want to verify that my workflow finishes in a reasonable amount of time,
    so that I can stay assured that there are no unusual problems with computing resources.

    Scenario: The workflow terminates in a reasonable amount of time
        When the workflow execution completes
        Then the workflow run duration should be less than 25 minutes

    Scenario: The SCRAM step terminates in a reasonable amount of time
        When the workflow execution completes
        Then the duration of the step "scram" should be less than 5 minutes

    Scenario: The analysis of the real collision data is performed in a reasonable amount of time
        When the workflow execution completes
        Then the duration of the step "analyze_data" should be less than 15 minutes

    Scenario: The analysis of the simulated collision data is performed in a reasonable amount of time
        When the workflow execution completes
        Then the duration of the step "analyze_mc" should be less than 15 minutes

    Scenario: The generation of the Higgs signal plot terminates in a reasonable amount of time
        When the workflow execution completes
        Then the duration of the step "make_plot" should be less than 5 minutes
