# Codex Image Batch Runner for WSL2 Ubuntu

This repository is the portable handoff package for the workflow validated in WSL2 Ubuntu, where `codex` runs inside the shell.

It is designed to be copied to another machine without exposing the original author's home directory, Windows username, or local repository path.

Validated by:

- TK2LAB
- Codex

Tested on:

- 2026-04-19
- `codex-cli 0.121.0`

## Included Files

- `codex-image-batch.sh`
- `examples/codex-image-batch.sample.json`
- `examples/codex-image-edit-batch.sample.json`
- `examples/input/README.md`

## Scope

The package is written around one tested setup:

- WSL2
- Ubuntu
- Codex CLI invoked from Bash

Other Linux environments may also work, but that is not the claim being made here.

## What This Runner Does

- Runs one or many image-generation jobs from JSON
- Supports one-off manual prompting without editing JSON
- Supports image-edit jobs with one or more input images
- Accepts Linux paths, Windows drive paths like `C:\...`, and WSL UNC paths like `\\wsl.localhost\Distro\...`
- Recovers output from `~/.codex/generated_images` if Codex does not copy the PNG into the requested directory
- Writes a summary JSON file and per-job raw logs

## First Run

From the repository root:

```bash
bash ./codex-image-batch.sh --doctor
```

This checks:

- whether `jq`, `python3`, and other required commands exist
- whether `codex` is on `PATH`
- whether a likely `~/.nvm/.../bin/codex` fallback exists
- whether `image_generation` is already enabled

If `codex` is not on `PATH`, you can run with an explicit binary:

```bash
CODEX_BIN="$HOME/.nvm/versions/node/<your-version>/bin/codex" \
  bash ./codex-image-batch.sh --doctor
```

Replace `<your-version>` with your actual Node version.

## Safest Starting Point

Preview the sample spec before running anything:

```bash
bash ./codex-image-batch.sh --spec ./examples/codex-image-batch.sample.json --preview
```

That prints prompts and commands without generating images.

## Real Batch Run

```bash
bash ./codex-image-batch.sh --spec ./examples/codex-image-batch.sample.json --pause-at-end
```

The runner asks for confirmation before a real execution unless you explicitly use `--no-prompt`.

## Manual One-Off Run

```bash
bash ./codex-image-batch.sh --manual --pause-at-end
```

Use this when you want to type one prompt interactively instead of creating JSON.

## JSON Shape

Supported JSON roots:

- a single job object
- an array of job objects
- an object containing `defaults` and `jobs`

Example:

```json
{
  "defaults": {
    "language": "ja",
    "codex_model": "gpt-5.4",
    "output_dir": "./outputs"
  },
  "jobs": [
    {
      "name": "my-first-image",
      "mode": "generate",
      "aspect_ratio": "square",
      "prompt": "A clean product photo of a glass bottle on a white background."
    }
  ]
}
```

## Most Useful Options

- `--preview`
  Print prompts and commands only
- `--manual`
  Enter one job interactively
- `--doctor`
  Print environment diagnostics and exit
- `--list-presets`
  Print available aspect and style presets
- `--overwrite`
  Replace existing outputs instead of skipping them
- `--stop-on-job-error`
  Stop the batch at the first failure
- `--inter-job-delay N`
  Wait `N` seconds between jobs
- `--retry-count N`
  Retry failed jobs `N` extra times
- `--pause-at-end`
  Wait for Enter before exit

## Common Beginner Mistakes

- Running the script in Windows PowerShell instead of WSL Bash
  This package is for WSL/Linux shells.
- Pasting a folder path instead of a JSON file path
  The runner warns if you select a directory.
- Forgetting to preview first
  Use `--preview` when you are unsure the prompt or JSON is correct.
- Using edit mode without an input image
  Edit jobs require at least one existing image path.
- Expecting existing outputs to be replaced automatically
  By default, existing PNGs are skipped. Use `--overwrite` to replace them.
- Assuming a pasted Windows path will always fail
  Common `C:\...` and `\\wsl.localhost\...` paths are converted automatically.

## Output Files

By default, outputs go to:

- `./outputs` for generation samples
- `./edited-outputs` for edit samples

Each run also writes:

- one raw log per job
- one run-summary JSON file

Those summary and log references are written as relative paths whenever possible so the file is safer to forward to someone else.

## Notes for Sharing

- This package intentionally avoids embedding any user-specific home directory or machine name in the files you are expected to distribute.
- You can rename the folder or move it anywhere inside WSL.
- Relative paths in JSON are resolved relative to the JSON file location, not the shell's current working directory.
