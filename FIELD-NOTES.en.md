# Field Notes: Codex CLI Image Generation in WSL2 Ubuntu

This document is the publishable record of what was actually tested, what was confirmed, what was not confirmed, and what turned out to be practical in day-to-day use.

It is written for private GitHub publication first, with enough detail to be useful to other people, but without leaking personal paths, machine names, or internal-only notes.

Verified by:

- TK2LAB
- Codex

Tested on:

- 2026-04-19
- `codex-cli 0.121.0`

## Why I Wrote This Down

The interesting part was not that Codex could draw a blue sphere. The interesting part was that the CLI surface was usable as a real image workflow once a few rough edges were understood:

- where the feature gate lives
- how to verify the environment
- how output files are actually written
- how to move from one-off prompts to repeatable batch runs

That is the sort of thing that saves the next person an afternoon.

## Test Scope

I focused on four questions:

1. Can Codex CLI actually generate and edit images in a WSL2 Ubuntu workflow?
2. What needs to be enabled or configured before it works reliably?
3. What is the smallest direct command that still feels practical?
4. What extra tooling is worth adding once one-off commands stop being enough?

## What I Confirmed

- Codex CLI can generate and edit images directly from a WSL2 Ubuntu terminal workflow.
- In this test environment, `codex-cli 0.121.0` reported the `image_generation` feature and accepted direct image-generation flows.
- Direct one-liners using `codex exec -` worked for generation.
- `codex exec -i ...` worked for image editing.
- Japanese prompts and English prompts both worked.
- Practical output sizing clustered around three useful buckets:
  - square
  - portrait
  - landscape
- A lightweight batch runner became worthwhile once the work moved from one image to many.

## Tested Environment

- WSL2
- Ubuntu
- Bash
- Codex CLI `0.121.0`
- CLI-side text model flow observed with GPT-5.4

Anything outside that exact envelope should be treated as possible, not as part of the verified claim.

## What I Did Not Claim

- I did not directly verify which internal image-model alias the CLI selected for each run.
- I did not claim that every arbitrary requested dimension would be honored literally.
- I did not claim that native Windows PowerShell is the best execution surface. For this workflow, WSL was the stable path.
- I did not treat a product announcement as proof of every CLI detail. I used it as context, then checked the local behavior separately.

## Fact Check and Debunk

### “You need the desktop app for image generation.”

Not necessarily.

The official Codex CLI docs explicitly say the CLI can generate or edit images directly in the CLI.

Reference:
- https://developers.openai.com/codex/cli

### “If the model says GPT-5.4, then GPT-5.4 itself is outputting the PNG.”

That is too strong.

What I observed was:

- Codex CLI was running with a GPT-5.4-class text model in the CLI
- image generation happened through Codex’s built-in image generation capability

OpenAI’s product announcement says Codex can use `gpt-image-1.5` for image generation and iteration, but the CLI did not expose the exact internal image-model alias during my tests.

References:
- https://openai.com/index/codex-for-almost-everything/
- https://developers.openai.com/codex/cli

### “You must use the API directly.”

No.

The API is useful, but not required for this workflow. The CLI path is real and useful on its own. The API docs were still valuable because they helped anchor what image generation models and practical image sizes exist on the OpenAI side.

Reference:
- https://developers.openai.com/api/docs/guides/tools-image-generation
- https://developers.openai.com/api/docs/models/all

### “Any requested size works exactly as written.”

No.

In practice, the useful mental model was three buckets:

- `1024x1024`
- `1024x1536`
- `1536x1024`

That lines up with the published image-model size options shown in OpenAI’s model docs.

References:
- https://developers.openai.com/api/docs/models/gpt-image-1.5/
- https://developers.openai.com/api/docs/models/gpt-image-1

### “WSL setup details do not matter.”

They do.

The official sandboxing docs note that on Linux and WSL2, `bubblewrap` is the recommended prerequisite. In practice, environment quality does affect how smooth the workflow feels.

Reference:
- https://developers.openai.com/codex/concepts/sandboxing#prerequisites

### “Models older than GPT-5.4 should be assumed to work the same way.”

I would not publish that as a fact.

This record is intentionally scoped to a GPT-5.4-era Codex CLI workflow in WSL2 Ubuntu. I did not validate earlier model combinations here, so this package should not be read as evidence that pre-GPT-5.4 behavior is the same.

## The Commands That Mattered Most

### Basic direct generation

```bash
printf 'Use the built-in image generation capability only.\nGenerate a square 1:1 image of a blue sphere on a white background.\nNo text, no logo, no watermark.\n' | codex exec -
```

### Basic direct editing

```bash
codex exec -i ./input.png "Use the built-in image editing capability only. Change the background to white. Keep the subject, composition, and colors intact. No text, no logo, no watermark."
```

### Direct editing with two references

```bash
codex exec -i ./base.png -i ./reference.png "Use the first image as the base. Transfer the palette and mood from the second image while preserving the composition and main subject of the first image. No text, no logo, no watermark."
```

### Safer first step before real work

```bash
codex --version
codex features list
```

## What Graduated From “Nice to Have” to “Worth Keeping”

Once I moved past one-offs, these became worth keeping:

- JSON specs for repeatable prompts
- a preview mode before real runs
- retries
- delay between jobs
- path normalization for mixed Windows/WSL usage
- summary JSON and per-job raw logs

That is why the share package includes both direct-usage notes and a runner.

## Security and Privacy Review

The package was prepared for publication so that the useful parts of the workflow remained, while private or irrelevant local details were not carried forward into the shared material.

## Practical Recommendation

If you are checking this workflow for the first time:

1. Run `--doctor`
2. Run `--preview`
3. Try one direct one-liner
4. Then move to JSON and the runner if you actually need repeatability

That order gives the most signal with the least confusion.

## Official References I Actually Used

- Codex CLI docs  
  https://developers.openai.com/codex/cli
- Codex sandboxing and WSL/Linux prerequisites  
  https://developers.openai.com/codex/concepts/sandboxing#prerequisites
- Image generation tool guide  
  https://developers.openai.com/api/docs/guides/tools-image-generation
- OpenAI model catalog  
  https://developers.openai.com/api/docs/models/all
- GPT Image 1.5 model page  
  https://developers.openai.com/api/docs/models/gpt-image-1.5/
- Product announcement: Codex for (almost) everything  
  https://openai.com/index/codex-for-almost-everything/
