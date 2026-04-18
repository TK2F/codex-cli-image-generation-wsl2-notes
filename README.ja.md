# WSL2 Ubuntu 向け Codex 画像バッチランナー

このリポジトリは、`codex` を WSL2 の Ubuntu 上の Bash から呼び出す形で検証した workflow 向けの配布パッケージです。

元の作成者のホームディレクトリ、Windows ユーザー名、ローカルリポジトリの場所を開示せずに、そのまま他の環境へ渡せる形を意図しています。

検証者:

- TK2LAB
- Codex

検証日:

- 2026-04-19
- `codex-cli 0.121.0`

## 同梱ファイル

- `codex-image-batch.sh`
- `examples/codex-image-batch.sample.json`
- `examples/codex-image-edit-batch.sample.json`
- `examples/input/README.md`

## この文書のスコープ

ここで確認したのは次の構成です。

- WSL2
- Ubuntu
- Bash から Codex CLI を実行

他の Linux 環境でも動く可能性はありますが、この文書で断定しているのは上記の構成だけです。

## このランナーでできること

- JSON から複数の画像生成ジョブをまとめて実行
- JSON を書かずに手入力で 1 本だけ実行
- 1 枚または複数枚の入力画像を使った画像編集
- Linux パス、`C:\...` のような Windows パス、`\\wsl.localhost\Distro\...` のような UNC パスを受け付け
- Codex が指定先に PNG をコピーしなかった場合、`~/.codex/generated_images` から回収を試行
- ジョブごとの raw log と run summary JSON を保存

## 最初にやること

リポジトリのルートで次を実行してください。

```bash
bash ./codex-image-batch.sh --doctor
```

この診断で確認する内容:

- `jq`、`python3` など必須コマンドの有無
- `codex` が `PATH` にあるか
- `~/.nvm/.../bin/codex` のような fallback 候補があるか
- `image_generation` が有効か

もし `codex` が `PATH` に無い場合は、実体を明示して実行できます。

```bash
CODEX_BIN="$HOME/.nvm/versions/node/<your-version>/bin/codex" \
  bash ./codex-image-batch.sh --doctor
```

`<your-version>` を自分の Node バージョンに置き換えてください。

## 一番安全な始め方

まず sample JSON を preview してください。

```bash
bash ./codex-image-batch.sh --spec ./examples/codex-image-batch.sample.json --preview
```

これは prompt と command の表示だけを行い、画像生成は実行しません。

## 実際にバッチ実行する

```bash
bash ./codex-image-batch.sh --spec ./examples/codex-image-batch.sample.json --pause-at-end
```

`--no-prompt` を付けない限り、本実行前に確認が入ります。

## 手入力で 1 本だけ実行する

```bash
bash ./codex-image-batch.sh --manual --pause-at-end
```

JSON を作らずに、その場で prompt を入力したいときに使います。

## JSON の形

対応している root 形式:

- 単一ジョブの object
- ジョブ配列
- `defaults` と `jobs` を持つ object

例:

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

## よく使うオプション

- `--preview`
  prompt と command の確認だけを行う
- `--manual`
  1 ジョブを手入力で実行
- `--doctor`
  環境診断だけして終了
- `--list-presets`
  aspect / style の組み込み preset 一覧を表示
- `--overwrite`
  既存出力を skip せず上書き
- `--stop-on-job-error`
  1 件失敗した時点で停止
- `--inter-job-delay N`
  ジョブ間待機秒数
- `--retry-count N`
  失敗時の再試行回数
- `--pause-at-end`
  実行後に Enter 待ち

## 初心者がやりがちなミス

- Windows PowerShell でそのまま実行する
  このパッケージは WSL/Linux の Bash 向けです。
- JSON ファイルではなくフォルダを貼る
  ランナーが警告します。
- preview をせずに本実行する
  迷うならまず `--preview` を使ってください。
- edit mode なのに入力画像を指定していない
  編集ジョブには最低 1 枚の画像が必要です。
- 既存画像が自動で上書きされると思い込む
  デフォルトは skip です。上書きしたい場合は `--overwrite` を付けます。
- Windows パスを貼ると必ず失敗すると思い込む
  `C:\...` や `\\wsl.localhost\...` は自動変換されます。

## 出力ファイル

デフォルトの出力先:

- 生成サンプルは `./outputs`
- 編集サンプルは `./edited-outputs`

各実行では次も保存されます。

- ジョブごとの raw log
- run summary JSON

summary や log の参照は、可能な限り相対パスで書き出すようにしてあり、そのまま共有しやすくしてあります。

## 共有時の注意

- このパッケージには、配布時に不要なユーザー固有パスやマシン名を埋め込まないようにしています。
- フォルダ名を変更しても構いません。
- JSON 内の相対パスは、シェルのカレントディレクトリではなく JSON ファイル自身の場所を基準に解決されます。
