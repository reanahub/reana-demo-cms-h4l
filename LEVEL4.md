# Running the Level 4 analysis on REANA

Level 3 processes a single AOD file and draws the one Higgs candidate it finds
as a single marker on top of pre-made Monte Carlo histograms. Level 4 processes
**every file of all six CMS collision datasets** — 12 306 AOD files, roughly 43
TB read over XRootD — so the observed data becomes a full histogram and the
result reproduces the published CMS reference plot.

| Dataset                                     | recid | Files | Validation JSON |
| ------------------------------------------- | ----- | ----- | --------------- |
| `/DoubleMu/Run2011A-12Oct2013-v1/AOD`       | 17    | 1378  | 2011 (7 TeV)    |
| `/DoubleElectron/Run2011A-12Oct2013-v1/AOD` | 16    | 1697  | 2011 (7 TeV)    |
| `/DoubleMuParked/Run2012B-22Jan2013-v1/AOD` | 6004  | 2279  | 2012 (8 TeV)    |
| `/DoubleMuParked/Run2012C-22Jan2013-v1/AOD` | 6030  | 2920  | 2012 (8 TeV)    |
| `/DoubleElectron/Run2012B-22Jan2013-v1/AOD` | 6003  | 1643  | 2012 (8 TeV)    |
| `/DoubleElectron/Run2012C-22Jan2013-v1/AOD` | 6029  | 2389  | 2012 (8 TeV)    |

The files of each dataset are split into chunks of at most 320 files (43 chunks
in total), and each chunk is processed by one job. The chunk size comes from a
measured 45 s per file, which puts a chunk at about 4 hours. The full workflow
is 53 steps: 43 `analyze_chunk` jobs, 6 per-dataset merges, 2 era combinations
(2012 B+C), one CMSSW build and the final plot.

