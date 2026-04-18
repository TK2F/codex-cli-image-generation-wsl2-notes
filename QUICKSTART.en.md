# Reproduction Quickstart — The Commands I Actually Ran

This document is a trimmed-down list of the exact commands TK2LAB and
Codex typed while checking how far Codex CLI image generation and
editing work. **It is not an introductory tutorial and not a
recommended procedure.** Use it as a reproduction checklist to see
whether the same commands produce the same results in your environment.

> Rather than "do X and you will get Y", the framing here is "when I
> ran this, the result was this." Please try the same commands on
> your side and compare.

For the longer write-up — observations, version tables, aspect-ratio
behavior, runner options, and a review of common claims against what
was observed here — see [README.en.md](README.en.md).

---

## The environment assumed behind every command below

All of the commands below were recorded in this stack. Different
environments do not invalidate them, but the version table is the
first thing to compare when results diverge.

- **Host OS**: Windows 11
- **Runtime**: Ubuntu on WSL2 (LTS)
- **Shell**: Bash
- **Codex CLI**: `codex-cli 0.121.0`
- **Codex feature state**: `image_generation` listed as enabled by
  `codex features list`

The concrete versions observed for Node.js, npm, jq, python3,
bubblewrap, and related tools, plus the commands that read yours, live
in [README.en.md — Environment versions and how to check them](README.en.md#environment-versions-and-how-to-check-them).

## Environment setup, as a flow summary with official links

Rather than re-documenting installation steps that the upstream
projects already describe well, here is the flow I followed with
links to the authoritative sources.

1. **Windows 11 + WSL2 + Ubuntu**
   Use the Microsoft-supplied procedure. The common flow is
   `wsl --install` from an elevated PowerShell.
   Reference: https://learn.microsoft.com/windows/wsl/install
2. **Basic Linux packages**
   I ensured `jq`, `python3`, `bubblewrap`, `curl`, and `git` were
   available inside the Ubuntu shell. `bubblewrap` is listed in the
   Codex sandbox documentation as the prerequisite on Linux/WSL2.
   Reference: https://developers.openai.com/codex/concepts/sandboxing#prerequisites
3. **Node.js**
   I installed the LTS line through nvm. Any Node installation that
   places `codex` on `PATH` after CLI install works for the same
   purpose.
   Reference: https://nodejs.org/
4. **Codex CLI install and first login**
   The authoritative install, login (browser authorization), and
   feature-enablement instructions come from OpenAI directly.
   Reference: https://developers.openai.com/codex/cli

After completing these, `codex --version` and `codex features list`
both had output in my shell. My values were `codex-cli 0.121.0` and
`image_generation` shown as enabled. If yours differ, that is the
first place to look when comparing results.

## The commands I ran, in order

These are the minimal one-line forms I used while recording the
results. None of them assume the runner is installed.

### Generation (one image, English prompt, blue sphere on white)

```bash
printf 'Use the built-in image generation capability only.\nGenerate a square 1:1 image of a blue sphere on a white background.\nNo text, no logo, no watermark.\n' | codex exec -
```

In my run, Codex printed the output path after the call. When the
file did not appear at the printed path, `ls ~/.codex/generated_images/`
was where I found it on several occasions.

### Generation (Japanese prompt)

```bash
printf 'built-in の画像生成機能だけを使ってください。\n正方形 1:1、1024x1024 で、白背景に青い球体を 1 枚描いてください。\n文字、ロゴ、透かしは入れないでください。\n' | codex exec -
```

Japanese prompts went through in this run. I kept the same structure
as the English form (state the built-in capability up front, close
with "no text, no logo, no watermark") so later comparisons would be
cleaner.

### Editing (one input image)

```bash
codex exec -i ./input.png "Use the built-in image editing capability only. Change the background to white. Keep the subject, composition, and colors intact. No text, no logo, no watermark."
```

Attach the image to edit with `-i ./input.png`. Background-replacement
instructions went through for me.

### Editing (two input images; first as base, second as reference)

```bash
codex exec -i ./base.png -i ./reference.png "Use the first image as the base. Transfer the palette and mood from the second image while preserving the composition and main subject of the first image. No text, no logo, no watermark."
```

Two `-i` flags put the second image into a reference role. I did not
test three or more images in this run.

## About the small helper script I wrote

Once the single-image case was working, I wanted a compact way to run
several jobs from JSON — not because a runner is necessary, but
because it was convenient for the checks I was doing. That became
`codex-image-batch.sh`. **It is not a recommended tool.** It is a
personal-convenience script shared in the spirit of "here is what I
ended up using; better options almost certainly exist." Parallel
execution, Make / Taskfile, custom Python drivers, and other
approaches would all fit the same need.

The four commands I used against the runner while verifying it:

```bash
# Dependency / Codex-detection diagnostics only (no call to Codex)
bash ./codex-image-batch.sh --doctor

# Print prompts and commands for the sample spec; no generation
bash ./codex-image-batch.sh --spec ./examples/codex-image-batch.sample.json --preview

# Actually run the sample spec (a confirmation prompt runs first)
bash ./codex-image-batch.sh --spec ./examples/codex-image-batch.sample.json --pause-at-end

# One job, interactively typed, no JSON file
bash ./codex-image-batch.sh --manual --pause-at-end
```

The JSON input schema (single object / array / `defaults` + `jobs`),
the presets, every flag, and the runner behavior are all in
[README.en.md](README.en.md).

## When results do not match

Diverging results happened on my side too, usually after rebuilding
the environment. These are the places I looked first.

- `codex` not found: nvm initialization may not have been applied to
  the current shell. A fresh terminal, or checking that `~/.bashrc`
  sources nvm, usually resolved it here.
- `image_generation` listed as disabled: in my run, the feature shifted
  to enabled after I started `codex` interactively once and asked for
  a small image. This is an observation from my environment, not a
  documented behavior of the CLI, so defer to the official Codex CLI
  docs if they describe a canonical path. A config-file alternative is
  mentioned in [README.en.md](README.en.md).
- `bubblewrap` warning: `sudo apt install -y bubblewrap` added it on
  Ubuntu for me.
- PowerShell rejecting a command: the commands here assume WSL Bash.
  Native Windows PowerShell behavior is outside the scope of this
  report.

## What I would suggest trying from here

- If the same commands produce different results on your machine,
  that is a more useful datapoint than anything in this repository.
  Sharing the diff (issue, message, note) makes this report stronger.
- Copying one of the sample files under `examples/` and replacing
  only the prompts was the lightest way to move from "it runs" to
  "it produces something I actually want."
- Running the same experiment on a different distribution, model
  selection, or size goes past what this report covers. Treat those
  runs as your own observations rather than confirmations of mine.
