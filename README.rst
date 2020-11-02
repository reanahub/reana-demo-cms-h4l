===========================================
 REANA example - CMS Higgs-to-four-leptons
===========================================

.. image:: https://github.com/reanahub/reana-demo-cms-h4l/workflows/CI/badge.svg
   :target: https://github.com/reanahub/reana-demo-cms-h4l/actions

.. image:: https://badges.gitter.im/Join%20Chat.svg
   :target: https://gitter.im/reanahub/reana?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge

.. image:: https://img.shields.io/badge/license-MIT-blue.svg
   :target: https://github.com/reanahub/reana-demo-cms-h4l/blob/master/LICENSE

About
=====

This `REANA <http://www.reana.io/>`_ reproducible analysis example studies the
Higgs-to-four-lepton decay channel that led to the Higgs boson experimental
discovery in 2012. The example uses CMS open data released in 2011 and
2012. "This research level example is a strongly simplified reimplementation of
parts of the original CMS Higgs to four lepton analysis published in Phys.Lett.
B716 (2012) 30-61, arXiv:1207.7235." (See Ref. `1 <http://opendata.web.cern.ch/record/5500>`_).

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

- the list of CMS validated runs included in the ``data`` directory:

  - ``Cert_190456-208686_8TeV_22Jan2013ReReco_Collisions12_JSON.txt``

- a set of data files in the `ROOT <https://root.cern.ch/>`_ format, processed
  from CMS public datasets, included in the ``data`` directory:

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

"The example uses legacy versions of the original CMS data sets in the CMS AOD,
which slightly differ from the ones used for the publication due to improved
calibrations. It also uses legacy versions of the corresponding Monte Carlo
simulations, which are again close to, but not identical to, the ones in the
original publication. These legacy data and MC sets listed below were used in
practice, exactly as they are, in many later CMS publications.

Since according to the CMS Open Data policy the fraction of data which are
public (and used here) is only 50% of the available LHC Run I samples, the
statistical significance is reduced with respect to what can be achieved with
the full dataset. However, the original paper Phys.Lett. B716 (2012) 30-61,
arXiv:1207.7235, was also obtained with only part of the Run I statistics,
roughly equivalent to the luminosity of the public sets, but with only partial
statistical overlap."(See Ref. `1 <http://opendata.web.cern.ch/record/5500>`_).

2. Analysis code
----------------

The analysis will consist of two stages. In the first stage, we shall process
the original collision data (using `demoanalyzer_cfg_level3data.py <https://github.com/reanahub/reana-demo-cms-h4l/blob/master/code/HiggsExample20112012/Level3/demoanalyzer_cfg_level3data.py>`_
) and simulated data (using `demoanalyzer_cfg_level3MC.py <https://github.com/reanahub/reana-demo-cms-h4l/blob/master/code/HiggsExample20112012/Level3/demoanalyzer_cfg_level3MC.py>`_
) for one Higgs signal candidate with with reduced statistics. In the second
stage, we shall plot the results (using `M4Lnormdatall_lvl3.cc <https://github.com/reanahub/reana-demo-cms-h4l/blob/master/code/HiggsExample20112012/Level3/M4Lnormdatall_lvl3.cc>`_
). The ``HiggsDemoAnalyzer`` directory contains the analysis code plugin for
the `CMSSW <http://cms-sw.github.io/>`_ analysis framework.

"The provided analysis code recodes the spirit of the original analysis and
recodes many of the original cuts on original data objects, but does not
provide the original analysis code itself. Also, for the sake of simplicity, it
skips some of the more advanced analysis methods of the original paper.
Nevertheless, it provides a qualitative insight about how the original result
was obtained. In addition to the documented core results, the resulting root
files also contain many undocumented plots which grew as a side product from
setting up this example and earlier examples. The significance of the Higgs
'excess' is about 2 standard deviations in this example, while it was 3.2
standard deviations in this channel alone in the original publication. The
difference is attributed to the less sophisticated background suppression. In
more recent (not yet public) CMS data sets with higher statistics the signal is
observed in a preliminary analysis with more than 5 standard deviations in this
channel alone CMS-PAS-HIG-16-041.

The analysis strategy is the following: Get the 4mu and 2mu2e final states from
the DoubleMuParked datasets and the 4e final state from the DoubleElectron
dataset. This avoids double counting due to trigger overlaps. All MC
contributions except top use data-driven normalization: The DY (Z/gamma^*)
contribution is scaled to the Z peak. The ZZ contribution is scaled to describe
the data in the independent mass range 180-600 GeV. The Higgs contribution is
scaled to describe the data in the signal region. The (very small) top
contribution remains scaled to the MC generator cross section."
(See Ref. `1 <http://opendata.web.cern.ch/record/5500>`_).

