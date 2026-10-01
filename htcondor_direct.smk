# Variant B: drive HTCondor straight from Snakemake's own
# snakemake-executor-plugin-htcondor, with no REANA involved at all --
# https://snakemake.github.io/snakemake-plugin-catalog/plugins/executor/htcondor.html
#
# This exists to check whether REANA's two htcondorcern bugs on this server
# (see LEVEL4.md, "Later: analyze_chunk on HTCondor") are REANA-side or
# CERN-pool-side: this plugin submits its own job wrapper and container
# invocation, independent of reana-job-controller, so it may simply not hit
# them. It is UNVERIFIED -- run smoke first. See HTCONDOR_DIRECT.md for setup,
# invocation and how to check that a job actually ran.
#
# Run from the repository root:
#   snakemake -s htcondor_direct.smk --workflow-profile workflow/profiles/htcondor-direct \
#       --jobs 1 -p smoke
#   snakemake -s htcondor_direct.smk --workflow-profile workflow/profiles/htcondor-direct \
#       --jobs 1 -p pilot
#
# `pilot` mirrors reana_htcondor_pilot.yaml: the same CMSSW steps as a real
# analyze_chunk job, over the single AOD file listed in
# workflow/calibration_file.txt, so problems surface in minutes, not after a
# 4h chunk.

JSON_2011 = "Cert_160404-180252_7TeV_ReRecoNov08_Collisions11_JSON.txt"
JSON_2012 = "Cert_190456-208686_8TeV_22Jan2013ReReco_Collisions12_JSON.txt"

# Unpacked on CVMFS, so it is identical on lxplus and on every execution
# node and never has to be pulled or transferred.
CMSSW_IMAGE = (
    "/cvmfs/unpacked.cern.ch/registry.hub.docker.com"
    "/cmsopendata/cmssw_5_3_32:latest"
)


rule all:
    input:
        "htcondor_direct_pilot_timing.txt",


rule smoke:
    # No container, no CMSSW -- just: does condor_submit from lxplus via this
    # plugin reach an execution point at all, and does it have CVMFS and
    # apptainer/singularity (both required by `pilot`)?
    #
    # The output deliberately sits at the top level rather than in results/.
    # HTCondor runs the job in a scratch directory on the execution point and
    # transfers back new files from the *top level* of it; a file written into
    # a subdirectory is silently left behind, which is what the first
    # successful run of this rule did -- "Job was successful" followed by
    # "missing locally". Outputs in subdirectories need --shared-fs-usage
    # none; see HTCONDOR_DIRECT.md.
    output:
        "htcondor_direct_smoke.txt",
    threads: 1
    resources:
        htcondor_request_mem_mb=512,
        htcondor_request_disk_mb=1024,
    shell:
        "{{ hostname; date; id; echo PWD=$(pwd); "
        "echo '--- cvmfs ---'; ls /cvmfs/ 2>&1 || echo 'no /cvmfs'; "
        "echo '--- apptainer/singularity ---'; "
        "(command -v apptainer || command -v singularity) 2>&1 || echo 'neither found'; "
        "echo '--- afs ---'; ls /afs/cern.ch/user/ 2>&1 | head -3 || echo 'no /afs'; "
        "}} > htcondor_direct_smoke.txt"


rule smoke_subdir:
    # Does an output in a *subdirectory* come back? The plugin is supposed to
    # arrange that with transfer_output_remaps under shared-fs-usage none, but
    # `smoke` only ever proved it for a top-level file, and every chunk of the
    # real workflow writes to results/chunks/<dataset>/<chunk>.root.
    #
    # Worth its own two-minute job: the alternative is discovering the answer
    # four hours into a real chunk.
    output:
        "results/smoke_subdir/htcondor_direct_subdir.txt",
    threads: 1
    resources:
        htcondor_request_mem_mb=512,
        htcondor_request_disk_mb=1024,
    shell:
        "mkdir -p results/smoke_subdir "
        "&& {{ hostname; date; echo PWD=$(pwd); "
        "echo 'wrote {output}'; }} > {output}"


