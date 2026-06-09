# Project Closeout — fUSi-workflow

**Closed:** 2026-05-25
**Final state:** Abandoned/paused — functional ultrasound (fUSi) preprocessing & analysis workflow, retired from the active workspace.
**Final commit:** `e190846` on `main`

## What this was
A functional ultrasound imaging (fUSi) workflow: DICOM → NIfTI conversion (dcm2niix),
BIDS organization, slice/chunk transforms, GLM and PSTH analysis over fUSi time series.
Last active 2025-02. Closed because work is paused and the repo's 1.5 GB local footprint
(almost entirely raw `data/`) was migrating-dead-weight during the workspace reorg.

## State at closeout
- **Branches pushed:** `main` (e190846, fully in sync) and `close/preproc-wip`.
- **Preserved WIP:** the prior local stash (new `code/utils/preproc.py` +137 lines, plus
  notebook edits in `glm.ipynb` / `slice2chunk.ipynb`) was branched and pushed as
  **`close/preproc-wip`** — it existed nowhere else. Recover it from that branch.
- **Crucial gitignored files archived:** `.env`, `output/`, `logs/` (in the closeout tarball — see below). Values never committed.
- **Large data NOT in git:** `data/` (1.4 GB — DICOM/NIfTI/BIDS/chunk derivatives).
  Classified **reproducible** and **deleted** with the local copy. Re-generate by
  re-running the DICOM→NIfTI→BIDS pipeline from the source DICOMs (not stored here).

## How to resume
1. `git clone git@github.com:yibeichan/fUSi-workflow.git`
2. `git checkout close/preproc-wip` if you need the unfinished preproc work; otherwise `main`.
3. Restore `.env` from the closeout archive (see below).
4. Re-fetch/re-stage source DICOMs and rebuild `data/` via the conversion notebooks
   (`dcm2niix` → BIDS → chunk). Nothing in `data/` was unique to this machine beyond
   what the pipeline regenerates.

## Archive location
`~/archive/repos/fUSi-workflow-2026-05-25.tar.gz` (full repo incl. `.git`, `.env`,
`output/`, `logs/`; **excludes** `data/`). Verified with `gzip -t` + `tar -tzf`.
