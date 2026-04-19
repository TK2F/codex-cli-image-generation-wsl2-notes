# Changelog

## 2026-04-19 — initial public share

First public share of a personal verification memo by TK2LAB and Codex,
covering what was observed on 2026-04-18 in a WSL2 Ubuntu Bash shell on
Windows 11 with `codex-cli 0.121.0`, plus a 2026-04-19 re-test.

**Contents**

- `README.md` / `README.ja.md` / `README.en.md` — bilingual landing and
  per-language write-up: environment versions and how to check them, the
  two methods used to enable `image_generation`, smallest working command,
  aspect-ratio behavior, JSON spec shape, and a review of common claims
  against what was actually observed.
- `QUICKSTART.ja.md` / `QUICKSTART.en.md` — reproduction quickstart with
  the environment, an official-docs-first setup flow, commands run
  verbatim, and helper-script usage.
- `codex-image-batch.sh` — a small Bash helper for running multiple
  image-generation / image-edit jobs from a JSON spec. Supports
  `--doctor`, `--preview`, `--manual`, `--list-presets`, retry, inter-job
  delay, a confirmation prompt, and a `~/.codex/generated_images`
  fallback recovery path.
- `examples/codex-image-batch.sample.json` — generation job samples,
  including a multi-reference character example.
- `examples/codex-image-edit-batch.sample.json` — image-edit job samples.
- `examples/input/README.md` — placeholder folder for edit-input images.
- `examples/gallery/README.md` and `examples/gallery/*.png` — a small,
  metadata-stripped gallery of the re-test outputs with prompt notes.
- `docs/RETEST-2026-04-19.md` — public-safe summary of the 2026-04-19
  re-test: what still held up, what had to be reframed, and manual
  recovery for PNGs that landed under
  `~/.codex/generated_images/<session-id>/`.
- `.github/workflows/ci.yml` — `bash -n`, `shellcheck`, and sample-JSON
  validation for the helper script.
- `LICENSE` — MIT.
- `.gitignore` — excludes helper-script outputs, raw logs, run summaries,
  local env / secrets, editor/OS noise, and local Codex/Claude state.

**Key observations captured here**

- Image generation and editing succeeded, but the PNGs landed under
  `~/.codex/generated_images/<session-id>/` rather than the requested
  workdir path. Recovery uses the `session id` from the run log.
- `--enable image_generation` is a valid flag but behaves as a practical
  no-op when `config.toml` already has `image_generation = true`.
- Enabling sandbox network access was not required for the successful
  image-generation runs observed here.
