# Changelog

## 2026-04-19

Initial private-publication release. Verified by TK2LAB and Codex on
`codex-cli 0.121.0` inside WSL2 Ubuntu Bash.

**Added**

- `codex-image-batch.sh` — WSL/Bash-first runner with `--doctor`,
  `--preview`, `--manual`, `--list-presets`, retry, inter-job delay,
  confirmation prompt, and `~/.codex/generated_images` fallback recovery
- `examples/codex-image-batch.sample.json` — five generation jobs
- `examples/codex-image-edit-batch.sample.json` — three edit jobs
- `examples/input/README.md` — placeholder folder for edit inputs
- `README.md` — bilingual landing with status and entry points
- `README.ja.md` / `README.en.md` — single comprehensive doc per
  language with hands-on notes, a review of common claims against what
  was observed here, and official references
- `QUICKSTART.ja.md` / `QUICKSTART.en.md` — first-time setup covering
  WSL2 install, account login, Codex CLI install, direct commands, and
  the runner
- `.gitignore` — excludes runner outputs, raw logs, run summaries,
  common editor/OS noise, and local secrets