rule pilot:
    # Every path here goes through {input.*} / {output}, never an absolute one
    # baked in at parse time. With shared-fs-usage none the plugin transfers
    # these into the job's scratch directory and transfers the output back, so
    # the names Snakemake hands the shell are the ones that resolve there.
    input:
        smoke="htcondor_direct_smoke.txt",
        data="data",
        code="code",
        calibration_file="workflow/calibration_file.txt",
    output:
        "htcondor_direct_pilot_timing.txt",
    threads: 1
    container:
        CMSSW_IMAGE
    resources:
        htcondor_request_mem_mb=8192,
        htcondor_request_disk_mb=16384,
    shell:
        # set +u first, and not optionally: Snakemake runs every shell command
        # under `set -euo pipefail`, and CMSSW's /opt/cms/cmsset_default.sh
        # reads CMS_PATH at line 33 before assigning it. Harmless in an
        # ordinary shell, fatal under nounset -- "CMS_PATH: unbound variable",
        # exit 127, before any of the analysis runs. REANA never hit this
        # because its job wrapper doesn't set -u.
        "set +u "
        # WORKDIR pins the directory Snakemake started in, because the build
        # below cds several levels deep and {input.*} / {output} are relative
        # to where it began.
        "&& WORKDIR=$(pwd) "
        "&& mkdir -p work_htcondor_direct_pilot "
        "&& cd work_htcondor_direct_pilot "
        "&& source /opt/cms/cmsset_default.sh "
        "&& scramv1 project CMSSW CMSSW_5_3_32 "
        "&& cd CMSSW_5_3_32/src "
        "&& eval `scramv1 runtime -sh` "
        "&& cp -r $WORKDIR/{input.code}/HiggsExample20112012 . "
        "&& cd HiggsExample20112012/HiggsDemoAnalyzer "
        "&& scram b "
        "&& cd ../Level4 "
        "&& cp $WORKDIR/{input.calibration_file} this_chunk_index.txt "
        "&& sed "
        "-e 's|/home/cms-opendata/CMSSW_5_3_32/src/Demo/DemoAnalyzer/datasets/CMS_Run2012C_DoubleMuParked_AOD_22Jan2013-v1_10000_file_index.txt|this_chunk_index.txt|' "
        "-e \"s|/home/cms-opendata/CMSSW_5_3_32/src/Demo/DemoAnalyzer/datasets/Cert_190456-208686_8TeV_22Jan2013ReReco_Collisions12_JSON.txt|$WORKDIR/{input.data}/Cert_190456-208686_8TeV_22Jan2013ReReco_Collisions12_JSON.txt|\" "
        "-e \"s|'HiggsDemoAnalyzer'|'HiggsDemoAnalyzerGit'|\" "
        "demoanalyzer_cfg_level4data.py > demoanalyzer_cfg_pilot.py "
        "&& START=$(date +%s) "
        "&& cmsRun demoanalyzer_cfg_pilot.py "
        "&& END=$(date +%s) "
        '&& echo "DURATION_SECONDS=$((END-START))" | tee $WORKDIR/{output}'


# ---------------------------------------------------------------------------
# The real Level 4 workflow on HTCondor, without REANA.
#
# Same analysis as workflow/Snakefile.level4 (variant A, the validated REANA path),
# but with the 43 analyze_chunk jobs going to the CERN pool through this
# plugin. That file is left alone on purpose: it produced the result we
# checked against the reference plot, and it should stay reproducible.
#
# Run it with the `level4` target -- `rule all` above stays pointed at the
# pilot, so a bare `snakemake` can't start a two-day run by accident:
#
#   snakemake -s htcondor_direct.smk \
#     --workflow-profile workflow/profiles/htcondor-direct --jobs 20 level4
#
# Read the "Full run" section of HTCONDOR_DIRECT.md before starting one.

import os

CHUNK_LISTS = os.path.join(workflow.basedir, "workflow", "chunk_lists")

# Derived from the chunk list files rather than hard-coded. workflow/Snakefile.level4
# spells these out because reana-client serialises each rule to JSON and
# chokes on anything dynamic; nothing here goes through REANA, so the
# filesystem can be the source of truth.
CHUNKS = {
    dataset: sorted(
        name[: -len(".txt")]
        for name in os.listdir(os.path.join(CHUNK_LISTS, dataset))
        if name.endswith(".txt")
    )
    for dataset in sorted(os.listdir(CHUNK_LISTS))
}

JSON_BY_DATASET = {
    "DoubleMu_Run2011A": JSON_2011,
    "DoubleElectron_Run2011A": JSON_2011,
    "DoubleMuParked_Run2012B": JSON_2012,
    "DoubleMuParked_Run2012C": JSON_2012,
    "DoubleElectron_Run2012B": JSON_2012,
    "DoubleElectron_Run2012C": JSON_2012,
}

