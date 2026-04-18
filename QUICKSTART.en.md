# Quick Start

This is the shortest path to a working run inside WSL.

## 1. Move into the shared folder

```bash
cd /path/to/share
```

## 2. Check the environment

```bash
bash ./codex-image-batch.sh --doctor
```

If `codex` is not on `PATH`, run the same check with an explicit binary:

```bash
CODEX_BIN="$HOME/.nvm/versions/node/<your-version>/bin/codex" \
  bash ./codex-image-batch.sh --doctor
```

Replace `<your-version>` with your own installed Node version if needed.

## 3. Preview before running

```bash
bash ./codex-image-batch.sh --spec ./examples/codex-image-batch.sample.json --preview
```

This prints prompts and commands only. No images are generated.

## 4. Run the sample batch

```bash
bash ./codex-image-batch.sh --spec ./examples/codex-image-batch.sample.json --pause-at-end
```

## 5. Run a one-off manual job

```bash
bash ./codex-image-batch.sh --manual --pause-at-end
```

## Common Flags

- `--preview`
  Inspect prompts without generating images
- `--doctor`
  Check dependencies and Codex detection
- `--overwrite`
  Replace existing output files
- `--pause-at-end`
  Keep the terminal open until you press Enter
- `--list-presets`
  Show built-in aspect and style presets

## If Something Fails

- Read `README.en.md` for the full guide
- Run `--doctor` again
- Use `--preview` first
- Check the per-job raw log and the summary JSON written by the runner
