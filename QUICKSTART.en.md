# Quickstart — Try Codex Image Generation from WSL2 on Windows 11

This guide is for the reader who has **never touched Codex or WSL2 before,
and just wants to get one image out today**. The whole thing is designed
to fit into about 10–20 minutes.

For the full detail, the verification notes, the debunked assumptions, and
the runner options, read [README.en.md](README.en.md) afterwards.

> A small but important note: this repository is a hands-on experiment
> by TK2LAB and Codex, not a formal benchmark. Everything below worked in
> the setup we tried. If your environment differs, expect to adjust.

---

## 0. What this guide assumes

- **OS**: Windows 11 (Windows 10 also works if WSL2 is available).
- **Account**: An OpenAI / ChatGPT account that is allowed to use Codex.
  A browser-based authorization is part of the first login.
- **Network**: You need internet during install and the first login.
- **Disk**: A few gigabytes free for Ubuntu and Node.
- **Where to type**: Every command below goes into the **WSL Ubuntu
  Bash shell**, not Windows PowerShell. Copy the block and press Enter;
  no leading `$` is shown.

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

`bubblewrap` is the recommended prerequisite for Codex's sandbox on Linux
and WSL2 (official docs:
https://developers.openai.com/codex/concepts/sandboxing#prerequisites ).

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

`codex --version` should print `codex-cli` and a version number.
`codex features list` should include `image_generation`. That is the
baseline you want before moving on.

The very first `codex` invocation may open a browser window for OpenAI
account authorization. Complete the flow in Windows, come back to the
Ubuntu terminal, and it continues.

If `image_generation` shows as disabled, the cleanest paths are:

- Run `codex` once interactively and ask for a simple image; the feature
  often becomes active after that.
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

- For the full picture — scope, JSON spec shape, aspect ratio reality,
  presets, debunked claims, and references — see
  [README.en.md](README.en.md).
- Copy one of the files in `examples/` and edit the prompts to match
  what you actually want to produce.
- Before sharing any output, remove absolute personal paths and any
  internal names from logs and summaries.