ALL_CHUNK_ROOTS = [
    f"results/chunks/{dataset}/{chunk_id}.root"
    for dataset, chunk_ids in CHUNKS.items()
    for chunk_id in chunk_ids
]

# Everything except analyze_chunk runs on lxplus: seconds of work each, and
# they share the CMSSW build area in the working directory, which would have
# to be shipped to a node otherwise. lxplus has apptainer and CVMFS, so the
# container directive still applies to them.
localrules:
    level4,
    scram,
    stage_chunk,
    merge_dataset,
    combine_2012_muon,
    combine_2012_electron,
    make_plot,


rule level4:
    input:
        "results/mass4l_combine_user.pdf",


rule scram:
    input:
        data="data",
        code="code",
    output:
        touch("results/scramdone.txt"),
        directory("CMSSW_5_3_32"),
    container:
        CMSSW_IMAGE
    shell:
        "set +u "
        "&& source /opt/cms/cmsset_default.sh "
        "&& scramv1 project CMSSW CMSSW_5_3_32 "
        "&& cd CMSSW_5_3_32/src "
        "&& eval `scramv1 runtime -sh` "
        "&& cp -r ../../{input.code}/HiggsExample20112012 . "
        "&& cd HiggsExample20112012/HiggsDemoAnalyzer "
        "&& scram b "
        "&& mkdir -p ../../../../results"


rule analyze_chunk:
    # The one rule that goes to HTCondor. One job per chunk list, 43 in total.
    #
    # workflow/Snakefile.level4 splits this in two by year because a params lambda
    # isn't JSON-serialisable for reana-client; here a lambda is fine, so the
    # validation JSON is just looked up per dataset.
    input:
        data="data",
        code="code",
        chunk_list="workflow/chunk_lists/{dataset}/{chunk_id}.txt",
    output:
        # Flat, and at the top level, because an output inside a subdirectory
        # does not survive the trip back: HTCondor looks for it at
        # <scratch>/results/chunks/... and finds nothing, and the job ends up
        # held on "Transfer output files failure". Proven with a two-minute
        # smoke_subdir job rather than four hours into a real chunk. The
        # top-level case is what the pilot exercised and it works, so write
        # there and let stage_chunk put the file in its place afterwards.
        temp("chunk__{dataset}__{chunk_id}.root"),
    params:
        json=lambda wildcards: JSON_BY_DATASET[wildcards.dataset],
    wildcard_constraints:
        dataset="|".join(CHUNKS),
        chunk_id=r"chunk_\d+",
    threads: 1
    container:
        CMSSW_IMAGE
    resources:
        htcondor_request_mem_mb=8192,
        htcondor_request_disk_mb=16384,
        # CERN's pool defaults to the espresso flavour, 20 minutes, which
        # would kill a chunk several hours in. Set as a rule resource rather
        # than in the profile: the plugin quotes classad string values itself,
        # and a value routed through the profile's YAML picks up a second
        # layer of quoting on the way (the same thing that made
        # should_transfer_files unusable).
        classad_JobFlavour="tomorrow",
    shell:
        "set +u "
        "&& WORKDIR=$(pwd) "
        "&& mkdir -p work_{wildcards.dataset}_{wildcards.chunk_id} "
        "&& cd work_{wildcards.dataset}_{wildcards.chunk_id} "
        "&& source /opt/cms/cmsset_default.sh "
        "&& scramv1 project CMSSW CMSSW_5_3_32 "
        "&& cd CMSSW_5_3_32/src "
        "&& eval `scramv1 runtime -sh` "
        "&& cp -r $WORKDIR/{input.code}/HiggsExample20112012 . "
        "&& cd HiggsExample20112012/HiggsDemoAnalyzer "
        "&& scram b "
        "&& cd ../Level4 "
        "&& cp $WORKDIR/{input.chunk_list} this_chunk_index.txt "
        "&& sed "
        "-e 's|/home/cms-opendata/CMSSW_5_3_32/src/Demo/DemoAnalyzer/datasets/CMS_Run2012C_DoubleMuParked_AOD_22Jan2013-v1_10000_file_index.txt|this_chunk_index.txt|' "
        "-e \"s|/home/cms-opendata/CMSSW_5_3_32/src/Demo/DemoAnalyzer/datasets/Cert_190456-208686_8TeV_22Jan2013ReReco_Collisions12_JSON.txt|$WORKDIR/{input.data}/{params.json}|\" "
        "-e \"s|'HiggsDemoAnalyzer'|'HiggsDemoAnalyzerGit'|\" "
        "demoanalyzer_cfg_level4data.py > demoanalyzer_cfg_level4data_chunk.py "
        "&& cmsRun demoanalyzer_cfg_level4data_chunk.py "
        "&& cp *.root $WORKDIR/{output}"


