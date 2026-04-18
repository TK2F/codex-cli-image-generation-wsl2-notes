# ツールなし利用ガイド

このガイドは、バッチランナーを使わなくても Codex の画像生成を理解し、直接使えるようにするためのものです。

## まず最初に確認すること

最初に次を実行してください。

```bash
codex --version
codex features list
```

WSL / Linux で sandbox 前提の警告が出る場合は、`bubblewrap` があるかも確認します。

```bash
command -v bwrap || command -v bubblewrap
```

## 画像生成 feature を有効にする推奨方法

一番簡単なのはこれです。

```bash
codex features enable image_generation
```

その後に確認します。

```bash
codex features list | grep '^image_generation'
```

## 設定ファイルを手で編集する方法

Codex のローカル設定は通常ここです。

```text
~/.codex/config.toml
```

手で編集する場合は、次の内容が入っていることを確認してください。

```toml
[features]
image_generation = true
```

すでに `[features]` セクションがある場合は、重複セクションを増やさず既存セクションへ key を追加してください。

## 対話モードで直接使う

まず Codex を起動します。

```bash
codex
```

その後に例えば次のように入力します。

```text
Use the built-in image generation capability only.
Generate a square 1:1 image of a blue sphere on a white background.
No text, no logo, no watermark.
```

## 非対話で直接使う

1 行生成:

```bash
printf 'Use the built-in image generation capability only.\nGenerate a square 1:1 image of a blue sphere on a white background.\nNo text, no logo, no watermark.\n' | codex exec -
```

入力画像 1 枚の編集:

```bash
codex exec -i ./input.png "Use the built-in image editing capability only. Change the background to white. Keep the subject, composition, and colors intact. No text, no logo, no watermark."
```

入力画像 2 枚の編集:

```bash
codex exec -i ./base.png -i ./reference.png "Use the first image as the base. Transfer the palette and mood from the second image while preserving the composition and main subject of the first image. No text, no logo, no watermark."
```

## 直接コマンドが使えるのに、なぜランナーがあるのか

ランナーには運用上のガードがあります。

- 環境診断
- 実行前 preview
- retry
- ジョブ間待機
- パス正規化
- JSON による構造化入力
- summary と raw log

1 枚だけ今すぐ作りたいなら direct command で十分です。  
複数回繰り返したい、他人へ渡したい、誤操作を減らしたいならランナーの方が安全です。

## この配布物で行った検証フロー

この share package は次の順で確認しました。

1. ランナーの構文チェック
2. `--help` の出力確認
3. `--list-presets` の出力確認
4. `--doctor` の出力確認
5. sample JSON に対する preview 実行
6. Windows path から WSL path への正規化確認
7. 個人情報、私的パス、秘匿情報の混入チェック

## 参照先

- Codex CLI docs: https://developers.openai.com/codex/cli
- Codex sandboxing と Linux/WSL の `bubblewrap` 前提: https://developers.openai.com/codex/concepts/sandboxing#prerequisites
- OpenAI image generation tool guide: https://developers.openai.com/api/docs/guides/tools-image-generation
- OpenAI models catalog: https://developers.openai.com/api/docs/models/all
