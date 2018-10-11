===========================================
 REANA example - CMS Higgs-to-four-leptons
===========================================

.. image:: https://badges.gitter.im/Join%20Chat.svg
   :target: https://gitter.im/reanahub/reana?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge

.. image:: https://img.shields.io/badge/license-MIT-blue.svg
   :target: https://github.com/reanahub/reana-demo-cms-h4l/blob/master/LICENSE

About
=====

This `REANA <http://www.reana.io/>`_ reproducible analysis example studies the
Higgs-to-four-lepton decay channel that led to the Higgs boson experimental
discovery in 2012. The example uses CMS open data released in 2011 and
2012.

Analysis structure
==================

Making a research data analysis reproducible basically means to provide
"runnable recipes" addressing (1) where is the input data, (2) what software was
used to analyse the data, (3) which computing environments were used to run the
software and (4) which computational workflow steps were taken to run the
analysis. This will permit to instantiate the analysis on the computational
cloud and run the analysis to obtain (5) output results.


1. Input data
-------------

The analysis takes the following inputs:

- the list of CMS validated runs included in the ``inputs`` directory:

  - ``Cert_190456-208686_8TeV_22Jan2013ReReco_Collisions12_JSON.txt``

- a set of data files in the `ROOT <https://root.cern.ch/>`_ format, processed
  from CMS public datasets, included in the ``inputs`` directory:

  - ``DoubleE11.root``
  - ``DoubleE12.root``
  - ``DoubleMu11.root``
  - ``DoubleMu12.root``
  - ``DY1011.root``
  - ``DY1012.root``
  - ``DY101Jets12.root``
  - ``DY50Mag12.root``
  - ``DY50TuneZ11.root``
  - ``DY50TuneZ12.root``
  - ``DYTo2mu12.root``
  - ``HZZ11.root``
  - ``HZZ12.root``
  - ``TTBar11.root``
  - ``TTBar12.root``
  - ``TTJets11.root``
  - ``TTJets12.root``
  - ``ZZ2mu2e11.root``
  - ``ZZ2mu2e12.root``
  - ``ZZ4e11.root``
  - ``ZZ4e12.root``
  - ``ZZ4mu11.root``
  - ``ZZ4mu12.root``

- CMS collision data from 2011 and 2012 accessed "live" during analysis via
  `CERN Open Data <http://opendata.cern.ch/>`_ portal:

  - `/DoubleMuParked/Run2012C-22Jan2013-v1/AOD <http://opendata.cern.ch/record/6030>`_

- CMS simulated data from 2011 and 2012 accessed "live" during analysis via
  `CERN Open Data <http://opendata.cern.ch/>`_ portal:

  - `/SMHiggsToZZTo4L_M-125_8TeV-powheg15-JHUgenV3-pythia6/Summer12_DR53X-PU_S10_START53_V19-v1/AODSIM <http://opendata.cern.ch/record/9356>`_

2. Analysis code
----------------

The analysis will consist of two stages. In the first stage, we shall process
the original collision data (using ``demoanalyzer_cfg_level3data.py``) and
simulated data (using ``demoanalyzer_cfg_level3MC.py``) for one Higgs signal
candidate with with reduced statistics. In the second stage, we shall plot the
results (using ``M4Lnormdatall_lvl3.cc``). The ``HiggsDemoAnalyzer`` directory
contains the analysis code plugin for the `CMSSW <http://cms-sw.github.io/>`_
analysis framework.

3. Compute environment
----------------------

In order to be able to rerun the analysis even several years in the future, we
need to "encapsulate the current compute environment", for example to freeze the
software package versions our analysis is using. We shall achieve this by
preparing a `Docker <https://www.docker.com/>`_ container image for our analysis
steps.

This analysis example runs within the `CMSSW <http://cms-sw.github.io/>`_
analysis framework that was packaged for Docker in `clelange/cmssw
<https://hub.docker.com/r/clelange/cmssw/>`_.

4. Analysis workflow
--------------------

The analysis workflow is simple and consists of two above-mentioned stages:

.. code-block:: console

                              START
                             /     \
                            /       \
                           /         \
   +-------------------------+     +------------------------+
   | process collision data  |     | process simulated data |
   +-------------------------+     +------------------------+
                   \                       /
                    \ Higgs4L1file.root   / DoubleMuParked2012C_10000_Higgs.root
                     \                   /
                  +-------------------------+
                  |    produce final plot   |
                  +-------------------------+
                             |
                             | mass4l_combine_userlvl3.pdf
                             V
                            STOP

We shall use the `CWL <http://www.commonwl.org/v1.0/>`_ workflow specification
to express the computational workflow:

- `workflow definition <workflow/workflow.cwl>`_

and its individual steps:

