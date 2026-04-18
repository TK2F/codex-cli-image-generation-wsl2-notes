# Codex CLI Image Generation from WSL2 Ubuntu — Personal Notes (as of 2026-04-18)

This is the memo I kept while TK2LAB and Codex were checking whether
`codex` could really be driven for image generation and editing from a
WSL2 Ubuntu Bash shell on Windows 11. Output did come through, so the
private notes I was keeping for myself have been tidied up and shared
here for anyone curious about the same question.

The document walks, in the order I ran them, through the smallest
working commands, whether Japanese and English prompts both went
through, which aspect ratios produced output, how `image_generation`
looked on first install, and where a small JSON-driven helper script
started to earn its keep.

> This is a personal memo captured on 2026-04-18 by one person plus
> Codex. It is not a recommendation of the exact commands or steps.
> Codex CLI evolves quickly; future releases, behavior changes, new
> findings, or official announcements may render parts of this report
> outdated or incorrect. **Treat it as a single reference point in
> time.** I may not be able to respond to questions or diffs about
> this snapshot in a timely manner, so please verify against upstream
> documentation and feel free to explore better commands, flags, and
> tooling on your side — that exploration is the intended spirit of
> this share.

**Date of observation:** 2026-04-18
**Observers:** TK2LAB and Codex (on the CLI side)
**Host OS:** Windows 11
**Runtime:** Ubuntu on WSL2
**Shell:** Bash (native Windows PowerShell execution is out of scope)
**Codex CLI:** `codex-cli 0.121.0`

