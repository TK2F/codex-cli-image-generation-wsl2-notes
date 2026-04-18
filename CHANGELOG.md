# Changelog

## 2026-04-19 — initial share

First private-publication cut of a personal memo by TK2LAB and Codex,
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