- `process collision data <workflow/step1data.cwl>`_
- `process simulated data <workflow/step1mc.cwl>`_
- `produce final plot <workflow/step2.cwl>`_

5. Output results
-----------------

The example produces a plot showing the Higgs signal:

.. figure:: https://raw.githubusercontent.com/reanahub/reana-demo-cms-h4l/master/docs/mass4l_combine_userlvl3.png
   :alt: mass4l_combine_userlvl3.png
   :align: center

Local testing
=============

*Optional*

If you would like to test the analysis locally (i.e. outside of the REANA
platform), you can proceed as follows.

Using pure Docker:

.. code-block:: console

    $ docker run -i -t --rm \
           -v `pwd`/inputs:/inputs \
           -v `pwd`/code:/code \
           -v `pwd`/outputs:/outputs \
           clelange/cmssw:5_3_32 \
       /bin/bash -c 'cp -r /code/HiggsExample20112012 .; \
                     scram b; \
                     cd /code/HiggsExample20112012/Level3; \
                     cmsRun ./demoanalyzer_cfg_level3data.py'

    $ docker run -i -t --rm \
           -v `pwd`/inputs:/inputs \
           -v `pwd`/code:/code \
           -v `pwd`/outputs:/outputs \
           clelange/cmssw:5_3_32 \
       /bin/bash -c 'cp -r /code/HiggsExample20112012 .; \
                     scram b; \
                     cd /code/HiggsExample20112012/Level3; \
                     cmsRun demoanalyzer_cfg_level3MC.py'

    $ docker run -i -t --rm \
           -v `pwd`/inputs:/inputs \
           -v `pwd`/code:/code \
           -v `pwd`/outputs:/outputs \
           clelange/cmssw:5_3_32 \
       /bin/bash -c 'cd /code/HiggsExample20112012/Level3; \
                     root -b -l -q ./M4Lnormdatall_lvl3.cc'

Using CWL:

.. code-block:: console

    $ cwltool --outdir=./outputs ./workflow/workflow.cwl ./workflow/input.yaml

Running the example on REANA cloud
==================================

We start by creating a `reana.yaml <reana.yaml>`_ file describing the above analysis structure with its inputs, code, runtime environment, computational workflow steps and expected outputs:

.. code-block:: yaml
   
    version: 0.3.0
    inputs: 
      files:
      - code/HiggsExample20112012/HiggsDemoAnalyzer/src/HiggsDemoAnalyzerGit.cc
      - code/HiggsExample20112012/Level3/demoanalyzer_cfg_level3data.py
      - code/HiggsExample20112012/Level3/demoanalyzer_cfg_level3MC.py 
      - code/HiggsExample20112012/Level3/M4Lnormdatall_lvl3.cc 
      parameters:
         input: workflow/input.yaml
    workflow:
      type: cwl
      file: workflow/workflow.cwl
    environments:
      - type: docker
      image: clelange/cmssw:5_3_32
    outputs:
      files:
       - results/mass4l_combine_userlvl3.pdf

We can now install the REANA command-line client, run the analysis and download the resulting plots:

.. code-block:: console

    $ # install REANA client:
    $ mkvirtualenv reana-client
    $ pip install reana-client
    $ # connect to some REANA cloud instance:
    $ export REANA_SERVER_URL=https://reana.cern.ch/
    $ export REANA_ACCESS_TOKEN=XXXXXXX
    $ # create new workflow:
    $ reana-client create -n my-analysis
    $ export REANA_WORKON=my-analysis
    $ # upload input code and data to the workspace:
    $ reana-client upload ./code ./data
    $ # start computational workflow:
    $ reana-client start
    $ # ... should be finished in about a minute:
    $ reana-client status
    $ # list workspace files:
    $ reana-client list
    $ # download output results:
    $ reana-client download results/mass4l_combine_userlvl3.pdf

Please see the `REANA-Client <https://reana-client.readthedocs.io/>`_
documentation for more detailed explanation of typical ``reana-client`` usage
scenarios.
    
Contributors
============

This example is based on the `original open data analysis
<http://opendata.cern.ch/record/5500>`_ by Jomhari, Nur Zulaiha; Geiser, Achim;
Bin Anuar, Afiq Aizuddin, "Higgs-to-four-lepton analysis example using 2011-2012
data", CERN Open Data Portal, 2017. DOI: `10.7483/OPENDATA.CMS.JKB8.RR42
<https://doi.org/10.7483/OPENDATA.CMS.JKB8.RR42>`_

The list of contributors to this REANA example in alphabetical order:


- `Clemens Lange <https://orcid.org/0000-0002-3632-3157>`_
- `Diyaselis Delgado Lopez <https://orcid.org/0000-0002-4306-8828>`_
- `Tibor Simko <https://orcid.org/0000-0001-7202-5803>`_