rule stage_chunk:
    # Local, instant: put the flat file analyze_chunk had to produce into
    # the layout everything downstream expects, which is also the layout
    # the REANA run produced, so the two can be compared file by file.
    input:
        "chunk__{dataset}__{chunk_id}.root",
    output:
        "results/chunks/{dataset}/{chunk_id}.root",
    wildcard_constraints:
        dataset="|".join(CHUNKS),
        chunk_id=r"chunk_\d+",
    shell:
        "mkdir -p $(dirname {output}) && cp {input} {output}"


rule merge_dataset:
    # One rule with a wildcard instead of workflow/Snakefile.level4's six unrolled
    # copies -- again, the reason for unrolling them there was reana-client's
    # JSON serialisation, which doesn't apply here.
    input:
        scramdone="results/scramdone.txt",
        cmssw="CMSSW_5_3_32",
        chunks=lambda wildcards: expand(
            "results/chunks/{dataset}/{chunk_id}.root",
            dataset=wildcards.dataset,
            chunk_id=CHUNKS[wildcards.dataset],
        ),
    output:
        "results/{dataset}_full.root",
    wildcard_constraints:
        dataset="|".join(CHUNKS),
    container:
        CMSSW_IMAGE
    shell:
        "set +u "
        "&& source /opt/cms/cmsset_default.sh "
        "&& cd CMSSW_5_3_32/src "
        "&& eval `scramv1 runtime -sh` "
        "&& hadd -f ../../{output} ../../results/chunks/{wildcards.dataset}/*.root"


# The analysis reads the 4mu and 2mu2e final states from the DoubleMu(Parked)
# primary datasets and the 4e final state from DoubleElectron, to avoid
# double-counting from overlapping triggers. 2012 has two eras per primary
# dataset to combine; 2011 has only era A, so its merge output is used as is.

rule combine_2012_muon:
    input:
        b="results/DoubleMuParked_Run2012B_full.root",
        c="results/DoubleMuParked_Run2012C_full.root",
        scramdone="results/scramdone.txt",
        cmssw="CMSSW_5_3_32",
    output:
        "results/DoubleMu12_combined.root",
    container:
        CMSSW_IMAGE
    shell:
        "set +u "
        "&& source /opt/cms/cmsset_default.sh "
        "&& cd CMSSW_5_3_32/src "
        "&& eval `scramv1 runtime -sh` "
        "&& hadd -f ../../{output} ../../{input.b} ../../{input.c}"


rule combine_2012_electron:
    input:
        b="results/DoubleElectron_Run2012B_full.root",
        c="results/DoubleElectron_Run2012C_full.root",
        scramdone="results/scramdone.txt",
        cmssw="CMSSW_5_3_32",
    output:
        "results/DoubleE12_combined.root",
    container:
        CMSSW_IMAGE
    shell:
        "set +u "
        "&& source /opt/cms/cmsset_default.sh "
        "&& cd CMSSW_5_3_32/src "
        "&& eval `scramv1 runtime -sh` "
        "&& hadd -f ../../{output} ../../{input.b} ../../{input.c}"


rule make_plot:
    input:
        data="data",
        code="code",
        scramdone="results/scramdone.txt",
        cmssw="CMSSW_5_3_32",
        mu12="results/DoubleMu12_combined.root",
        e12="results/DoubleE12_combined.root",
        mu11="results/DoubleMu_Run2011A_full.root",
        e11="results/DoubleElectron_Run2011A_full.root",
    output:
        "results/mass4l_combine_user.pdf",
    container:
        CMSSW_IMAGE
    shell:
        "set +u "
        "&& source /opt/cms/cmsset_default.sh "
        "&& cd CMSSW_5_3_32/src "
        "&& eval `scramv1 runtime -sh` "
        "&& cd HiggsExample20112012/Level4 "
        "&& cp ../../../../{input.data}/*.root . "
        "&& cp ../../../../{input.mu12} DoubleMu12.root "
        "&& cp ../../../../{input.e12} DoubleE12.root "
        "&& cp ../../../../{input.mu11} DoubleMu11.root "
        "&& cp ../../../../{input.e11} DoubleE11.root "
        "&& root -b -l -q ./M4Lnormdatall.cc "
        "&& cp mass4l_combine_user.pdf ../../../../{output}"
