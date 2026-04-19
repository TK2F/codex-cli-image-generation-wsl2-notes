# 再現用クイックガイド — まず 1 枚出してから、必要なら batch に進む

この文書は、私（TK2Works）が WSL2 Ubuntu 上の Codex CLI で画像生成と画像編集を
試したときの流れを、**初心者でも追いやすい順** に並べ直したものです。

ここで共有しているのは、Codex CLI の公式な使い方そのものではなく、
**本環境で実際に通った確認手順** です。特に同梱の `codex-image-batch.sh` と
JSON spec は、私が検証を繰り返しやすくするために置いた補助実装であり、
Codex CLI の標準機能ではありません。

詳しい検証結果、環境差分、アスペクト比の扱い、スクリプト仕様の全体像は
[README.ja.md](README.ja.md) を参照してください。

## 先に押さえること

- この文書のコマンドは **WSL2 上の Bash 前提** です。
- Windows PowerShell ネイティブ実行は今回の検証範囲外です。
- まず **このリポジトリのルートディレクトリへ移動してから** コマンドを実行してください。
- `./examples/...` や `./codex-image-batch.sh` のような相対パスは、repo の外で実行すると見つかりません。
- 最初は helper script を使わず、**Codex CLI 単体で 1 枚出るか** を確認するのが安全です。
- `image_generation` は本環境では最初 `false` に見えましたが、これは公式の初期値として断定していません。
- 2026-04-19 の追試では、生成 PNG が作業ディレクトリではなく
  `~/.codex/generated_images/<session-id>/` に保存されるケースを確認しました。

### 最初にいる場所を確認する

WSL2 の Ubuntu / Bash で、この repo を clone または展開した場所へ移動してから
始めてください。たとえば次のようにします。

```bash
cd /path/to/codex-cli-image-generation-wsl2-notes
pwd
ls
```

`pwd` がこの repo のパスになっていて、`ls` に少なくとも次が見えれば、
正しい場所です。

- `README.md`
- `QUICKSTART.ja.md`
- `codex-image-batch.sh`
- `examples`

Windows Terminal から入る場合も、まず Ubuntu プロファイルを開いてから
同じ確認をするのが安全です。`user@host:~$` のような表示なら、まだ
ホームディレクトリにいる可能性があります。

## 1. minimum one-shot image generation

最初の目標は、**補助スクリプトを使わずに 1 枚だけ生成できることを確認する**
ことです。ここが通ってから batch に進むほうが、切り分けが楽です。

### 必要なもの

- WSL2 Ubuntu
- Node.js と Codex CLI
- Codex CLI のログイン完了

最初の確認コマンド:

```bash
codex --version
codex features list
```

私の環境では `codex-cli 0.121.0` が返り、`codex features list` で
`image_generation` の状態確認ができました。

### `image_generation` の有効化

本環境で通った方法は 3 通りありました。

**方法 A: `~/.codex/config.toml` に設定を書く**

```toml
[features]
image_generation = true
```

**方法 B: Codex の feature 管理サブコマンドを使う**

```bash
codex features enable image_generation
```

**方法 C: 実行時だけ `--enable image_generation` を付ける**

```bash
codex exec --enable image_generation -
```

追試では、`config.toml` ですでに有効化されている環境では、方法 C は実質
no-op でした。初心者の方は、まず `codex features list` を見て、
その時点の状態に合わせて選ぶのが安全です。

### 最初に試す 1 行コマンド

英語 prompt の最小例:

```bash
printf 'Use the built-in image generation capability only.\nGenerate a square 1:1 image of a blue sphere on a white background.\nNo text, no logo, no watermark.\n' | codex exec --enable image_generation -
```

日本語 prompt の最小例:

```bash
printf 'built-in の画像生成機能だけを使ってください。\n正方形 1:1、1024x1024 で、白背景に青い球体を 1 枚描いてください。\n文字、ロゴ、透かしは入れないでください。\n' | codex exec --enable image_generation -
```

この段階では、**まず 1 枚出るか** だけを確認します。batch や JSON は、
この確認が終わってからで十分です。

