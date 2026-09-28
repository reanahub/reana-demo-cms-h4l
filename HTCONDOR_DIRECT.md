# Variant B: HTCondor without REANA

Two ways to get `analyze_chunk` onto CERN HTCondor:

- **Variant A (REANA, working today):** `reana-level4.yaml` / `workflow/Snakefile.level4`,
  run via `reana-client` on Kubernetes -- see [LEVEL4.md](LEVEL4.md). This is
  the validated path; use it unless you're specifically trying variant B.
- **Variant B (this file):** drive HTCondor directly with
  [`snakemake-executor-plugin-htcondor`](https://snakemake.github.io/snakemake-plugin-catalog/plugins/executor/htcondor.html),
  no REANA server involved. Worth trying because REANA's two `htcondorcern`
  bugs (entrypoint/job_wrapper.sh, `unpacked_img` hang -- see LEVEL4.md
  "Later: analyze_chunk on HTCondor") live in `reana-job-controller`'s own job
  submission code; this plugin submits jobs its own way, so it may not hit
  them at all.

**Status: the full Level 4 analysis has been run this way (2026-09-23), and
the result is identical to the REANA one.** All 43 chunks were computed on the
CERN pool as plain HTCondor jobs, collected, and merged into
`results/mass4l_combine_user.pdf`. Every one of the 42 chunks that has a REANA
counterpart matches it **byte for byte**, and the final PDF is the same 17977
bytes as the one from `level4-recovery`. (The 43rd, `DoubleMuParked_Run2012C/
chunk_0006`, has no counterpart to compare against: it is precisely the chunk
that was OOM-killed at 4Gi during the REANA run.) So REANA's two
`htcondorcern` bugs are bypassed, not worked around.

Use **Variant A2** below for a real run. The Snakemake-executor route further
up is where the ground was mapped and is worth reading for that, but it cannot
survive a multi-day run from lxplus: see the note on lxplus9 killing sessions
on logout.

## What's different from the REANA path

- **The `snakemake` process itself must stay running for the whole workflow.**
  Unlike `reana-client start`, which hands the run off to the server, this
  `snakemake` invocation is the thing polling HTCondor and driving the DAG. If
  it dies (closed terminal, lxplus session drop), the jobs are affected --
  the plugin's own docs warn that exiting the terminal aborts jobs in
  non-shared-filesystem mode, and even in shared mode there is no supervisor
  left running to notice a job finished. **Always run it inside `tmux` /
  `screen`, or under `nohup ... &`.**
- **You get real per-job HTCondor logs**, not REANA's "emitted no logs":
  every job gets its own submit/log/out/err files under `.snakemake/htcondor/`
  (see `htcondor-jobdir` in the profile). This is the main diagnostic upgrade
  over the REANA path, where a hung `/cvmfs/` job gave no way to see what
  HTCondor itself thought was happening.
- **The job runs in a scratch directory, not in your working directory.** The
  plugin submits with an absolute `Cmd` and `Iwd` and adds no transfer
  directives, i.e. it assumes a shared filesystem. HTCondor disagrees:
  `should_transfer_files` defaults to `IF_NEEDED` and the access and execution
  points on this pool don't share a `FILESYSTEM_DOMAIN`, so the job gets
  `/pool/condor/dir_NNN` and only new files at the **top level** of it are
  transferred back. Hence the two rules here read inputs through absolute
  `/afs` paths and write their outputs at the top level. An output under
  `results/` is silently lost -- the run reports success and then
  "missing locally".

## Files

- [`htcondor_direct.smk`](htcondor_direct.smk) -- `smoke` (no container, no
  CMSSW: proves `condor_submit` reaches a worker at all, and that the worker
  has CVMFS and `apptainer`/`singularity`) and `pilot` (the same CMSSW steps
  as a real `analyze_chunk` job, over the one AOD file in
  `workflow/calibration_file.txt` -- mirrors `reana_htcondor_pilot.yaml`).
- [`workflow/profiles/htcondor-direct/config.yaml`](workflow/profiles/htcondor-direct/config.yaml)
  -- the Snakemake profile: `executor: htcondor`, apptainer as the container
  backend, default memory/disk.

## 1. Set up on lxplus

`snakemake>=8.6` needs Python >=3.11, and lxplus's plain `python3` is 3.9.
Two candidates exist, and only one of them works here:

- **`/usr/bin/python3.12` (system): no.** It runs on lxplus, but the batch
  execution nodes don't have `libpython3.12.so.1.0` installed, so the
  interpreter cannot start there at all.
- **LCG on CVMFS: yes.** CVMFS is mounted identically on lxplus and on the
  execution nodes, so the same interpreter and the same libraries are visible
  from both.

```bash
LCG=/cvmfs/sft.cern.ch/lcg/views/LCG_110/x86_64-el9-gcc15-opt
$LCG/bin/python3 --version          # 3.13.11
$LCG/bin/python3 -m venv ~/.virtualenvs/htcondor-direct
source ~/.virtualenvs/htcondor-direct/bin/activate
pip install --upgrade pip
pip install "snakemake>=8.6" snakemake-executor-plugin-htcondor
```

**Do not pass `--copies`.** The venv default (symlinks) is what you want, and
`--copies` actively breaks this setup: the LCG interpreter finds its own
`libpython` through a *relative* RPATH (`$ORIGIN/../lib`), so a copy placed in
`~/.virtualenvs/.../bin/` looks for the library in
`~/.virtualenvs/.../lib/`, finds nothing, and dies -- `venv --copies` itself
fails at the `ensurepip` step with exit 127 for exactly this reason. Left as a
symlink, `$ORIGIN` resolves through to the CVMFS `bin/` directory and the
library is found.

The matching half of this is `htcondor_submit_transfer_executable: "False"` in
[the profile](workflow/profiles/htcondor-direct/config.yaml): the plugin never
sets `transfer_executable`, so HTCondor's default (`True`) would copy the
interpreter into the execution point's scratch directory and break `$ORIGIN`
all over again. See the comment there.

Confirm lxplus can talk to the pool at all, independently of REANA:

```bash
klist                    # valid Kerberos ticket (kinit if not)
condor_q                 # should return, even if empty, not error out
condor_status -avail | head
```

## 2. Smoke test

```bash
cd ~/reana-demo-cms-h4l   # your clone
tmux new -s htcondor-direct   # or: screen -S htcondor-direct
source ~/.virtualenvs/htcondor-direct/bin/activate

snakemake -s htcondor_direct.smk \
  --workflow-profile workflow/profiles/htcondor-direct \
  --jobs 1 -p smoke
```

**While it runs**, in another lxplus session (or another `tmux` pane):

```bash
condor_q                         # job should appear: Idle -> Running -> gone
ls .snakemake/htcondor/          # one directory per submitted job
cat .snakemake/htcondor/*/*.log  # HTCondor's own event log for the job
cat .snakemake/htcondor/*/*.out .snakemake/htcondor/*/*.err
```

**After it finishes:**

```bash
condor_history -limit 5          # confirm it shows Completed, not Removed/Held
cat htcondor_direct_smoke.txt
```

If `condor_q` shows the job `held` instead of progressing, get the reason before
doing anything else:

```bash
condor_q -hold <cluster>.<proc>   # e.g. condor_q -hold 16677020.0
```

### What it answered

Run on 2026-09-16, execution point `b9p28p6148.cern.ch`. All three checks
passed, which is what makes `pilot` worth attempting:

- **CVMFS**: fully mounted, `unpacked.cern.ch` and `cms.cern.ch` among the
  repositories -- so the CMSSW image `pilot` asks for is reachable.
- **apptainer**: `/usr/bin/apptainer` present.
- **AFS**: `/afs/cern.ch/user/` readable, so a job can reach the working
  directory through an absolute path.

It also showed `PWD=/pool/condor/dir_1613768`, i.e. the job runs in scratch --
which is why both rules use absolute `/afs` paths for input and top-level
output files.

### CMSSW and `set -u`

Snakemake runs every shell command under `set -euo pipefail`. CMSSW's
`/opt/cms/cmsset_default.sh` reads `CMS_PATH` before assigning it, which is
fine in an ordinary shell and fatal under `nounset`:

```
/opt/cms/cmsset_default.sh: line 33: CMS_PATH: unbound variable
```

The job then exits 127 before any analysis runs, and -- because the output
file never appears -- HTCondor puts it on hold complaining about output
transfer instead, which points at entirely the wrong thing. Any rule that
sources a CMSSW environment must start with `set +u`. REANA never hit this;
its job wrapper doesn't set `-u`.

## 3. Pilot (real CMSSW, one file)

```bash
snakemake -s htcondor_direct.smk \
  --workflow-profile workflow/profiles/htcondor-direct \
  --jobs 1 -p pilot
```

Same monitoring as the smoke test (`condor_q`, `.snakemake/htcondor/.../`
log+out+err). This step takes minutes, not hours, so watch it interactively
rather than detaching.

**Verify it actually ran the analysis, not just the container:**

```bash
cat htcondor_direct_pilot_timing.txt   # DURATION_SECONDS=<N>
```

Compare `<N>` to the ~45 s/file baseline measured on Kubernetes. If this file
exists with a plausible number, the full chain worked: HTCondor submission,
CVMFS image, CMSSW build, XRootD read from EOS, `cmsRun`.

Measured on 2026-09-16: `DURATION_SECONDS=69`, whole run 4 min 10 s including
queue, input transfer and the `scram b` build. Note that 69 s covers `cmsRun`
startup as well as the one file, and that startup is amortised across the 320
files of a real chunk -- so this does not by itself mean chunks would take
69/45 times longer than on Kubernetes. Measure a real chunk before resizing
anything.

## 4. Full run

`htcondor_direct.smk` also carries the whole Level 4 workflow, under the
`level4` target. Only `analyze_chunk` goes to HTCondor -- 43 jobs, one per
chunk list. `scram`, `merge_dataset`, the two `combine_2012_*` rules and
`make_plot` are `localrules`: seconds of work each, and they share the CMSSW
build area in the working directory, which would otherwise have to be shipped
to a node. lxplus has apptainer and CVMFS, so they still run in the container.

`rule all` stays pointed at the pilot, so a bare `snakemake` cannot start a
two-day run by accident -- name the target explicitly.

### Outputs in subdirectories don't come back

Chunk results belong in `results/chunks/<dataset>/<chunk_id>.root`, but an
output inside a subdirectory does not survive the trip back from the execution
point. HTCondor looks for it at `<scratch>/results/chunks/...`, finds nothing,
and the job goes to `held` with "Transfer output files failure" -- most likely
because Snakemake moves outputs into its own `--local-storage-prefix` before
HTCondor's transfer runs. `transfer_output_remaps` does not save it.

So `analyze_chunk` writes a flat `chunk__<dataset>__<chunk_id>.root` at the
top level, which is the case the pilot proved works, and the local
`stage_chunk` rule moves it into place afterwards. The flat file is `temp()`,
so it doesn't accumulate.

The `smoke_subdir` rule is kept as a two-minute regression test for this. If a
future plugin version fixes it, that rule will start passing and
`analyze_chunk` can write directly where it belongs:

```bash
snakemake -s htcondor_direct.smk   --workflow-profile workflow/profiles/htcondor-direct   --jobs 1 -p results/smoke_subdir/htcondor_direct_subdir.txt
```

### Then the full run

```bash
tmux new -s level4-htcondor
snakemake -s htcondor_direct.smk   --workflow-profile workflow/profiles/htcondor-direct   --jobs 20 --keep-going level4
```

`--keep-going` matters: one bad chunk shouldn't stop the other 42.

### What has to survive a multi-day run

Nothing supervises this from a server, unlike REANA. Two things will end the
run if ignored:

- **The `snakemake` process.** In `tmux` or `screen`, always. Detach with
  `Ctrl+b` then `d`; reattach with `tmux attach -t level4-htcondor`.
- **The Kerberos ticket**, which lasts about 25 hours and is what lets jobs
  reach AFS. A run longer than that needs it renewed -- `kinit -R` from cron,
  or `k5reauth -f -i 3600 -- snakemake ...` wrapping the whole run.

### The chunks are already there

`results/chunks/` on lxplus holds all 43 chunk files from the REANA run. If
they're in place, Snakemake will consider `analyze_chunk` done and go
straight to the merges -- correct behaviour, but it means nothing reaches
HTCondor. To actually exercise the farm, move them aside first:

```bash
mv results/chunks results/chunks.reana
```

Keep them: they are a validated reference. Comparing a HTCondor-produced
chunk against its REANA counterpart is the strongest check available that
this path computes the same thing.

## Variant A2: no live dispatcher (use this for a real run)

**lxplus9 kills tmux and screen sessions on logout**
([CERN/HSF analysis essentials](https://hsf-training.github.io/analysis-essentials/shell-extras/persistent-screen.html)),
and a Snakemake dispatcher dies with them. A 43-chunk run takes a day or
more, so it cannot be supervised from lxplus at all. Observed directly: a
single chunk submitted at 21:27 lost its dispatcher on logout, left a 0-byte
Snakemake log, and the job itself was removed at 06:44 elapsed -- most likely
when its delegated Kerberos credential lapsed with the session.

HTCondor jobs, by contrast, survive logout by design. The 43 chunks are
independent, so they don't need a DAG engine at all: submit them as plain
jobs, collect the files afterwards, and run only the short merge/combine/plot
steps locally, which take minutes and need no supervision.

### Files

- [`condor/chunk_job.sh`](condor/chunk_job.sh) -- one chunk. Re-enters itself
  inside the CMSSW container (`apptainer exec`, binding `/cvmfs` and the
  scratch directory), builds the analyser, runs `cmsRun`, writes one flat
  file at the top level of the scratch directory.
- [`condor/chunks.txt`](condor/chunks.txt) -- the 43 `dataset, chunk_id`
  pairs, generated from `workflow/chunk_lists/`.
- [`condor/analyze_chunks.sub`](condor/analyze_chunks.sub) -- the submit
  description. `tomorrow` flavour (the pool defaults to espresso, 20 minutes),
  8GB, 16GB disk, two retries.
- [`condor/collect_chunks.sh`](condor/collect_chunks.sh) -- moves finished
  files into `results/chunks/<dataset>/`, reports what is still missing. Safe
  to run repeatedly while jobs are still going.

Jobs are deliberately self-contained: the analyser source, both validation
JSONs and the chunk's file list are transferred in, and the AOD files are read
over XRootD from `eospublic`, which is public. Nothing touches AFS, so no
credential has to stay valid for a job to survive.

### Run it

```bash
cd ~/reana-demo-cms-h4l
mkdir -p condor_out condor_logs
condor_submit condor/analyze_chunks.sub
```

Then log out. Nothing on lxplus needs to stay alive.

Measured on the real run: one chunk is about 4h20m (`cmsRun finished in
15744 s` for 320 files), and all 43 finished inside a day with nothing
supervising them. Two points are worth submitting one chunk first for, since
both were found that way and both would have been expensive across 43 jobs:
the flat-output-plus-collect mechanics, and the size of what CMSSW writes to
stderr.

Check back with:

```bash
condor_q
condor_q -hold                      # if anything is stuck, get the reason
./condor/collect_chunks.sh          # moves what's done, lists what isn't
```

### Finish locally

Once `collect_chunks.sh` reports 43/43:

```bash
snakemake -s htcondor_direct.smk --cores 1   --software-deployment-method apptainer   --apptainer-args "--bind /cvmfs --bind /afs"   level4
```

Everything left is a `localrule` -- `scram`, the merges, the two combines and
`make_plot` -- so this runs on lxplus in minutes with no dispatcher to lose.
Result: `results/mass4l_combine_user.pdf`.

### Re-submitting failures

`collect_chunks.sh` writes `condor/retry.txt` with whatever is still
missing, every time it runs, so it is always current:

```bash
./condor/collect_chunks.sh
condor_submit condor/analyze_chunks.sub -append 'chunklist = condor/retry.txt'
```

The list is a submit macro rather than an appended `queue` statement:
`condor_submit` refuses two `queue` statements in one submission.

## If it works

Only after `pilot` succeeds is it worth adapting the real 43-job
`analyze_chunk` rules (from `workflow/Snakefile.level4`) to this executor: copy
their `shell:` blocks into `htcondor_direct.smk` with wildcards over
`workflow/chunk_lists/`, bump `htcondor_request_mem_mb` (the REANA run needed
8Gi -- see LEVEL4.md), and run the whole thing inside `tmux`/`nohup` since,
unlike REANA, nothing keeps it alive if lxplus drops. Ask before doing that
conversion -- it's real workflow-editing work, not a config tweak.
