# Direct Usage Guide

This guide is for people who want to understand or use Codex image generation directly, even without the batch runner.

## What To Check Before Anything Else

Run these commands first:

```bash
codex --version
codex features list
```

If you are on WSL or Linux and Codex warns about sandbox prerequisites, check whether `bubblewrap` is installed:

```bash
command -v bwrap || command -v bubblewrap
```

## Preferred Way To Enable Image Generation

The easiest method is:

```bash
codex features enable image_generation
```

Then verify:

```bash
codex features list | grep '^image_generation'
```

## Manual Config File Method

Codex stores local defaults in:

```text
~/.codex/config.toml
```

If you need to edit the config file manually, ensure it contains:

```toml
[features]
image_generation = true
```

If the file already contains a `[features]` section, merge the key instead of creating duplicate sections.

## Basic Interactive Usage

Start Codex interactively:

```bash
codex
```

Then type a prompt such as:

```text
Use the built-in image generation capability only.
Generate a square 1:1 image of a blue sphere on a white background.
No text, no logo, no watermark.
```

## Basic Non-Interactive Usage

One-line generation:

```bash
printf 'Use the built-in image generation capability only.\nGenerate a square 1:1 image of a blue sphere on a white background.\nNo text, no logo, no watermark.\n' | codex exec -
```

One-line editing with one input image:

```bash
codex exec -i ./input.png "Use the built-in image editing capability only. Change the background to white. Keep the subject, composition, and colors intact. No text, no logo, no watermark."
```

One-line editing with two input images:

```bash
codex exec -i ./base.png -i ./reference.png "Use the first image as the base. Transfer the palette and mood from the second image while preserving the composition and main subject of the first image. No text, no logo, no watermark."
```

## Why The Runner Exists If Direct Commands Already Work

The runner adds operational guardrails:

- environment diagnostics
- preview before execution
- retries
- delay between jobs
- path normalization
- structured JSON input
- summary and raw logs

If you only need one image once, direct commands are enough.
If you need repeatability or want to hand the workflow to someone else, the runner is safer.

## Validation Flow Used For This Package

The share package was checked in this order:

1. Syntax check for the runner
2. `--help` output
3. `--list-presets` output
4. `--doctor` output
5. Preview run against the sample JSON
6. Windows-path to WSL-path normalization
7. Sanitization review for private paths and personal identifiers

## References

- Codex CLI docs: https://developers.openai.com/codex/cli
- Codex sandboxing and Linux/WSL `bubblewrap` prerequisites: https://developers.openai.com/codex/concepts/sandboxing#prerequisites
- OpenAI image generation tool guide: https://developers.openai.com/api/docs/guides/tools-image-generation
- OpenAI models catalog: https://developers.openai.com/api/docs/models/all
