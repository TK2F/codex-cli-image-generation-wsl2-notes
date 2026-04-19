# Reproduction Quickstart — Start with One Image, Then Move to Batch If Needed

This document rewrites my original verification flow into an order that
is easier for beginners to follow. It reflects what I, TK2Works, tested
with Codex CLI on WSL2 Ubuntu when checking whether image generation and
image editing actually worked from Bash.

What is shared here is not the official Codex CLI way to work. It is a
record of **what actually worked in this environment**. In particular,
the bundled `codex-image-batch.sh` and JSON specs are helper pieces I
added so I could repeat my own checks more easily. They are not built-in
Codex CLI workflow features.

For the longer write-up — environment details, aspect-ratio behavior,
script semantics, and the full set of observations — see
[README.en.md](README.en.md).

## What to know first

- Every command here assumes **Bash inside WSL2**.
- Native Windows PowerShell was out of scope for this verification.
- Start by moving into **the root directory of this repository** before
  running any commands.
- Relative paths such as `./examples/...` and `./codex-image-batch.sh`
  will fail if you run them outside the repo root.
- The safest first step is to ignore the helper script and confirm that
  **Codex CLI alone can generate one image**.
- In this environment, `image_generation` initially appeared as `false`,
  but I am not claiming that is the universal default.
- In the 2026-04-19 re-test, generated PNGs sometimes landed under
  `~/.codex/generated_images/<session-id>/` instead of the working
  directory.

### Confirm where you are before you start

In WSL2 Ubuntu / Bash, change into the directory where you cloned or
unpacked this repo before doing anything else. For example:

```bash
cd /path/to/codex-cli-image-generation-wsl2-notes
pwd
ls
```

If `pwd` prints the path to this repo, and `ls` shows at least these
entries, you are in the right place:

- `README.md`
- `QUICKSTART.en.md`
- `codex-image-batch.sh`
- `examples`

If you are using Windows Terminal, open the Ubuntu profile first and
then run the same check. A prompt like `user@host:~$` often means you
are still in your home directory rather than inside the repo.

## 1. minimum one-shot image generation

The first goal is simple: **confirm that one image can be generated
without the helper script**. Once that works, batch usage becomes much
easier to reason about.

### What you need

- WSL2 Ubuntu
- Node.js and Codex CLI
- Completed Codex CLI login

Small sanity checks:

```bash
codex --version
codex features list
```

In my environment, `codex --version` returned `codex-cli 0.121.0`, and
`codex features list` showed the current state of `image_generation`.

### Enabling `image_generation`

Three methods worked in this environment.

**Method A: set it in `~/.codex/config.toml`**

```toml
[features]
image_generation = true
```

**Method B: use Codex's feature-management command**

```bash
codex features enable image_generation
```

**Method C: pass `--enable image_generation` only for the current run**

```bash
codex exec --enable image_generation -
```

In the later re-test, Method C behaved like a practical no-op once the
feature was already enabled in config. For beginners, the safest pattern
is to check `codex features list` first, then choose the path that
matches the current state.

### The first one-liner to try

Small English prompt example:

```bash
printf 'Use the built-in image generation capability only.\nGenerate a square 1:1 image of a blue sphere on a white background.\nNo text, no logo, no watermark.\n' | codex exec --enable image_generation -
```

Small Japanese prompt example:

```bash
printf 'built-in の画像生成機能だけを使ってください。\n正方形 1:1、1024x1024 で、白背景に青い球体を 1 枚描いてください。\n文字、ロゴ、透かしは入れないでください。\n' | codex exec --enable image_generation -
```

At this stage, the goal is simple: confirm that **one image comes out at
all**. Leave batch runs and helper tooling for later.

### If you also want one editing test

One input image:

```bash
codex exec --enable image_generation -i ./input.png "Use the built-in image editing capability only. Change the background to white. Keep the subject, composition, and colors intact. No text, no logo, no watermark."
```

Two input images:

```bash
codex exec --enable image_generation -i ./base.png -i ./reference.png "Use the first image as the base. Transfer the palette and mood from the second image while preserving the composition and main subject of the first image. No text, no logo, no watermark."
```

Important note:

- Two `-i` flags worked for this tested prompt.
- That does **not** prove a CLI-level rule that "first means base and
  second means reference."
- The safer reading is that the prompt was interpreted that way in this
  run.

### The shortest safe path for beginners

1. Check `codex --version`
2. Check `codex features list`
3. If needed, use `config.toml` or `--enable image_generation`
4. Generate one image with a single one-liner
5. Confirm where the PNG actually landed

## 2. JSON batch usage

Once the one-shot flow works, move to JSON batch only if you actually
want to run multiple jobs.

### This is a repo-local helper flow, not an official Codex workflow

`codex-image-batch.sh` is a small Bash helper I wrote because repeatedly
testing multiple jobs by hand became tedious. It is not an official
Codex CLI tool.

The JSON values used by that script, such as `aspect_ratio` and the
style shorthands, are not official Codex CLI parameters. They are
**repo-local shorthand values** that the script expands into prompts.

### Extra dependencies for batch runs

If you want to try batch mode too, install these on top of the minimum
setup:

```bash
sudo apt update
sudo apt install -y jq python3 bubblewrap coreutils findutils gawk grep
```

Rough role split:

- `jq`, `python3`: JSON reading and syntax validation
- `bubblewrap`: Linux / WSL prerequisite checks around Codex sandboxing
- `coreutils`, `findutils`, `gawk`, `grep`: support commands used by
  the helper script

### The first three steps

1. Run diagnostics only

```bash
bash ./codex-image-batch.sh --doctor
```

2. Print the prompt and command without executing generation

```bash
bash ./codex-image-batch.sh --spec ./examples/codex-image-batch.sample.json --preview
```

3. Run the sample only after the preview looks correct

```bash
bash ./codex-image-batch.sh --spec ./examples/codex-image-batch.sample.json --pause-at-end
```

If you want one interactive job without writing JSON:

```bash
bash ./codex-image-batch.sh --manual --pause-at-end
```

### How to read the sample JSON

Generation sample:

- `examples/codex-image-batch.sample.json`

Editing sample:

- `examples/codex-image-edit-batch.sample.json`

The script accepts three root shapes:

- a single job object
- an array of jobs
- an object containing `defaults` and `jobs`

Small example:

```json
{
  "defaults": {
    "language": "ja",
    "output_dir": "./outputs"
  },
  "jobs": [
    {
      "name": "my-first-image",
      "mode": "generate",
      "aspect_ratio": "square",
      "prompt": "Generate one blue sphere on a white background. No text, no logo, no watermark."
    }
  ]
}
```

### One practical warning about the bundled sample

- Some sample jobs need local input images under `examples/input/`.
- If those files are not present yet, `--preview` or a real run can fail
  with an input-image-not-found error for that job.
- For a first pass, it is fine to validate the generation-only jobs
  first and leave the edit or multi-reference jobs for later.

### A safe order for beginners

1. Start with one one-shot image
2. Then run `--doctor`
3. Then run `--preview`
4. Then run the sample JSON
5. Only after that, write your own JSON

## 3. troubleshooting for generated image location

The most confusing failure mode in this repo is: **the image appears to
have been generated, but you cannot find the PNG where you expected**.

### The main thing to know

In the 2026-04-19 re-test, Codex sometimes printed an output location
that did not match where the PNG actually ended up.

The location I could confirm in this environment was:

```text
~/.codex/generated_images/<session-id>/ig_*.png
```

### The order I would check

1. Look for the PNG in the current working directory
2. Look for `session id:` in the Codex output
3. Inspect `~/.codex/generated_images/<session-id>/`
4. If you used the helper script, also inspect the run summary JSON

### Manual recovery example

```bash
session_id="019da255-d906-7831-8a2d-0912b86d3e00"
cp ~/.codex/generated_images/"$session_id"/*.png ./recovered-output.png
```

### Common misunderstandings

- The printed `Output path` did not always correspond to a real file in
  this environment.
- Even when using the helper script, the script may end up recovering
  from `~/.codex/generated_images`.
- Parallel runs increase the chance of grabbing the wrong image. A
  session-specific recovery path is safer when available.
- A `tokens used` line can appear in the Codex log even when the PNG did
  not land in the current directory. Treat it as run metadata, not as
  proof that the file exists where you expected.

### Where I would look first when something fails

- `codex` not found: nvm initialization may not be active in the current
  shell. Open a fresh terminal or check `~/.bashrc`.
- `image_generation` still looks disabled: re-check `codex features list`
  and then choose between `config.toml`, `codex features enable`, and
  per-run `--enable image_generation`.
- PNG missing where expected: check
  `~/.codex/generated_images/<session-id>/` first.
- `bubblewrap` warning: on Ubuntu, `sudo apt install -y bubblewrap`
  added it in my environment.
- PowerShell rejects the command: every command here assumes WSL Bash,
  not native PowerShell.

## 4. JSON validation tips

Once you move to JSON batch, the safest pattern is **do not start with a
real run**. First make sure the JSON itself is not broken.

### Check syntax first

With `jq`:

```bash
jq . ./examples/codex-image-batch.sample.json >/dev/null
```

With `python3`:

```bash
python3 -m json.tool ./examples/codex-image-batch.sample.json >/dev/null
```

If either command exits quietly, the JSON syntax is at least valid.

### Use `--preview` before real execution

Valid JSON does not guarantee the final prompt is what you intended.
This repo's JSON format is interpreted by the helper script, which means
the final prompt is assembled before Codex sees it. That is why
`--preview` matters.

```bash
bash ./codex-image-batch.sh --spec ./examples/codex-image-batch.sample.json --preview
```

What `--preview` helps you inspect:

- the final prompt that will be sent to Codex
- the `codex exec` command that is about to run
- resolved input-image paths

### Things to watch when writing your own spec

- Relative paths are resolved from the **spec file's directory**.
- `mode: "edit"` requires `input_image` or `input_images`.
- If you provide `prompt` directly, it takes priority.
- If you split content into `subject` and `scene`, the script assembles
  the final prompt from those pieces.
- For multiple images, prompt wording still matters because image roles
  are not guaranteed by documented CLI semantics.

### A simple safe pattern

1. Run the sample JSON through `jq` or `python3 -m json.tool`
2. Use `--preview` and inspect the prompt visually
3. Edit your own JSON in small steps
4. Re-check after each small change

## Closing note

This document reflects what I observed in this environment on
2026-04-18 / 2026-04-19. Differences on your side are entirely possible.
If behavior diverges, compare the Codex CLI version, feature state,
image location, auth state, and official documentation before assuming
the same commands still behave the same way.