3. Compute environment
----------------------

In order to be able to rerun the analysis even several years in the future, we
need to "encapsulate the current compute environment", for example to freeze the
software package versions our analysis is using. We shall achieve this by
preparing a `Docker <https://www.docker.com/>`_ container image for our analysis
steps.

This analysis example runs within the `CMSSW <http://cms-sw.github.io/>`_
analysis framework that was packaged for Docker in `cmsopendata/cmssw_5_3_32
<https://hub.docker.com/r/cmsopendata/cmssw_5_3_32/>`_.

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

There is a serial workflow that does the steps sequentially, but this demo
represents a better use case for workflow tools capable of parallel execution.

We shall use the `CWL <http://www.commonwl.org/v1.0/>`_ workflow specification
to express the computational workflow:

- `workflow definition <workflow/workflow.cwl>`_

and its individual steps:

- `process collision data <workflow/analyse_data.cwl>`_
- `process simulated data <workflow/analyse_mc.cwl>`_
- `produce final plot <workflow/make_plot.cwl>`_


5. Output results
-----------------


The example produces a plot showing the now legendary Higgs signal:

.. figure:: https://raw.githubusercontent.com/reanahub/reana-demo-cms-h4l/master/docs/mass4l_combine_userlvl3.png
   :alt: mass4l_combine_userlvl3.png
   :align: center

The published reference plot which is being approximated in this example is
https://inspirehep.net/record/1124338/files/H4l_mass_3.png. Other Higgs final
states (e.g. Higgs to two photons), which were also part of the same CMS paper
and strongly contributed to the Higgs boson discovery, are not covered by this
example.

Running the example on REANA cloud
==================================

We start by creating a `reana.yaml <reana.yaml>`_ file describing the above
analysis structure with its inputs, code, runtime environment, computational
workflow steps and expected outputs. In this example we are using the CWL
workflow specification, with its steps in the `workflow <workflow>`_ directory.

At the same time, for easy debugging purposes (to avoid the *cwl* overhead), we
have setup also a serial workflow as follows:

.. code-block:: yaml

    version: 0.6.0
    inputs:
      files:
        - inputs
        - code

    workflow:
      type: serial
      specification:
        steps:
          - name: analyse_data
            environment: 'cmsopendata/cmssw_5_3_32'
            commands:
              - >
                  source /opt/cms/cmsset_default.sh
                  && scramv1 project CMSSW CMSSW_5_3_32
                  && cd CMSSW_5_3_32/src
                  && eval `scramv1 runtime -sh`
                  && cp -r ../../code/HiggsExample20112012 .
                  && cd HiggsExample20112012/HiggsDemoAnalyzer
                  && scram b
                  && cd ../Level3
                  && mkdir -p ../../../../results
                  && cmsRun demoanalyzer_cfg_level3data.py
                  && cmsRun demoanalyzer_cfg_level3MC.py
                  && root -b -l -q ./M4Lnormdatall_lvl3.cc

    outputs:
      files:
        - results/mass4l_combine_userlvl3.pdf



We can now install the REANA command-line client, run the analysis and download
the resulting plots:

.. code-block:: console

    $ # create new virtual environment
    $ virtualenv ~/.virtualenvs/myreana
    $ source ~/.virtualenvs/myreana/bin/activate
    $ # install REANA client
    $ pip install reana-client
    $ # connect to some REANA cloud instance
    $ export REANA_SERVER_URL=https://reana.cern.ch/
    $ export REANA_ACCESS_TOKEN=XXXXXXX
    $ # create new workflow
    $ reana-client create -n my-analysis
    $ export REANA_WORKON=my-analysis
    $ # upload input code and data to the workspace
    $ reana-client upload
    $ # start computational workflow
    $ reana-client start
    $ # ... should be finished in a couple (~5) of minutes
    $ reana-client status
    $ # list workspace files
    $ reana-client list
    $ # download output results
    $ reana-client download

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
- `Daniel Prelipcean <https://orcid.org/0000-0002-4855-194X>`_
- `Diyaselis Delgado Lopez <https://orcid.org/0000-0001-9643-9322>`_
- `Tibor Simko <https://orcid.org/0000-0001-7202-5803>`_
