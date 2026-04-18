# Reproduction Quickstart — The Commands I Actually Ran (as of 2026-04-18)

While TK2LAB and Codex were checking whether `codex` could really
generate and edit images from a WSL2 Ubuntu Bash shell, several
commands worked end-to-end. This page is the personal memo I kept
during that check, shared here for anyone with the same question.
**It is not a recommended procedure and not an introductory tutorial.**
The framing is "here is what I ran and what happened" — use it as a
reproduction checklist on your own machine and compare.

> This is a personal observation recorded on 2026-04-18. Codex CLI
> evolves quickly, so future releases, behavior changes, new findings,
> or official announcements may make parts of this report outdated
> within a short timeframe. Treat this as a single reference point in
> time. Other commands, prompt patterns, and helper designs almost
> certainly exist — please try variations in your own environment.

For the longer write-up — versions, observations in detail,
aspect-ratio behavior, helper-script options, and a review of common claims
against what I saw here — see [README.en.md](README.en.md).

---

## The environment behind every command below

These values are the stack I verified against. Different environments
do not invalidate the commands, but this is the first place to compare
when results diverge.

- **Host OS**: Windows 11
- **Runtime**: Ubuntu on WSL2 (LTS)
- **Shell**: Bash (native Windows PowerShell is out of scope)
- **Codex CLI**: `codex-cli 0.121.0`