For the other packages, runtimes, and libraries, see the
[Environment versions and how to check them](#environment-versions-and-how-to-check-them)
section below.

---

## Contents

1. [Prerequisites — just the minimum](#prerequisites--just-the-minimum)
2. [30-second summary](#30-second-summary)
3. [Environment versions and how to check them](#environment-versions-and-how-to-check-them)
4. [Scope and what is not asserted](#scope-and-what-is-not-asserted)
5. [`image_generation` looked disabled by default — two ways I got it working](#image_generation-looked-disabled-by-default--two-ways-i-got-it-working)
6. [The smallest commands that worked in this run](#the-smallest-commands-that-worked-in-this-run)
7. [Why the commands use `printf`](#why-the-commands-use-printf)
8. [Japanese and English prompts](#japanese-and-english-prompts)
9. [Aspect ratios in practice](#aspect-ratios-in-practice)
10. [From one image to many — the small helper script I wrote](#from-one-image-to-many--the-small-helper-script-i-wrote)
11. [doctor → preview → run (the order I used)](#doctor--preview--run-the-order-i-used)
12. [JSON spec shape](#json-spec-shape)
13. [Built-in presets](#built-in-presets)
14. [Common claims vs. what was observed here](#common-claims-vs-what-was-observed-here)
15. [Before you share the output](#before-you-share-the-output)
16. [Option cheat sheet](#option-cheat-sheet)
17. [Mistakes I noticed during the work](#mistakes-i-noticed-during-the-work)
18. [Official references used](#official-references-used)

---

## Prerequisites — just the minimum

This report is written for readers with minimum familiarity with Codex
CLI and WSL2, attempting to reproduce the observations below. It is
not an introductory tutorial; the upstream projects document their
own installation procedures far better than a short restatement here.

- **Codex CLI** — OpenAI's command-line tool. The commands in this
  document center on `codex exec`.
  Reference: https://developers.openai.com/codex/cli
- **WSL2** — Microsoft's supported way to run Linux on Windows. This
  report ran inside WSL2 Ubuntu with Bash.
  Reference: https://learn.microsoft.com/windows/wsl/install
- **PowerShell and Bash are different shells** — escaping and pipe
  semantics differ. The commands below assume Bash inside WSL. Native
  Windows PowerShell behavior is out of scope for this report.
- **Reading the commands** — code blocks are shown without a leading
  `$` or shell prompt, so they can be copied as-is into the Bash
  terminal.
- **Assumed state** — `codex` is already installed inside the WSL2
  Ubuntu environment, and the one-time login and sandbox setup have
  been completed.
- **Side-effect ordering** — commands are arranged left-to-right by
  increasing side effect. `--doctor` and `--preview` neither call
  Codex nor generate images.

From here on, the document records commands that were actually run and
what was observed when they were run. Comparing your own run against
the same commands is where the report earns its usefulness.

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
- Output sizes observed here fell into three concrete values:
  **`1024x1024`**, **`1024x1536`**, **`1536x1024`**. Arbitrary ratios
  are requests to the model, not guarantees.
- A small helper script for JSON-driven batching started to earn its
  keep once the workflow moved from one image to several.
- The Codex CLI docs explicitly state the CLI supports image generation
  and editing ([reference](#official-references-used)).

## Environment versions and how to check them

To keep "your mileage may vary" from being an easy excuse, here are the
versions observed during this run and the exact commands that produce
them. Values marked `—` were not captured during this report and can be
filled in by running the listed command on your machine.

| Item | This run | How to check |
| --- | --- | --- |
| Windows | Windows 11 | PowerShell: `winver`, or `Get-ComputerInfo \| Select-Object WindowsProductName, WindowsVersion, OsBuildNumber` |
| PowerShell | — | PowerShell: `$PSVersionTable.PSVersion` |
| WSL | WSL2 | PowerShell: `wsl --version`, or `wsl --status` |
| Ubuntu distribution | Ubuntu (LTS) | Bash: `cat /etc/os-release`, or `lsb_release -a` |
| Kernel | — | Bash: `uname -r` |
| Bash | — | Bash: `bash --version` |
| Codex CLI | `codex-cli 0.121.0` | Bash: `codex --version` |
| Codex feature state | `image_generation` enabled | Bash: `codex features list` |
| Node.js | — (LTS via nvm) | Bash: `node --version` |
| npm | — | Bash: `npm --version` |
| nvm | — | Bash: `nvm --version` |
| jq | — | Bash: `jq --version` |
| python3 | — | Bash: `python3 --version` |
| bubblewrap | — | Bash: `bwrap --version` |

To collect the WSL-side values in one pass, this snippet is convenient:

```bash
{
  printf '# Environment snapshot (%s)\n' "$(date -Iseconds)"
  echo "## From PowerShell, run separately:"
  echo "  winver ; Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsBuildNumber ; \$PSVersionTable.PSVersion ; wsl --version"
  echo
  echo "## WSL / Bash"
  printf 'uname -a: %s\n' "$(uname -a)"
  printf 'bash: %s\n' "$BASH_VERSION"
  cat /etc/os-release 2>/dev/null | grep -E '^(NAME|VERSION)='
  printf 'codex: %s\n' "$(codex --version 2>/dev/null || echo 'not found')"
  printf 'node: %s\n' "$(node --version 2>/dev/null || echo 'not found')"
  printf 'npm: %s\n' "$(npm --version 2>/dev/null || echo 'not found')"
  printf 'jq: %s\n' "$(jq --version 2>/dev/null || echo 'not found')"
  printf 'python3: %s\n' "$(python3 --version 2>/dev/null || echo 'not found')"
  printf 'bwrap: %s\n' "$(bwrap --version 2>/dev/null || echo 'not found')"
}
```

PowerShell and Windows build numbers cannot be read from WSL directly,
so run these on the Windows side:

```powershell
Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsBuildNumber
$PSVersionTable.PSVersion
```

## Scope and what is not asserted

The observations cover only the environment listed above. For anything
outside that envelope, this report stays silent rather than generalizing.

- Stable operation confirmed at `1024x1024`, `1024x1536`, and
  `1536x1024`.
- `codex exec` accepted prompts via stdin and as argument strings, for
  both generation and edit flows.
- Output files appeared both in the current directory and under
  `~/.codex/generated_images`.
- The text-side model flow was observed as GPT-5.4-class. Which
  image-model alias the CLI selected per call was not directly
  observable from the CLI surface in this run.
- No private identifiers (character names, machine names, home paths,
  personal email, API keys, pinned Node version strings) are carried
  into this repository.

Not asserted:

- The specific image-model alias used on any given call.
- Behavior on pre-GPT-5.4 model generations.
- That arbitrary sizes such as `1408x768` are honored literally.
- Equivalent behavior on native Windows PowerShell.

## `image_generation` looked disabled by default — two ways I got it working

On a fresh install in my environment, `codex features list` showed
`image_generation` as disabled (`false`). This was what I saw on my
machine rather than a claim about the canonical default. Two methods
let me run image generation end-to-end. Both produced output, and
portrait, landscape, and 1:1 sizes all came through.

**Method A: pass `--enable image_generation` on each `codex exec` call**

```bash
codex exec --enable image_generation -
```

Adding the flag was enough to run image generation in my run. The
bundled `codex-image-batch.sh` follows the same approach: when the
feature is not already enabled, the script adds `--enable
image_generation` to each call.

**Method B: set it in `~/.codex/config.toml`**

```toml
[features]
image_generation = true
```

With those two lines in place, interactive `codex` and `codex exec`
both produced images in my environment without the flag. For
continuous use, the config-file path felt less fiddly.

New CLI versions may change defaults or the enablement path, so when
installing a fresh version it is worth checking `codex features list`
first and deferring to the official Codex CLI documentation.

## The smallest commands that worked in this run

Three one-liners, in the order they were run, each recorded verbatim
for reproduction. Running the same commands on your side and comparing
output is the primary intended use of this section.

The commands below include `--enable image_generation`, reflecting the
`false`-by-default state I observed. If you already set
`image_generation = true` in `~/.codex/config.toml` (Method B above),
the flag can be dropped.

**Generate one image:**

```bash
printf 'Use the built-in image generation capability only.\nGenerate a square 1:1 image of a blue sphere on a white background.\nNo text, no logo, no watermark.\n' | codex exec --enable image_generation -
```

**Edit one image:**

```bash
codex exec --enable image_generation -i ./input.png "Use the built-in image editing capability only. Change the background to white. Keep the subject, composition, and colors intact. No text, no logo, no watermark."
```

**Edit using one image as base and another as reference:**

```bash
codex exec --enable image_generation -i ./base.png -i ./reference.png "Use the first image as the base. Transfer the palette and mood from the second image while preserving the composition and main subject of the first image. No text, no logo, no watermark."
```

Two short sanity checks I ran before the first real call:

```bash
codex --version
codex features list
```

In this run, `codex --version` printed `codex-cli 0.121.0`, and
`codex features list` showed `image_generation` as `false` — which is
why the three commands above add `--enable image_generation`. If you
already set it in `config.toml` (Method B), the flag is redundant.

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

Two small conventions that seemed to stabilize output in this run.
They are not required, and readers may want to confirm in their own
prompts.

- Stating "use the built-in image generation capability only" (or
  editing, as appropriate) up front. Without it, some runs drifted
  toward SVG or HTML substitutes.
- Closing with "no text, no logo, no watermark" by default. When that
  closing line was present, post-processing edits were rarer in this
  run.

## Aspect ratios in practice

In this run, three output sizes appeared consistently:

- `1024x1024` — square
- `1024x1536` — portrait
- `1536x1024` — landscape

Those match the sizes published in the OpenAI image-model docs
([reference](#official-references-used)).

Popular ratios like Instagram Story (9:16), Instagram feed (4:5), and
hero-banner (16:9) were handled most cleanly by accepting that the
underlying model output maps to the three real sizes. The helper script's
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

## From one image to many — the small helper script I wrote

After the single-image path was working, I wanted to run several jobs
in a row. Writing out the prompt and `-i` flags command by command
felt tedious, and a JSON file looked like a convenient way to manage
the work. So I thought "let me try stitching it together" and put
together a small Bash script. That became `codex-image-batch.sh`.

**I am not pitching it as a tool.** It is what I ended up with while
doing this check; use it if it happens to be useful, and replace it
freely if something else fits your work better — Make / Taskfile,
a custom Python driver, parallel execution tools, an existing CI
orchestrator, and so on. This script works as either a starting point
or a counter-example, whichever is more helpful.

Seven small conveniences ended up in the script as a natural
consequence of running several jobs in sequence:

- A visible prompt check before the real call (preview mode).
- Automatic retry of failed jobs.
- A small delay between jobs.
- Normalizing mixed Linux / Windows-drive / WSL UNC paths.
- Recovering output from `~/.codex/generated_images` when Codex did
  not copy the PNG into the intended directory.
- A per-run summary JSON alongside per-job raw logs.
- Skipping existing outputs unless explicitly asked to overwrite.

The script is a single Bash file with only `jq` and `python3` as
external dependencies, short enough to read through end to end.

## doctor → preview → run (the order I used)

The sequence I followed while verifying the script. It is a record
of what I ran, not a prescribed procedure — the helper script does
not require this order.

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

By default the helper script asks for confirmation before a real run. Add
`--no-prompt` only when you want to skip that confirmation deliberately.

```bash
bash ./codex-image-batch.sh --manual --pause-at-end
```

Manual mode skips the JSON step and lets you enter one job interactively.

## JSON spec shape

The helper script accepts three shapes at the root of the JSON:

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

- `codex_model` is passed to `codex exec --model` unchanged. The helper script
  does not validate the value. Whether a specific model name is accepted
  depends on the Codex CLI and the account at runtime.
- Relative paths are resolved from the **spec file's own location**, not
  from the shell's current directory. This is what lets a spec folder
  move without breaking.
- `mode` is either `generate` or `edit`. For `edit`, supply at least one
  of `input_image` or `input_images`.
- `subject` and `scene` can be written separately, in which case the
  helper script composes the prompt with the selected aspect and style. If you
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

## Common claims vs. what was observed here

Several claims about Codex CLI image generation circulate online. Below
is how each one held up during this specific run, together with the
relevant official documentation. These are observations from one
environment, and other runs may produce different results.

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

That is not what the observations showed in this run. The output sizes
seen here were `1024x1024`, `1024x1536`, and `1536x1024`.

**"The WSL setup does not matter."**

The Codex sandboxing docs list `bubblewrap` as the recommended
prerequisite on Linux and WSL2. Environments that follow that reduce
ambiguity when something misbehaves, so it is worth getting right
up-front.

**"Older model generations behave the same way."**

This repository does not prove that. The verification is intentionally
scoped to `codex-cli 0.121.0` and the GPT-5.4 era.

## Before you share the output

Sharing experimental output cleanly was part of this project. The
checklist below is the one this report was run through before the
repository was pushed; it may also be useful for other work that
touches prompts, logs, or generated images.

- Absolute personal home paths, removed from prompts, logs, and
  summary files. The helper script writes relative paths where possible; input
  image names and prompt text were corrected by hand.
- Internal product or character names, replaced with generic subjects
  in sample prompts (glass bottle, blue sphere, studio product shot).
- Host names, Windows user names, personal emails, API keys, tokens,
  and pinned Node version strings, scrubbed from environment notes.
- Output images not intended for the audience, excluded. The
  `.gitignore` already excludes `examples/outputs/`,
  `examples/edited-outputs/`, `*.log.txt`, and `codex-image-batch-run-*.json`.

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

## Mistakes I noticed during the work

Observations, not warnings. These are missteps I either made myself or
heard about repeatedly. Shared as part of the reproduction record.

- Running the script in Windows PowerShell instead of WSL Bash. The
  commands here were written for WSL/Linux shells.
- Pasting a folder path where a JSON file is expected. The helper script
  warns when it sees a directory.
- Running a new spec without `--preview` first. Preview has no side
  effect and makes prompt / command inspection trivial.
- Running edit mode without any input image. At least one `-i` path
  is required.
- Assuming existing PNGs would be replaced silently. In my run,
  existing outputs were skipped unless `--overwrite` was passed.
- Assuming Windows-style paths would fail. In practice, common
  `C:\...` and `\\wsl.localhost\...` forms were normalized by the
  helper script during this test.

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