### 編集も 1 回だけ試す場合

入力画像 1 枚:

```bash
codex exec --enable image_generation -i ./input.png "Use the built-in image editing capability only. Change the background to white. Keep the subject, composition, and colors intact. No text, no logo, no watermark."
```

入力画像 2 枚:

```bash
codex exec --enable image_generation -i ./base.png -i ./reference.png "Use the first image as the base. Transfer the palette and mood from the second image while preserving the composition and main subject of the first image. No text, no logo, no watermark."
```

注意:

- `-i` を 2 つ並べると今回の prompt では通りました。
- ただし、これは「1 枚目が base、2 枚目が reference」という CLI 仕様保証を意味しません。
- **prompt がそう解釈された** と読むのが安全です。

### 初心者向けの最短ルート

1. `codex --version` を確認する
2. `codex features list` で `image_generation` の状態を見る
3. 必要なら `config.toml` または `--enable image_generation` を使う
4. まず 1 行コマンドで 1 枚だけ生成する
5. PNG の保存先を確認する

## 2. JSON batch usage

1 枚だけの確認が通ったあとで、**複数ジョブをまとめて流したい** と感じたら
JSON batch に進みます。

### これは公式 workflow ではなく、repo 同梱の補助実装

`codex-image-batch.sh` は、私が複数ジョブを繰り返し試すために書いた
個人的な Bash 補助スクリプトです。Codex CLI の公式ツールではありません。

このスクリプトで使う JSON の `aspect_ratio` や style 系の値は、Codex CLI の
公式パラメータではなく、**スクリプト側で prompt に展開する shorthand** です。

### batch 用の追加依存

batch まで試すなら、最小構成に加えて次を入れておきます。

```bash
sudo apt update
sudo apt install -y jq python3 bubblewrap coreutils findutils gawk grep
```

役割の目安:

- `jq`, `python3`: JSON の読み取りと構文確認
- `bubblewrap`: Codex の Linux / WSL 前提確認
- `coreutils`, `findutils`, `gawk`, `grep`: 補助スクリプトの実行に使用

### まずやる 3 ステップ

1. 診断だけ行う

```bash
bash ./codex-image-batch.sh --doctor
```

2. 実行せず、prompt と command だけ確認する

```bash
bash ./codex-image-batch.sh --spec ./examples/codex-image-preview.sample.json --preview
```

3. 問題なければ実行する

```bash
bash ./codex-image-batch.sh --spec ./examples/codex-image-batch.sample.json --pause-at-end
```

JSON を書かずに 1 ジョブだけ対話で流したい場合:

```bash
bash ./codex-image-batch.sh --manual --pause-at-end
```

### サンプル JSON の見方

生成サンプル:

- `examples/codex-image-preview.sample.json`
- `examples/codex-image-batch.sample.json`

編集サンプル:

- `examples/codex-image-edit-batch.sample.json`

スクリプトは次の 3 形を受け付けます。

- 単一ジョブの object
- ジョブ配列
- `defaults` と `jobs` を持つ object