Every step, including the 43 `analyze_chunk` jobs, runs on **Kubernetes**. CERN
HTCondor would give far more parallel slots, but its backend on
reana.cern.ch 0.9.4 cannot run these jobs yet — see
[Later: analyze_chunk on HTCondor](#later-analyze_chunk-on-htcondor) for why and
for the switch to make once the server ships the fix.

## 1. Prerequisites

- A REANA account at <https://reana.cern.ch> and its access token
- A CERN computing account (only for the future HTCondor backend; not needed
  for the Kubernetes run below)

```bash
git clone https://github.com/KyryloFilonenko/reana-demo-cms-h4l.git
cd reana-demo-cms-h4l

python3 -m venv ~/.virtualenvs/myreana
source ~/.virtualenvs/myreana/bin/activate
pip install reana-client

export REANA_SERVER_URL=https://reana.cern.ch/
export REANA_ACCESS_TOKEN=<your-token>

reana-client ping   # verify the connection and token
```

## 2. Kerberos credentials for HTCondor (already done)

Only needed for the future HTCondor path; the Kubernetes run in section 3 does
not use it. The secrets (`CERN_USER`, `CERN_KEYTAB`, `.keytab`) are already
uploaded on this account — `reana-client secrets-list` shows them. Kept here
for reference / re-doing on another account.

CERN HTCondor authenticates with a Kerberos keytab. This is a one-time setup;
without it no HTCondor job will start. On `lxplus.cern.ch`:

```bash
cern-get-keytab --keytab ~/.keytab --user --login <your-cern-login>
kdestroy; kinit -kt ~/.keytab <your-cern-login>; klist   # verify
```

Copy `~/.keytab` to the machine running `reana-client`, then upload it:

```bash
reana-client secrets-add --env CERN_USER=<your-cern-login> \
                         --env CERN_KEYTAB=.keytab \
                         --file ~/.keytab
reana-client secrets-list
```

`CERN_KEYTAB` is the **file name** (`.keytab`), not a path. The HTCondor backend
injects the Kerberos token into each job on its own, so the workflow
specification does not need a `kerberos: true` flag.

## 3. Run the full analysis

The workflow is `reana-level4.yaml`, a separate specification from the
single-file example in `reana.yaml` that stays this repository's entry point.
Every step runs on Kubernetes; the `analyze_chunk` jobs ask for
`kubernetes_memory_limit="8Gi"`.

```bash
reana-client create -n level4 --file reana-level4.yaml
export REANA_WORKON=level4
reana-client upload
reana-client start
```

Everything runs server-side, so the local machine can be shut down once the
workflow is `running`. The 43 chunk jobs are ~4 h each at the measured 45 s per
file; wall time depends on how many run in parallel under the Kubernetes quota,
so expect the run to take considerably longer than the ~5 h it would on
HTCondor. Progress can be checked later from any machine with the same
`REANA_SERVER_URL`, `REANA_ACCESS_TOKEN` and `REANA_WORKON`:

```bash
reana-client ls -w level4 'results/*'      # light; see the IncompleteRead note below
reana-client download results/mass4l_combine_user.pdf
```

The result should match `5500/mass4l_combine.png`, the reference plot shipped
with [CERN Open Data record 5500](https://opendata.cern.ch/record/5500).

If a chunk job is killed for out-of-memory, raise `kubernetes_memory_limit` on
`analyze_chunk_2011` / `analyze_chunk_2012` in `workflow/Snakefile.level4`
(server max is 9.5Gi) and recover the run as in "Recovering from failed
chunks" below.

## Later: `analyze_chunk` on HTCondor

HTCondor would run the 43 chunk jobs with far more parallelism than the
Kubernetes quota allows. It does not work through REANA on
**reana.cern.ch 0.9.4** today (an alternative that skips REANA entirely --
`snakemake-executor-plugin-htcondor` -- is being tried separately; see
[HTCONDOR_DIRECT.md](HTCONDOR_DIRECT.md)):

- A Docker Hub image (`docker.io/cmsopendata/cmssw_5_3_32`) dies at once with
  `/opt/cms/entrypoint.sh: line 17: .../CMSSW_5_3_32/src/job_wrapper.sh: No
  such file or directory`. The image `ENTRYPOINT` `cd`s into `$CMSSW_BASE/src`
  before the command runs, and HTCondor's relative `./job_wrapper.sh` is then
  resolved in the wrong directory —
  [reanahub/reana-job-controller#531](https://github.com/reanahub/reana-job-controller/issues/531).
- A `/cvmfs/unpacked.cern.ch/...` image with `unpacked_img=True` (the
  documented way around that, running the job via `singularity exec` instead
  of the HTCondor Docker Universe) just sits in `running` forever with no logs
  and is not killed by `htcondor_max_runtime`. Confirmed on 0.9.4 with a
  one-line helloworld (`reana_htcondor_helloworld_cvmfs.yaml`) — 40 min, no
  output — while the Docker Hub helloworld finishes in minutes.

The REANA team confirmed both as a 0.9.4 bug with a fix targeted at the 0.95.0
release. Once `reana-client info` reports a server version that ships it, set on
both `analyze_chunk_2011` and `analyze_chunk_2012` in `workflow/Snakefile.level4`:

```python
    container:
        "/cvmfs/unpacked.cern.ch/registry.hub.docker.com/cmsopendata/cmssw_5_3_32:latest"
    resources:
        compute_backend="htcondorcern",
        htcondor_max_runtime="tomorrow",
        unpacked_img=True
```

The Kerberos secrets are already uploaded (section 2). `htcondor_max_runtime`
is `tomorrow` (24 h) against an expected 4 h. Note `reana-client`'s spec
preview echoes only `compute_backend`, not the other two resources — that is
normal. Probe one chunk first with `reana_htcondor_pilot.yaml`
(`reana-client create -n htcondor-pilot --file reana_htcondor_pilot.yaml`,
then `upload` / `start`); if its `DURATION_SECONDS` is far above the 45 s
measured on Kubernetes, regenerate `workflow/chunk_lists/` smaller with
[make_chunks.py](make_chunks.py) before the full run.

## Notes from earlier runs

**`reana-client status` can fail with `IncompleteRead`.** The status response
carries the accumulated logs of every job, and CMSSW is very verbose
(`MessageLogger` runs at `INFO` with no limit), so the payload grows to roughly
160 MB and the transfer breaks on a slow link. The workflow itself is unaffected
— polling only reads. `reana-client ls -w <workflow> 'results/*'` returns the
same progress information in a few kilobytes and is the reliable way to monitor
a long run.

**Recovering from failed chunks.** Individual chunks can fail — OOM-kills or
node evictions are a real risk at four hours per job. `reana-client restart -f`
was observed _not_ to apply an updated specification, so recover by seeding a
fresh workflow with the results that already exist:

```bash
reana-client download -w <old-workflow> results/chunks
unzip -o download_*_chunks_*.zip -d .
rm download_*_chunks_*.zip

reana-client create -n level4-recovery --file reana-level4.yaml
export REANA_WORKON=level4-recovery
reana-client upload                  # inputs first
reana-client upload results/chunks   # then the finished chunks, so they look newer
reana-client start
```

Snakemake treats the uploaded chunks as up to date and recomputes only what is
missing.

**Rebuilding the file lists.** [fetch_file_index.py](fetch_file_index.py) reads
the file index of an Open Data record straight from the public
`opendata.cern.ch` API, as a stand-in for `cernopendata-client` where that is
not installable. [make_chunks.py](make_chunks.py) turns such a list into chunk
files:

```bash
python3 fetch_file_index.py 6030 files_6030.txt
python3 make_chunks.py files_6030.txt workflow/chunks_DoubleMuParked_Run2012C.json \
        --chunk-size 320 --lists-dir workflow/chunk_lists/DoubleMuParked_Run2012C
```

**Monte Carlo is not yet part of the workflow.** The plot still takes its
simulated backgrounds from the pre-made ROOT files in `data/`. Processing the 14
MC datasets of `5500/List_indexfile.txt` through Level 4 the same way as the
collision data is the remaining piece of work.