Concrete version values for Node.js, npm, jq, python3, bubblewrap,
and related tools — plus the commands that read yours — live in
[README.en.md — Environment versions and how to check them](README.en.md#environment-versions-and-how-to-check-them).

## Environment setup as a flow summary (official links)

Rather than re-documenting what the upstream projects describe in
detail, I list the flow I followed and the authoritative references.

1. **Windows 11 + WSL2 + Ubuntu**
   Use the Microsoft-supplied procedure. The common one-time flow is
   `wsl --install` from an elevated PowerShell.
   Reference: https://learn.microsoft.com/windows/wsl/install
2. **Basic Linux packages**
   On Ubuntu I made sure `jq`, `python3`, `bubblewrap`, `curl`, and
   `git` were available. `bubblewrap` appears in the Codex sandbox
   documentation as the prerequisite on Linux/WSL2.
   Reference: https://developers.openai.com/codex/concepts/sandboxing#prerequisites
3. **Node.js**
   I used the LTS line via nvm. Any Node installation that places the
   `codex` executable on `PATH` after the CLI install will serve the
   same purpose.
   Reference: https://nodejs.org/
4. **Codex CLI install and first login**
   Installation, browser authorization, and feature inspection are all
   documented by OpenAI directly.
   Reference: https://developers.openai.com/codex/cli

With that in place, `codex --version` and `codex features list` should
return output in the Bash shell. My own `codex --version` printed
`codex-cli 0.121.0`.

## `image_generation` looked disabled by default — two ways I got it working

In my environment, `codex features list` initially showed
`image_generation` as disabled (`false`). This was what I saw on my
machine; I am not claiming it as the canonical default. To get image
generation running I confirmed two methods. Both worked in this run,
and portrait, landscape, and 1:1 outputs all came through.

**Method A: pass `--enable image_generation` on each `codex exec` call**

```bash
codex exec --enable image_generation -
```

Adding the flag was enough in my run. The bundled
`codex-image-batch.sh` uses this approach internally — it adds
`--enable image_generation` only when the feature is not already
enabled.

**Method B: set it in `~/.codex/config.toml`**

```toml
[features]
image_generation = true
```

After adding those two lines, both interactive `codex` and
`codex exec` runs produced images in my environment without the flag.
For repeated use the config-file path was the less fiddly of the two.

Defaults and feature-enablement steps can change in new CLI versions,
so when a fresh version is installed it is worth checking
`codex features list` first and deferring to the official Codex CLI
docs.

## The commands I ran, in order

Each one is the minimal one-line form I used during verification. All
of them produced output in my environment.

### Generation (one image, English prompt, blue sphere on white)

```bash
printf 'Use the built-in image generation capability only.\nGenerate a square 1:1 image of a blue sphere on a white background.\nNo text, no logo, no watermark.\n' | codex exec --enable image_generation -
```

In my run, Codex printed the output PNG path after the call. On a few
occasions the file did not appear at the printed path, and
`ls ~/.codex/generated_images/` was where I found it.

(When `image_generation = true` is already set in `config.toml`, the
`--enable image_generation` flag can be dropped.)

### Generation (Japanese prompt)

```bash
printf 'built-in の画像生成機能だけを使ってください。\n正方形 1:1、1024x1024 で、白背景に青い球体を 1 枚描いてください。\n文字、ロゴ、透かしは入れないでください。\n' | codex exec --enable image_generation -
```

Japanese prompts went through in this run. Keeping the same structure
as the English form (built-in capability stated first, "no text / logo
/ watermark" at the end) made later comparison simpler.

### Editing (one input image)

```bash
codex exec --enable image_generation -i ./input.png "Use the built-in image editing capability only. Change the background to white. Keep the subject, composition, and colors intact. No text, no logo, no watermark."
```

`-i ./input.png` attaches the image to edit. Background-replacement
prompts went through on my side.

### Editing (two input images; first as base, second as reference)

```bash
codex exec --enable image_generation -i ./base.png -i ./reference.png "Use the first image as the base. Transfer the palette and mood from the second image while preserving the composition and main subject of the first image. No text, no logo, no watermark."
```

Two `-i` flags put the second image into a reference role. Three or
more input images were not tested in this run.

## About the small helper script I wrote

Once single-image generation was working, I wanted a simple way to run
several jobs from a JSON spec — writing out each call by hand felt
repetitive, and a JSON file looked like a convenient way to manage it.
So I stitched together a small Bash script to try the idea. That is
`codex-image-batch.sh`. **I am not pitching it as a tool.** Use it if
it happens to help; if something else fits your workflow better
(Make / Taskfile, a custom Python driver, parallel execution tools,
existing CI orchestrators), please swap it out freely.

The four commands I used against the script while verifying it:

```bash
# Dependency / Codex-detection diagnostics only; no call to Codex
bash ./codex-image-batch.sh --doctor

# Print prompts and commands for the sample spec; no generation
bash ./codex-image-batch.sh --spec ./examples/codex-image-batch.sample.json --preview

# Actually run the sample spec (a confirmation prompt runs first)
bash ./codex-image-batch.sh --spec ./examples/codex-image-batch.sample.json --pause-at-end

# One job, typed interactively, no JSON file
bash ./codex-image-batch.sh --manual --pause-at-end
```

The JSON input schema (single object / array / `defaults` + `jobs`),
preset list, every flag, and the script's full behavior are all in
[README.en.md](README.en.md).

## Where I looked first when results diverged

Results differed on my side too after environment rebuilds. These are
the places I checked first.

- `codex` not found: nvm initialization was sometimes missing from the
  current shell. Opening a fresh terminal, or confirming that
  `~/.bashrc` sources nvm, usually resolved it for me.
- `image_generation` still listed as disabled: Method A
  (`--enable image_generation` on each call) or Method B
  (`~/.codex/config.toml` with `[features]`) both worked in my
  environment. Newer CLI versions may move the steps around — the
  latest official Codex CLI docs should take precedence.
- `bubblewrap` missing warning: on Ubuntu, `sudo apt install -y
  bubblewrap` added it for me.
- PowerShell rejecting a command: every command here assumes WSL
  Bash. Native Windows PowerShell behavior was not checked in this
  run.

## Closing note

This document captures what I saw on 2026-04-18 in one specific
environment. A mismatch on your side is a useful signal that the
report is already drifting from current reality; keeping your own
notes makes it easier to cross-reference upstream release notes and
community posts later.

Better commands, prompt shapes, and helper-tool designs likely exist.
Please try variations freely — that is the spirit in which this
snapshot is shared.