最小例:

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
      "prompt": "白背景に青い球体を 1 枚描いてください。文字、ロゴ、透かしは入れないでください。"
    }
  ]
}
```

### 同梱 sample について 1 点だけ注意

- `examples/codex-image-preview.sample.json` は、入力画像なしで `--preview` が通る最小サンプルです。
- `examples/codex-image-batch.sample.json` には multi-reference job が含まれており、`examples/input/` の画像がまだ無いと、その job は `--preview` や本実行で失敗します。
- 最初の確認では preview 専用 sample を使い、その後で生成系 sample 全体や編集系 sample に進むのが安全です。

### 初心者向けの進め方

1. まず one-shot で 1 枚出す
2. 次に `--doctor` で環境を確認する
3. その次に `--preview` で prompt を確認する
4. 問題なければ sample JSON を実行する
5. 最後に自分の JSON を作る

## 3. troubleshooting for generated image location

この repo で一番つまずきやすいのが、**画像は生成されたのに、期待した場所に
PNG が見つからない** というケースです。

### まず知っておくこと

2026-04-19 の追試では、Codex が表示した保存先や、作業ディレクトリ直下に
PNG が見当たらないケースがありました。

本環境で実際に確認できた保存先:

```text
~/.codex/generated_images/<session-id>/ig_*.png
```

### 迷ったときの確認順

1. いまいるディレクトリに PNG ができているか確認する
2. Codex の出力ログに `session id:` が出ているか確認する
3. `~/.codex/generated_images/<session-id>/` を見る
4. helper script を使っている場合は run summary JSON も確認する

### 手動回収の例

```bash
session_id="019da255-d906-7831-8a2d-0912b86d3e00"
cp ~/.codex/generated_images/"$session_id"/*.png ./recovered-output.png
```

### よくある勘違い

- Codex が表示した `Output path` が、そのまま実在するとは限りませんでした。
- helper script を使っていても、最終的に `~/.codex/generated_images` から回収しているだけのことがあります。
- 並列実行時は、別セッションの画像を拾うリスクがあります。可能なら `session id` 単位で追うほうが安全です。
- `tokens used` が表示されても、PNG が現在のディレクトリに保存されたことの証明にはなりません。保存確認はファイル実在と `session id` 側を優先してください。

### 詰まったときの切り分け

- `codex` が見つからない: nvm の初期化が shell に反映されていない可能性があります。新しいターミナルを開くか、`~/.bashrc` を確認してください。
- `image_generation` が無効表示のまま: `codex features list` を再確認し、`config.toml`、`codex features enable`、`--enable image_generation` のどれを使うか整理してください。
- 指定した保存先に PNG がない: 先に `~/.codex/generated_images/<session-id>/` を確認してください。
- `bubblewrap` の警告が出る: Ubuntu では `sudo apt install -y bubblewrap` で入ります。
- PowerShell で同じコマンドが通らない: この文書のコマンドは WSL 側の Bash 前提です。

## 4. JSON validation tips

JSON batch に進んだら、**いきなり本実行せずに、まず JSON が壊れていないか**
を確認するのが安全です。

### まず構文だけ確かめる

`jq` が入っていれば:

```bash
jq . ./examples/codex-image-batch.sample.json >/dev/null
```

`python3` なら:

```bash
python3 -m json.tool ./examples/codex-image-batch.sample.json >/dev/null
```

どちらも無言で終われば、少なくとも JSON 構文は壊れていません。

### 実行前に `--preview` を使う

構文が正しくても、**意図した prompt になるか** は別問題です。特にこの repo の
JSON spec は、helper script が値を組み合わせて最終 prompt を作るため、
本実行前に `--preview` で確認するのが重要です。

```bash
bash ./codex-image-batch.sh --spec ./examples/codex-image-preview.sample.json --preview
```

`--preview` で確認できるもの:

- 最終的に Codex に渡す prompt
- 実行予定の `codex exec` コマンド
- 入力画像パスの解決結果

### spec を書くときの注意

- 相対パスは **spec ファイルの場所基準** で解決されます。
- `mode: "edit"` では `input_image` または `input_images` が必要です。
- `prompt` を直接書くと、それが優先されます。
- `subject` と `scene` に分けた場合は、スクリプトがそれらを組み合わせて prompt を作ります。
- 複数画像の役割は CLI 仕様ではなく prompt で明示する前提です。

### 迷ったときの安全策

1. まず sample JSON をそのまま `jq` または `python3 -m json.tool` で通す
2. 次に `--preview` で prompt を目視確認する
3. そのあとで自分の JSON を少しずつ編集する
4. 1 回に 1 か所だけ変えて再確認する

## 最後に

この文書は 2026-04-18 / 2026-04-19 時点の私の環境で試した結果の共有です。
お手元の環境で差分が出ることは十分ありえます。挙動が違った場合は、
Codex CLI のバージョン、feature 状態、保存先、認証状態、公式ドキュメントを
見比べながら確認してください。
