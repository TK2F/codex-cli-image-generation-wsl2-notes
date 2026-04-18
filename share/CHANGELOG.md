# Changelog

## 2026-04-19 — review refresh

Follow-up refresh based on the 2026-04-19 re-test that is summarized in
`docs/RETEST-2026-04-19.md`.

**Changed**

- Corrected the docs to match the observed storage behavior: image
  generation and editing succeeded, but the PNGs landed under
  `~/.codex/generated_images/<session-id>/` rather than the requested
  workdir path.
- Added a manual recovery flow using the `session id` from the run log.
- Reframed `--enable image_generation` as a valid flag that behaved as
  a practical no-op when config already had `image_generation = true`.
- Clarified that enabling sandbox network access was not required for
  the successful image-generation runs captured in the evidence pack.
- Unified the method ordering across README and QUICKSTART, and added
  the persistent CLI path `codex features enable image_generation`.
- Added a small GitHub Actions workflow for `bash -n`, `shellcheck`,
  and sample JSON validation.
- Added a public-safe re-test summary under `docs/RETEST-2026-04-19.md`
  plus a small `examples/gallery/` set with prompt metadata.
- Added a multi-reference character example to
  `examples/codex-image-batch.sample.json` and documented the
  `reference_images` alias in the input notes and README.

**Fixed**

- Removed a few `shellcheck` warnings in `codex-image-batch.sh`.
- Made numbered interactive choices in `codex-image-batch.sh` more
  explicit.
- Tightened helper-script recovery so it prefers the exact
  `session id` directory under `~/.codex/generated_images/` before
  falling back to a broader filesystem scan.
- Added `session_id` / `internal_output_path` to helper-script summary
  output when available.

## 2026-04-19 — initial share

First portable share-package cut of a personal memo by TK2LAB and Codex,
describing what was observed on 2026-04-18 in a WSL2 Ubuntu Bash shell
on Windows 11, running `codex-cli 0.121.0`.

**Added**

- `codex-image-batch.sh` — a small Bash helper script for running
  multiple image-generation / image-edit jobs from a JSON spec.
  Includes `--doctor`, `--preview`, `--manual`, `--list-presets`,
  retry, inter-job delay, a confirmation prompt, and a
  `~/.codex/generated_images` fallback recovery path.
- `examples/codex-image-batch.sample.json` — five sample generation
  jobs.
- `examples/codex-image-edit-batch.sample.json` — three sample edit
  jobs.
- `examples/input/README.md` — placeholder folder for edit-input
  images.
- `README.md` — bilingual landing page with status, disclaimer, and
  entry points.
- `README.ja.md` / `README.en.md` — per-language write-up of the
  observations: environment versions and how to check them, the two
  methods used to enable `image_generation`, minimum working commands,
  aspect-ratio behavior, JSON spec shape, a review of common claims
  against what was observed here, and official references.
- `QUICKSTART.ja.md` / `QUICKSTART.en.md` — reproduction-style
  quickstart with the environment, an official-docs-first setup flow
  summary, the commands run verbatim, and the helper script usage.
- `.gitignore` — excludes helper-script outputs, raw logs, run
  summaries, common editor/OS noise, and local secrets.
