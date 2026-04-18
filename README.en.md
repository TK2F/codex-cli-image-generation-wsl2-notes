# Codex CLI Image Generation from WSL2 Ubuntu — Field Test and Batch Runner

This is a single end-to-end document for one question: "Can Codex CLI
really generate and edit images, called from a WSL2 Ubuntu shell on
Windows 11 — and if so, what is the smallest command that works, and
where does a batch runner start to earn its keep?"

It is written to stay fact-based, avoid exaggeration, and separate what
was actually observed from what was inferred. Official documentation is
linked for every non-trivial claim.

> This repository is a **small, hands-on experiment** by TK2LAB and
> Codex. It is not a formal benchmark or an exhaustive survey. Everything
> described here is limited to what actually ran and what was observed.
> Anything outside that envelope is intentionally not asserted, and
> behavior may differ on other environments or as the CLI evolves.

Validated by: TK2LAB and Codex
Validated on: 2026-04-19
CLI: `codex-cli 0.121.0`
Shell: Bash inside WSL2 Ubuntu
Out of scope: native Windows PowerShell execution

---

## Contents

1. [Prerequisites — just the minimum](#prerequisites--just-the-minimum)
2. [30-second summary](#30-second-summary)
3. [Test scope and sample framing](#test-scope-and-sample-framing)
4. [Smallest "does it really work" proof](#smallest-does-it-really-work-proof)
5. [Why the commands use `printf`](#why-the-commands-use-printf)
6. [Japanese and English prompts](#japanese-and-english-prompts)
7. [Aspect ratios in practice](#aspect-ratios-in-practice)
8. [From one image to many — where the runner helps](#from-one-image-to-many--where-the-runner-helps)
9. [doctor → preview → run](#doctor--preview--run)
10. [JSON spec shape](#json-spec-shape)
11. [Built-in presets](#built-in-presets)
12. [Fact check and debunk](#fact-check-and-debunk)
13. [Before you share the output](#before-you-share-the-output)
14. [Option cheat sheet](#option-cheat-sheet)
15. [Common pitfalls](#common-pitfalls)
16. [Official references used](#official-references-used)

---

## Prerequisites — just the minimum

Skip this section if you already use Codex CLI and WSL daily. For everyone
else, a short orientation.

- **What Codex CLI is**: a command-line tool distributed by OpenAI, run as
  `codex`. It has both an interactive mode and non-interactive modes like
  `codex exec`. Official docs: https://developers.openai.com/codex/cli
- **What WSL2 is**: Microsoft's supported way to run Linux on Windows
  10/11. Opening "Ubuntu" from the Start menu opens a Linux terminal
  (i.e., a Bash shell). If you have not installed it yet, the standard
  first-time step is `wsl --install` in an elevated PowerShell.
- **PowerShell and Bash are different shells**: they look similar but
  their syntax and escaping rules differ. All commands in this document
  assume **Bash inside WSL**. Pasting them into Windows PowerShell or
  `cmd.exe` usually will not work as written.
- **Reading the commands**: no leading `$` or shell prompt is shown. Copy
  the block as-is into the Bash terminal and press Enter. Lines starting
  with `#` are comments and do not affect execution.
- **Assumed state**: `codex` is already installed inside the WSL2 Ubuntu
  environment, and you have completed the one-time login and sandbox
  setup. If not, follow the Codex CLI docs linked above first.
- **Safe first steps**: the commands below are ordered from
  zero-side-effect to full execution. When unsure, start with `--doctor`
  and `--preview`. Neither of those generates images.

From here on, the document is the actual record.

---

## 30-second summary

- Image generation and editing both worked from a Bash shell inside WSL2
  Ubuntu using `codex exec`.
- The smallest working generation call is a single line with
  `printf ... | codex exec -`.
- Editing is one line: `codex exec -i ./input.png "..."`. Two reference
  images use two `-i` flags.
- Japanese and English prompts both worked, for both generation and
  editing.
- The practical output sizes are three buckets: **`1024x1024`**,
  **`1024x1536`**, **`1536x1024`**. Arbitrary ratios are requests, not
  guarantees.
- The batch runner starts to pay off once the workflow moves from one
  image to several.
- The Codex CLI docs explicitly state the CLI supports image generation
  and editing ([reference](#official-references-used)).

## Test scope and sample framing

- Platform: Windows 11 + WSL2 + Ubuntu + Bash.
- CLI: `codex-cli 0.121.0`.
- Text-side model flow observed as GPT-5.4-class. I did not directly
  observe which internal image-model alias the CLI selected per request.
- Stable operation confirmed at `1024x1024`, `1024x1536`, and
  `1536x1024`.
- `codex exec` accepted prompts via stdin and as argument strings, for
  both generation and edit flows.
- Output files were observed both in the working directory and under
  `~/.codex/generated_images`.
- No private identifiers (character names, machine names, home paths,
  personal email, API keys, etc.) are carried into this repository.

Not claimed:

- Which image-model alias the CLI used on any given call.
- Behavior on pre-GPT-5.4 model generations.
- That arbitrary size values (e.g., `1408x768`) are honored literally.
- Equivalent behavior on native Windows PowerShell.

## Smallest "does it really work" proof

Three minimal examples, in the order people usually need them.

**Generate one image:**

```bash
printf 'Use the built-in image generation capability only.\nGenerate a square 1:1 image of a blue sphere on a white background.\nNo text, no logo, no watermark.\n' | codex exec -
```

**Edit one image:**

```bash
codex exec -i ./input.png "Use the built-in image editing capability only. Change the background to white. Keep the subject, composition, and colors intact. No text, no logo, no watermark."
```

**Edit using one image as base and another as reference:**

```bash
codex exec -i ./base.png -i ./reference.png "Use the first image as the base. Transfer the palette and mood from the second image while preserving the composition and main subject of the first image. No text, no logo, no watermark."
```

Two short sanity checks worth running before the first real call:

```bash
codex --version
codex features list
```

You want `image_generation` to appear as enabled in the features list.

## Why the commands use `printf`

The one-liners use `printf` on purpose.

- `echo` interprets `\n` differently across shells and builds. `printf`
  is specified by POSIX, so multi-line prompts are portable.
- The trailing `-` in `| codex exec -` is `codex exec`'s explicit signal
  that the prompt comes from stdin. That lets you hand over multi-line
  text cleanly.

Broken down:

```bash
printf 'line1\nline2\nline3\n' | codex exec -
#  ^^^^^^                      ^     ^^^^^^^^^^
#  print multiple lines         pipe   read prompt from stdin
#  with real newlines
```

A form without `-i ./input.png` (the generation example) means "no
attached image, generate from scratch." Adding `-i` switches the call
into edit mode on that attached image.

For longer prompts, a heredoc is equally valid:

```bash
codex exec - <<'EOS'
Use the built-in image generation capability only.
Generate a square 1:1 image of a blue sphere on a white background.
No text, no logo, no watermark.
EOS
```

The single quotes around `'EOS'` disable shell variable expansion and
history expansion inside the prompt body. That matters when the prompt
contains `$`, backticks, or `!`.

## Japanese and English prompts

Both languages worked in practice. All four combinations are covered:

- Generate × English
- Generate × Japanese
- Edit × English
- Edit × Japanese

Japanese generation example:

```bash
printf 'built-in の画像生成機能だけを使ってください。\n正方形 1:1、1024x1024 で、白背景に青い球体を 1 枚描いてください。\n文字、ロゴ、透かしは入れないでください。\n' | codex exec -
```

Japanese edit example:

```bash
codex exec -i ./input.png "built-in の画像編集機能だけを使ってください。背景だけを白に変更し、被写体、構図、色味は維持してください。文字、ロゴ、透かしは加えないでください。"
```

Two practical conventions that survived testing:

- State "use the built-in image generation capability only" (or editing,
  as appropriate). This nudges the CLI away from SVG or HTML substitute
  outputs.
- End with "no text, no logo, no watermark" unless you explicitly want
  any of those. Making this a template closing line avoids repetitive
  follow-up edits.

## Aspect ratios in practice

Three sizes deserve to be treated as first-class:

- `1024x1024` — square
- `1024x1536` — portrait
- `1536x1024` — landscape

Those match the sizes published in the OpenAI image-model docs
([reference](#official-references-used)).

Popular ratios like Instagram Story (9:16), Instagram feed (4:5), and
hero-banner (16:9) were handled most cleanly by accepting that the
underlying model output maps to the three real sizes. The runner's
aspect presets follow that mapping, as shown by `--list-presets`:

| preset            | Treated as                                     |
| ----------------- | ---------------------------------------------- |
| `square`          | 1024x1024                                      |
| `portrait`        | 1024x1536                                      |
| `landscape`       | 1536x1024                                      |
| `instagram_story` | practical portrait, maps toward 1024x1536      |
| `instagram_post`  | practical portrait                             |
| `hero_banner`     | practical landscape, maps toward 1536x1024     |
| `custom`          | any `WIDTHxHEIGHT`, e.g., `1408x768`           |

`custom` is a wish, not a contract. Expect the actual output to gravitate
to a published size.

## From one image to many — where the runner helps

One image does not need a runner. Seven concerns do start to matter once
a workflow involves a handful:

- A visible prompt check before the real call (preview).
- Retrying failed jobs.
- Pause between jobs.
- Mixed Linux / Windows-drive / WSL UNC path handling.
- Recovering the output from `~/.codex/generated_images` when Codex
  does not copy the PNG into the intended directory.
- A per-run summary JSON plus per-job raw logs.
- Not silently overwriting an earlier successful run.

`codex-image-batch.sh` is a small Bash runner that covers exactly those
concerns, with no heavy dependencies — `jq` and `python3` are enough.

## doctor → preview → run

On a new machine, this is the least confusing order:

```bash
bash ./codex-image-batch.sh --doctor
```

`--doctor` reports required commands (`jq`, `python3`, …), whether
`codex` is on `PATH`, whether `~/.nvm/.../bin/codex` exists as a
fallback, and the state of the `image_generation` feature.

If `codex` is not on `PATH`, run the same diagnostics with an explicit
binary path:

```bash
CODEX_BIN="$HOME/.nvm/versions/node/<your-version>/bin/codex" \
  bash ./codex-image-batch.sh --doctor
```

Replace `<your-version>` with the Node version actually installed on your
machine.

```bash
bash ./codex-image-batch.sh --spec ./examples/codex-image-batch.sample.json --preview
```

`--preview` prints the final prompt and the exact `codex exec` command
that would run. It does not call Codex and it does not generate images.

```bash
bash ./codex-image-batch.sh --spec ./examples/codex-image-batch.sample.json --pause-at-end
```

By default the runner asks for confirmation before a real run. Add
`--no-prompt` only when you want to skip that confirmation deliberately.

```bash
bash ./codex-image-batch.sh --manual --pause-at-end
```

Manual mode skips the JSON step and lets you enter one job interactively.

## JSON spec shape

The runner accepts three shapes at the root of the JSON:

- a single job object
- an array of job objects
- an object with `defaults` and `jobs`

The third is the most practical once specs grow.

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

Key points:

- `codex_model` is passed to `codex exec --model` unchanged. The runner
  does not validate the value. Whether a specific model name is accepted
  depends on the Codex CLI and the account at runtime.
- Relative paths are resolved from the **spec file's own location**, not
  from the shell's current directory. This is what lets a spec folder
  move without breaking.
- `mode` is either `generate` or `edit`. For `edit`, supply at least one
  of `input_image` or `input_images`.
- `subject` and `scene` can be written separately, in which case the
  runner composes the prompt with the selected aspect and style. If you
  set `prompt` directly, that takes precedence.

Two samples ship with the package:

- `examples/codex-image-batch.sample.json` — five generation jobs
- `examples/codex-image-edit-batch.sample.json` — three edit jobs

## Built-in presets

Aspect presets are covered above. Style presets are intentionally small:

- `none`
- `watercolor`
- `cinematic`
- `pixel_art`
- `product_render`

Use `--list-presets` for the authoritative current list.

## Fact check and debunk

A few claims that are easy to repeat but do not hold up as-is.

**"Image generation only works in the Codex desktop app."**

Not accurate. The Codex CLI docs explicitly describe image generation
and editing directly in the CLI ([reference](#official-references-used)).
The verification in this repository was done entirely in the CLI.

**"If the CLI says GPT-5.4, GPT-5.4 is producing the PNG."**

Overstated. What was observed was a GPT-5.4-class text model flow on the
CLI side and image generation through Codex's built-in image capability.
OpenAI's product announcement states Codex uses `gpt-image-1.5` for
generation, but the CLI did not expose which image-model alias was used
on any given call during this test.

**"You need to call the OpenAI API directly."**

No. The API is useful, but not required for this workflow. The CLI path
was sufficient for every sample in this repository. The API docs were
used only to anchor which image sizes the underlying models actually
support.

**"Arbitrary requested sizes come back literally."**

That is not what the observations showed. The practical sizes are
`1024x1024`, `1024x1536`, and `1536x1024`.

**"The WSL setup does not matter."**

The Codex sandboxing docs list `bubblewrap` as the recommended
prerequisite on Linux and WSL2. Environments that follow that reduce
ambiguity when something misbehaves, so it is worth getting right
up-front.

**"Older model generations behave the same way."**

This repository does not prove that. The verification is intentionally
scoped to `codex-cli 0.121.0` and the GPT-5.4 era.

## Before you share the output

When forwarding any local experimental output, this checklist helps:

- No absolute personal home paths should remain in prompts, logs, or
  summary files. The runner prefers relative paths where possible.
- No internal product or character names in sample prompts. Generic
  subjects (glass bottle, blue sphere, studio product shot) travel well.
- No host names, Windows user names, personal emails, API keys, tokens,
  or pinned Node version strings should remain in environment notes.
- No output images that were not intended for the recipient. The
  `.gitignore` excludes `examples/outputs/`, `examples/edited-outputs/`,
  and `*.log.txt`.

## Option cheat sheet

- `--spec PATH` — JSON spec path
- `--output-root PATH` — override the output root
- `--codex-bin PATH` — explicit codex executable path (env `CODEX_BIN`
  is also accepted)
- `--ui-mode auto|cli` — input mode selector (default: `auto`)
- `--manual` — skip JSON and enter one job manually
- `--preview` — print prompts and commands without executing Codex
- `--doctor` — environment diagnostics only
- `--list-presets` — print built-in aspect / style presets
- `--no-prompt` — non-interactive mode (requires `--spec` or `--manual`)
- `--stop-on-job-error` — stop the batch on first failed job
- `--overwrite` — overwrite existing output files
- `--pause-at-end` — wait for Enter before exit
- `--inter-job-delay N` — seconds to wait between jobs (default: 2)
- `--generated-image-wait N` — seconds to wait for the
  `~/.codex/generated_images` fallback (default: 5)
- `--retry-count N` — retry count for failed jobs (default: 1)
- `--retry-delay N` — seconds between retries (default: 3)
- `-h`, `--help` — show help

## Common pitfalls

- Running the script in Windows PowerShell instead of WSL Bash. This
  package targets WSL/Linux shells.
- Pasting a folder path where a JSON file is expected. The runner warns.
- Skipping preview on a new spec. `--preview` is a cheap safety net.
- Edit mode without an input image. Edit jobs require at least one.
- Expecting existing PNGs to be replaced automatically. Defaults skip
  existing files. Use `--overwrite` to replace them.
- Assuming Windows-style paths will fail. Common `C:\...` and
  `\\wsl.localhost\...` forms are converted automatically.

## Official references used

- Codex CLI docs
  https://developers.openai.com/codex/cli
- Codex sandboxing and Linux/WSL prerequisites (`bubblewrap`)
  https://developers.openai.com/codex/concepts/sandboxing#prerequisites
- Image generation tool guide
  https://developers.openai.com/api/docs/guides/tools-image-generation
- OpenAI model catalog
  https://developers.openai.com/api/docs/models/all
- GPT Image 1.5 model page
  https://developers.openai.com/api/docs/models/gpt-image-1.5/
- Product announcement: Codex for (almost) everything
  https://openai.com/index/codex-for-almost-everything/
