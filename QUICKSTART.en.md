# Quickstart — Try Codex Image Generation from WSL2 on Windows 11

This guide is for the reader who has **never touched Codex or WSL2 before,
and just wants to get one image out today**. The whole thing is designed
to fit into about 10–20 minutes.

For the full report — environment versions with check commands, the
observations in detail, a review of common claims against what was seen
here, and the runner reference — see [README.en.md](README.en.md).

> This quickstart walks the same steps we ran during the field report:
> Windows 11 + WSL2 + Ubuntu + Bash + `codex-cli 0.121.0`. Everything
> below is a copy of what we did, not a recommended procedure. If your
> environment differs, adapt the steps and see
> [README.en.md](README.en.md#environment-versions-and-how-to-check-them)
> for the commands that read your own versions.

---

## 0. What this guide assumes

- **OS**: Windows 11 was used in this write-up. Windows 10 with WSL2
  available is likely to behave similarly, but that combination was
  not tested here.
- **Account**: An OpenAI / ChatGPT account that is allowed to use Codex.
  A browser-based authorization is part of the first login.
- **Network**: Internet access is needed during install and the first
  login.
- **Disk**: A few gigabytes free for Ubuntu and Node.
- **Where to type**: Every command below goes into the **WSL Ubuntu
  Bash shell**, not Windows PowerShell. Copy the block and press Enter;
  no leading `$` is shown.
- **Version check**: The exact versions used in the field report, and
  the commands that print yours, are in
  [README.en.md](README.en.md#environment-versions-and-how-to-check-them).

## 1. Install WSL2 + Ubuntu

If you already have Ubuntu running in WSL, skip this step.

Open **PowerShell as administrator** from the Start menu and run the
one-time command:

```powershell
wsl --install
```

Reboot when asked, then open **Ubuntu** from the Start menu. On first
launch it asks you to create a Linux username and password. From here on,
every command goes into this Ubuntu terminal.

Official docs: https://learn.microsoft.com/windows/wsl/install

## 2. Install base packages and Node.js

In the Ubuntu terminal, install the basics. You may be prompted for your
`sudo` password.

```bash
sudo apt update
sudo apt install -y curl git jq python3 bubblewrap
```

`bubblewrap` is listed as the prerequisite for Codex's sandbox on Linux
and WSL2 in the official documentation
(https://developers.openai.com/codex/concepts/sandboxing#prerequisites).

Install Node.js via nvm, which keeps versions simple.

```bash
curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm install --lts
node --version
```

A `v...` line from `node --version` means you are good to go.

## 3. Install Codex CLI and sign in

Package names and distribution channels change over time, so follow the
official install steps: https://developers.openai.com/codex/cli

When it is installed, confirm the CLI is reachable:

```bash
codex --version
codex features list
```

In this run, `codex --version` printed `codex-cli 0.121.0`, and
`codex features list` included `image_generation` as an enabled feature.
That was the baseline used before moving on. If your output differs,
consult the Codex CLI docs linked above before continuing.

The very first `codex` invocation may open a browser window for OpenAI
account authorization. Complete the flow in Windows, come back to the
Ubuntu terminal, and it continues.

If `image_generation` shows as disabled, two paths were observed during
this write-up. Either may work for you; try the one that fits your
setup:

- Run `codex` once interactively and ask for a simple image. In this
  run, the feature activated after that first invocation.
- Or add it to `~/.codex/config.toml` by hand:

  ```toml
  [features]
  image_generation = true
  ```

The bundled runner also passes `--enable image_generation` per call, so
even if the feature is not globally on, the runner will still try.

## 4. Generate your first image (one-liner)

Here is the smallest command that uses Codex CLI directly. It works from
any directory — `~` is fine.

```bash
printf 'Use the built-in image generation capability only.\nGenerate a square 1:1 image of a blue sphere on a white background.\nNo text, no logo, no watermark.\n' | codex exec -
```

On success, the command prints an output path. If Codex did not copy the
PNG into the current directory, look under `~/.codex/generated_images/`.

Japanese prompts work too:

```bash
printf 'built-in の画像生成機能だけを使ってください。\n正方形 1:1、1024x1024 で、白背景に青い球体を 1 枚描いてください。\n文字、ロゴ、透かしは入れないでください。\n' | codex exec -
```

## 5. Edit an existing image

Put a PNG in the current directory and try the minimal edit:

```bash
codex exec -i ./input.png "Use the built-in image editing capability only. Change the background to white. Keep the subject, composition, and colors intact. No text, no logo, no watermark."
```

Two images (first as base, second as reference) use two `-i` flags:

```bash
codex exec -i ./base.png -i ./reference.png "Use the first image as the base. Transfer the palette and mood from the second image while preserving the composition and main subject of the first image. No text, no logo, no watermark."
```

## 6. Use the bundled runner

Once you need more than one image, the bundled script starts to earn its
keep. Clone or download this repository into your WSL home, then run from
the repository root:

```bash
bash ./codex-image-batch.sh --doctor
```

If `codex` is not on `PATH`, point to the binary explicitly:

```bash
CODEX_BIN="$HOME/.nvm/versions/node/<your-version>/bin/codex" \
  bash ./codex-image-batch.sh --doctor
```

Preview the included sample batch (no images are generated yet):

```bash
bash ./codex-image-batch.sh --spec ./examples/codex-image-batch.sample.json --preview
```

Run it for real, with a confirmation prompt in front:

```bash
bash ./codex-image-batch.sh --spec ./examples/codex-image-batch.sample.json --pause-at-end
```

Try one job interactively without JSON:

```bash
bash ./codex-image-batch.sh --manual --pause-at-end
```

## 7. When something does not work

- **`codex: command not found`**
  The shell may not have loaded nvm yet. Open a fresh terminal, or run:
  ```bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  ```
- **`image_generation` is never enabled**
  Try running `codex` interactively once and asking for a small image. If
  it is still off, set it in `~/.codex/config.toml` under `[features]`,
  and rerun `bash ./codex-image-batch.sh --doctor`.
- **A `bubblewrap` warning**
  `sudo apt install -y bubblewrap`, then open a new terminal.
- **PowerShell rejects the command**
  This guide targets the WSL Ubuntu Bash shell. Open Ubuntu from the
  Start menu.

## 8. Next steps

- For the full picture — scope, JSON spec shape, observed aspect-ratio
  behavior, presets, a review of common claims against the observations
  here, and references — see [README.en.md](README.en.md).
- Copy one of the files in `examples/` and edit the prompts to match
  what you actually want to produce.
- Before sharing any output, remove absolute personal paths and any
  internal names from logs and summaries.
