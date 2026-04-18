# WSL2 Ubuntu から Codex CLI で画像生成 — フィールドレポート

Windows 11 の WSL2 Ubuntu 上の Bash から `codex` を呼び出すと、画像生成と
画像編集が本当にそのまま通るのか。もし通るなら、最小コマンドはどれくらい
素朴に書けるのか。1 枚から複数枚に増えるとどこで摩擦が生まれるのか。
この文書は、その 3 点を順に確かめて記録した、一人称のフィールドレポート
です。

> これは TK2LAB と Codex が、下記の具体的な組み合わせで確かめた
> 一人称の観察記録です。「この環境でこう試した」「結果はこうだった」
> 「公式ドキュメントにはこう書かれていた」を並べたものであり、同じ
> セットアップや手順を推奨するものではありません。読者のお手元でも
> 同じコマンドを走らせて結果を見比べていただけると、このレポートの
> 意味が一番強くなります。

**検証者:** TK2LAB, Codex
**検証日:** 2026-04-19
**ホスト OS:** Windows 11
**ランタイム:** WSL2 上の Ubuntu
**シェル:** Bash（Windows PowerShell ネイティブ実行は対象外）
**Codex CLI:** `codex-cli 0.121.0`
（その他のパッケージ／ランタイム／ライブラリの個別バージョンと
確認コマンドは、次の「[検証環境のバージョンと確認コマンド](#検証環境のバージョンと確認コマンド)」節にまとめています。）

---

## 目次

1. [はじめに（最低限の前提だけ）](#はじめに最低限の前提だけ)
2. [30 秒でわかる結論](#30-秒でわかる結論)
3. [検証環境のバージョンと確認コマンド](#検証環境のバージョンと確認コマンド)
4. [検証スコープと断定していないこと](#検証スコープと断定していないこと)
5. [最小コマンドでの動作確認結果](#最小コマンドでの動作確認結果)
6. [`printf` を使った理由と読み方](#printf-を使った理由と読み方)
7. [日本語 prompt と英語 prompt](#日本語-prompt-と英語-prompt)
8. [アスペクト比で見えた現実](#アスペクト比で見えた現実)
9. [1 枚から複数枚へ — 私が書いた簡易ユーティリティの位置づけ](#1-枚から複数枚へ--私が書いた簡易ユーティリティの位置づけ)
10. [今回辿った doctor → preview → run の順](#今回辿った-doctor--preview--run-の順)
11. [JSON spec の形](#json-spec-の形)
12. [組み込みプリセット](#組み込みプリセット)
13. [よく流れてくる話と、今回の観察の対比](#よく流れてくる話と今回の観察の対比)
14. [外部に共有する前の自分向けチェック](#外部に共有する前の自分向けチェック)
15. [オプション早見表](#オプション早見表)
16. [作業中に観察した誤りやすい点](#作業中に観察した誤りやすい点)
17. [参照した公式ドキュメント](#参照した公式ドキュメント)

---

## はじめに（最低限の前提だけ）

この文書は、Codex CLI と WSL2 に最低限の知識がある読者が、当方の観察を
追試できるよう整えたレポートです。初心者向けの導入解説ではないので、
個々のツールの入門情報は各公式ドキュメントが一次情報になります。

- **Codex CLI** — OpenAI が提供するコマンドラインツール。本文のコマンドは
  `codex exec` を中心に扱います。
  公式: https://developers.openai.com/codex/cli
- **WSL2** — Windows の上で Linux を動かす Microsoft の公式機能。当方の
  検証は WSL2 上の Ubuntu + Bash で行いました。
  公式: https://learn.microsoft.com/windows/wsl/install
- **PowerShell と Bash は別物** — エスケープやパイプの扱いが異なります。
  本文のコマンドは WSL 側の Bash 前提です。PowerShell ネイティブ実行は
  検証していません。
- **コードブロックの読み方** — 先頭に `$` やプロンプト記号は付けていま
  せん。そのままコピーしてターミナルに貼り付けられる形に揃えています。
- **前提状態** — `codex` が WSL2 Ubuntu にインストールされており、初回の
  ログインと sandbox 設定が済んでいる状態を起点にしています。
- **副作用の大きさ** — 本文のコマンドは、左上ほど副作用が小さいものから
  並べています。`--doctor` と `--preview` は Codex 本体を呼ばず画像も
  生成しません。

以降の記述は、この前提の上で当方が実際に実行したコマンドと、その結果の
観察記録です。同じ結果が出るかどうかを、お手元でご確認いただけると、
このレポートの意味が強くなります。

## 30 秒でわかる結論

まず結論だけ先にまとめます。詳細は各節で述べます。

- WSL2 Ubuntu の Bash から `codex exec` で、画像生成と画像編集の両方が
  通った。
- 最小の生成コマンドは `printf ... | codex exec -` の 1 行。
- 編集は `codex exec -i ./input.png "..."` の 1 行。2 枚同時に渡したい
  ときは `-i` を 2 つ並べる。
- 日本語 prompt・英語 prompt とも、生成・編集の両方で通った。
- 出力サイズは `1024x1024`, `1024x1536`, `1536x1024` の 3 実寸で安定した。
  任意比率は「希望値」として受け取られ、近い実寸に寄る挙動を何度か
  観察した。
- 1 枚から複数枚に増えた時点で、preview・retry・path 正規化・サマリ生成を
  まとめた小さな runner があると明らかに楽になった。
- Codex CLI の公式ドキュメントは、CLI 自体での画像生成・編集をサポート
  していると明記している（[参照](#参照した公式ドキュメント)）。

## 検証環境のバージョンと確認コマンド

「手元と違うから参考にならない」で終わらないよう、検証時に観測した
バージョンと、同じ値を取得するコマンドを一覧にします。左列の値は今回の
実測値、右列のコマンドはそのまま手元で走らせられます。値が確認できた
ものはそのまま掲載し、報告時点で未採取のものは `—` としています。
差分を見比べながら読み進めてください。

| 項目 | 今回の実測値 | 確認コマンド |
| --- | --- | --- |
| Windows | Windows 11 | PowerShell: `winver`、または `Get-ComputerInfo \| Select-Object WindowsProductName, WindowsVersion, OsBuildNumber` |
| PowerShell | — | PowerShell: `$PSVersionTable.PSVersion` |
| WSL | WSL2 | PowerShell: `wsl --version`、または `wsl --status` |
| Ubuntu ディストリビューション | Ubuntu（LTS） | Bash: `cat /etc/os-release`、または `lsb_release -a` |
| カーネル | — | Bash: `uname -r` |
| Bash | — | Bash: `bash --version` |
| Codex CLI | `codex-cli 0.121.0` | Bash: `codex --version` |
| Codex feature 状態 | `image_generation` が有効 | Bash: `codex features list` |
| Node.js | — （nvm 経由で LTS） | Bash: `node --version` |
| npm | — | Bash: `npm --version` |
| nvm | — | Bash: `nvm --version` |
| jq | — | Bash: `jq --version` |
| python3 | — | Bash: `python3 --version` |
| bubblewrap | — | Bash: `bwrap --version` |

まとめて記録したい場合は、WSL 側の Bash で次の 1 行を実行するとコピー
しやすい形で出力されます。

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

PowerShell のバージョンと Windows のビルド番号は WSL からは直接取れない
ので、Windows 側で次の 2 行を別途実行してください。

```powershell
Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OsBuildNumber
$PSVersionTable.PSVersion
```

## 検証スコープと断定していないこと

観察の対象は上の環境に絞っています。そこから外れる領域については、
この文書では事実として述べず、読者自身の環境で改めて確認できるよう、
断定していない点を明示します。

- 実寸 `1024x1024`, `1024x1536`, `1536x1024` の 3 サイズで安定動作を
  確認した。
- `codex exec` は、stdin から prompt を受ける形と、引数文字列として
  渡す形のどちらでも動作した。
- 生成物の保存先として、カレントディレクトリへのコピーと
  `~/.codex/generated_images` への保存の両方を観測した。
- text 側のモデル flow としては GPT-5.4 系を観測した。ただし、CLI が
  各呼び出しで内部的にどの image model alias を選んでいたかは、こちら
  から直接は観測できなかった。
- 公開できない内部固有名（キャラクター名、マシン名、ホームディレクトリ、
  私用メールなど）は、このリポジトリから意識的に外している。

断定していないこと:

- CLI が個々の呼び出しで採用していた image model alias の具体名。
- GPT-5.4 より前のモデル世代での同等挙動。
- 任意サイズ指定（例: `1408x768`）がモデル側で字義どおりに反映されること。
- Windows PowerShell ネイティブでの同等挙動。

## 最小コマンドでの動作確認結果

最初に確認したいのは「当方の環境で、1 行のコマンドで生成・編集が通るか」
でした。実際に通った最小コマンドを、生成 → 編集（1 枚）→ 編集（2 枚）の
順で記録します。同じコマンドを手元で走らせて、結果を比べていただけると
助かります。

**生成:**

```bash
printf 'Use the built-in image generation capability only.\nGenerate a square 1:1 image of a blue sphere on a white background.\nNo text, no logo, no watermark.\n' | codex exec -
```

**1 枚の画像を編集:**

```bash
codex exec -i ./input.png "Use the built-in image editing capability only. Change the background to white. Keep the subject, composition, and colors intact. No text, no logo, no watermark."
```

**2 枚の画像を組み合わせて編集（1 枚目を base、2 枚目を reference）:**

```bash
codex exec -i ./base.png -i ./reference.png "Use the first image as the base. Transfer the palette and mood from the second image while preserving the composition and main subject of the first image. No text, no logo, no watermark."
```

実行する前の様子見として、今回はまず次の 2 行を打ちました。どちらも画像を
生成しないので副作用の心配はありません。

```bash
codex --version
codex features list
```

`codex features list` の出力に `image_generation` が含まれ、かつ有効側に
見えていれば、ここから先の 3 コマンドはそのまま通せる状態にあります。

## `printf` を使った理由と読み方

one-liner の冒頭に `echo` ではなく `printf` を置いたのには、地味ですが
理由があります。

- `echo` は `\n` の扱いがシェル実装ごとにぶれる。`printf` は POSIX で
  挙動が定義されているため、改行入りの prompt を送るときに結果が揺れ
  にくい。
- `| codex exec -` の末尾 `-` は、`codex exec` 側で「prompt は stdin
  から読む」という明示的な指定。複数行のテキストを素朴に渡せる形に
  なる。

分解するとこのような構造です。

```bash
printf 'line1\nline2\nline3\n' | codex exec -
#  ^^^^^^                      ^     ^^^^^^^^^^
#  改行を含めて複数行を         パイプ  stdin から prompt を読む実行モード
#  標準出力に書き出す
```

`-i ./input.png` を付けない形（上の生成例）は「添付画像なしで生成」、
付けた形は「添付画像を読み込んで編集」という具合に、`-i` の有無だけで
そのまま挙動が切り替わります。

複数行をそのままの形で書きたいときは、heredoc を使っても同じ挙動に
なります。

```bash
codex exec - <<'EOS'
Use the built-in image generation capability only.
Generate a square 1:1 image of a blue sphere on a white background.
No text, no logo, no watermark.
EOS
```

ヒアドキュメントの境界記号を `'EOS'` のようにシングルクォートで囲むと、
bash が prompt 本文の `$` や `!` を展開しなくなります。prompt に `$`
を含めるときは、この形にしておくと安全です。

## 日本語 prompt と英語 prompt

今回は生成・編集の両方で、日本語・英語の prompt がどちらも通りました。
組み合わせは 4 通りです。

- 生成 × 日本語
- 生成 × 英語
- 編集 × 日本語
- 編集 × 英語

日本語の生成 prompt を手入力する場合の例:

```bash
printf 'built-in の画像生成機能だけを使ってください。\n正方形 1:1、1024x1024 で、白背景に青い球体を 1 枚描いてください。\n文字、ロゴ、透かしは入れないでください。\n' | codex exec -
```

日本語での編集指示の例:

```bash
codex exec -i ./input.png "built-in の画像編集機能だけを使ってください。背景だけを白に変更し、被写体、構図、色味は維持してください。文字、ロゴ、透かしは加えないでください。"
```

試した範囲で 2 つ、気づいた運用のコツを書き残しておきます。必須ではあり
ませんが、自分の手元では安定に寄与した表現です。

- 「built-in の画像生成機能だけを使ってください」と最初に宣言する。
  これを入れないと、状況によっては SVG や HTML で代用した応答に揺れる
  ことがあった。
- 「文字、ロゴ、透かしは入れないでください」をテンプレの末尾に固定で
  入れる。後で消すより、最初から入れておくほうが手戻りが少なかった。

## アスペクト比で見えた現実

今回の観察の範囲で、事実上のサイズは次の 3 つに収束しました。

- `1024x1024` — 正方形
- `1024x1536` — 縦長
- `1536x1024` — 横長

これは OpenAI の画像モデルの公開ドキュメントに記載されているサイズと
一致します（[参照](#参照した公式ドキュメント)）。

「9:16 の Instagram Story」「4:5 の Instagram フィード」「16:9 のヒーロー
バナー」といったよくある希望比率は、モデル側で最終的にこれら 3 実寸の
いずれかに寄る様子でした。runner の aspect preset も、その観察を前提に
次の対応で内部を組んでいます（`--list-presets` で同じ内容を表示できます）。

| preset            | 実寸の扱い                                         |
| ----------------- | -------------------------------------------------- |
| `square`          | 1024x1024                                          |
| `portrait`        | 1024x1536                                          |
| `landscape`       | 1536x1024                                          |
| `instagram_story` | 縦長（1024x1536 寄り）として扱った                 |
| `instagram_post`  | 縦長として扱った                                   |
| `hero_banner`     | 横長（1536x1024 寄り）として扱った                 |
| `custom`          | `1408x768` のような任意の `WIDTHxHEIGHT`           |

`custom` はモデル側で字義どおりに反映される保証のない「希望値」です。
近い公開サイズに寄ることを前提に書くほうが、あとで混乱しにくい、という
のが今回の感触です。

## 1 枚から複数枚へ — 私が書いた簡易ユーティリティの位置づけ

複数枚をまとめて回したいというニーズは今回の作業で発生しました。
公式の CLI だけでもループを書けば済む話ですが、preview・retry・
パス正規化・生成ファイルの回収などを毎回自前で書き直すのが億劫で、
自分の作業のために小さな Bash スクリプトを用意しました。同梱の
`codex-image-batch.sh` がそれです。

**お勧めのツールとして配布しているものではありません。** 「JSON で
複数の生成・編集ジョブを並べて流せると便利だった」という個人的な
事情で書いたユーティリティを、そのまま共有しているだけです。同じ
目的にはもっと良いアプローチ（並列実行、Make / Taskfile、独自の
Python ドライバ、既存の CI ツール等）があるはずなので、ご自身の
作業に合う形で差し替えて試してみてください。

当方の作業で実際に効いた補助機能は、結果的に次の 7 点でした。同じ
動機がある方には、このスクリプトが出発点の 1 つになるかもしれません。

- 本実行前に prompt と command を目視確認する（preview モード）
- 失敗したジョブを自動で retry する
- ジョブ間で一定秒数待つ
- Linux パス / Windows ドライブパス / WSL UNC パスの混在を正規化する
- Codex が PNG を指定先にコピーしなかった場合に
  `~/.codex/generated_images` から回収を試みる
- 1 回の run の成否と出力パスを summary JSON に残す
- ジョブ単位の raw log を残す

外部依存は `jq` と `python3` のみ、本体は 1 ファイル完結で、読み切れる
長さに収めてあります。もっとうまい書き方や、別言語での再実装を
試される場合は、当方の元スクリプトは参考 / アンチパターンのどちらと
してでも自由に使ってください。

## 今回辿った doctor → preview → run の順

当方でスクリプトを使って動作確認したときの順序を、そのまま記録します。
お勧めの使い方というより、「私はこうやって試した」という記録なので、
読み方の順序と思っていただければ十分です。

```bash
bash ./codex-image-batch.sh --doctor
```

`--doctor` は、`jq` や `python3` などの必要コマンド、`codex` の `PATH`、
`~/.nvm/.../bin/codex` のような fallback 候補、そして `image_generation`
feature の状態までをまとめて表示します。

`codex` が `PATH` に乗っていない環境では、実体を明示して同じ診断を
走らせられます。

```bash
CODEX_BIN="$HOME/.nvm/versions/node/<your-version>/bin/codex" \
  bash ./codex-image-batch.sh --doctor
```

`<your-version>` は、手元でインストールされている Node のバージョンに
置き換えてください。

```bash
bash ./codex-image-batch.sh --spec ./examples/codex-image-batch.sample.json --preview
```

`--preview` は、最終 prompt と実行予定の `codex exec` コマンドを表示
するだけで、Codex 本体は呼び出しません。

```bash
bash ./codex-image-batch.sh --spec ./examples/codex-image-batch.sample.json --pause-at-end
```

本実行の前に確認プロンプトが入ります。自動化したいときだけ `--no-prompt`
を明示します。

JSON を用意せず、対話で 1 ジョブだけ走らせたいときは manual モードが
便利でした。

```bash
bash ./codex-image-batch.sh --manual --pause-at-end
```

## JSON spec の形

ランナーは、spec の root を 3 つの形で受け付けます。

- 単一ジョブの object
- ジョブ配列
- `defaults` と `jobs` を持つ object

後から option を追加するとき、3 つ目の形がいちばん扱いやすく感じました。

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

気をつけた点:

- `codex_model` は `codex exec --model` にそのまま渡される override で、
  ランナー側では値の妥当性を検査していません。どのモデル名が受け入れ
  られるかは、そのときの Codex CLI とアカウントの挙動に依存します。
- 相対パスは、シェルの cwd ではなく **spec ファイル自身の場所** を
  基準に解決されます。spec を含むフォルダを移動しても壊れない形にした
  かったため、この動作を選びました。
- `mode` は `generate` または `edit`。`edit` の場合は `input_image`
  または `input_images` を少なくとも 1 つ指定します。
- `subject` と `scene` に分けて書くと、ランナーが style・aspect と
  組み合わせて prompt を構築します。prompt を 1 本の文字列で書きたい
  ときは `prompt` フィールドを使うと、そちらが優先されます。

サンプルは 2 本同梱しています。

- `examples/codex-image-batch.sample.json` — 生成系 5 ジョブ
- `examples/codex-image-edit-batch.sample.json` — 編集系 3 ジョブ

## 組み込みプリセット

アスペクト preset は上の「アスペクト比で見えた現実」のとおり。スタイル
preset は意図的に少なく、今回の実験に必要だったものだけに絞っています。

- `none`
- `watercolor`
- `cinematic`
- `pixel_art`
- `product_render`

最新の一覧は `--list-presets` で取得できます。

## よく流れてくる話と、今回の観察の対比

ネットや会話で繰り返し耳にする話を、今回の環境での観察と公式ドキュ
メントの記述に照らして並べます。あくまで今回のセットアップで見えた
範囲の話です。別の環境で別の結果が出た場合には、そちらの観察の方が
優先されます。

**「画像生成は Codex desktop app でしかできないのでは？」**

今回の観察ではそう思えませんでした。Codex CLI の公式ドキュメントでは、
CLI 自体で画像生成と画像編集の両方がサポートされていると明記されて
います（[参照](#参照した公式ドキュメント)）。今回の検証も CLI だけで
完結しました。

**「GPT-5.4 と表示されているなら、GPT-5.4 本体が PNG を描いているはず」**

そこまでは言えませんでした。今回確認できたのは、CLI の text 側で
GPT-5.4 系が使われていたこと、そして画像は Codex の built-in image
generation を経由して出ていたことまでです。OpenAI の発表では
Codex が `gpt-image-1.5` を使うと案内されていますが、CLI 上で内部の
image model alias までは表面に出ていませんでした。

**「OpenAI の API を直接叩かないと画像生成は無理では？」**

そうではありませんでした。API は便利ですが、今回のサンプルの範囲では
CLI 単体で完結できました。API ドキュメントは、モデル側が実際に対応する
画像サイズの裏取りとして活用しました。

**「任意サイズを指定すれば、字義どおりに返ってくるのでは？」**

観察の範囲ではそうなりませんでした。実運用で安定したのは公開 3 実寸
（`1024x1024`, `1024x1536`, `1536x1024`）でした。任意比率は「希望値」と
捉えた方が、結果との食い違いが小さくなりました。

**「WSL の前提なんて、気にしなくていいのでは？」**

Codex の sandbox ドキュメントは、Linux / WSL2 の前提として
`bubblewrap` を挙げています。環境が整っているほうが失敗の原因切り分け
が短くなったので、今回はその案内に沿って進めました。

**「GPT-5.4 以前のモデルでも、同じように動くのでは？」**

この文書ではそれを証明していません。ここに書いたのは `codex-cli 0.121.0`
と GPT-5.4 世代の観察に限定されています。

## 外部に共有する前の自分向けチェック

今回のような実験ノートをほかの人に渡すとき、自分に対して毎回通して
いるチェックを共有しておきます。読者自身の文脈でも、同じ観点が役立つ
ことがあるかもしれません。

- 個人のホームディレクトリ絶対パスが、prompt / log / summary に残って
  いないか。ランナーは可能な範囲で相対パスに丸めて書き出すが、
  prompt や入力画像名までは手で整えた方が確実だった。
- 固有のキャラクター名やプロダクト名が残っていないか。サンプル prompt は
  glass bottle や blue sphere のような汎用被写体に差し替えた。
- ホスト名、Windows ユーザー名、私用メールアドレス、API キー、トークン、
  Node の固定バージョン文字列などが、環境メモに紛れていないか。
- 出力フォルダに、そのまま共有するのはためらう画像が残っていないか。
  `.gitignore` は `examples/outputs/`, `examples/edited-outputs/`,
  `*.log.txt`, 実行サマリ JSON などを除外してあるが、手元の追加出力先
  については都度確認している。

## オプション早見表

- `--spec PATH` — JSON spec ファイルのパス
- `--output-root PATH` — 出力ルートの上書き
- `--codex-bin PATH` — codex 実体を明示（環境変数 `CODEX_BIN` でも可）
- `--ui-mode auto|cli` — 入力モードの選択（デフォルト `auto`）
- `--manual` — JSON を使わず手入力で 1 ジョブ
- `--preview` — prompt と command を表示するだけで実行はしない
- `--doctor` — 環境診断のみ実行
- `--list-presets` — 組み込み preset を一覧表示
- `--no-prompt` — 確認プロンプトを出さずに進める（`--spec` か `--manual`
  が必須）
- `--stop-on-job-error` — 1 件失敗で停止
- `--overwrite` — 既存出力を上書き
- `--pause-at-end` — 実行後に Enter 待ち
- `--inter-job-delay N` — ジョブ間で `N` 秒待機（デフォルト 2）
- `--generated-image-wait N` — `~/.codex/generated_images` からの回収
  待機（デフォルト 5 秒）
- `--retry-count N` — 失敗時の再試行回数（デフォルト 1）
- `--retry-delay N` — 再試行の間隔秒数（デフォルト 3）
- `-h`, `--help` — ヘルプ表示

## 作業中に観察した誤りやすい点

当方の作業中に踏んだ、あるいは周囲でよく聞いた誤解を観察として並べます。
同じ条件で作業される方には、当方の失敗の履歴として参考になるかもしれま
せん。注意書きではなく、観察の共有です。

- スクリプトを WSL ではなく Windows PowerShell で走らせてしまう。
  このパッケージは WSL の Bash 前提で作った。
- JSON ファイルの代わりにフォルダのパスを貼ってしまう。ランナーが警告を
  出す。
- 新しい spec を preview せずに本実行に回す。preview は副作用がゼロで、
  実行前の安価な安全装置として便利だった。
- edit mode で入力画像の指定を忘れる。edit ジョブは最低 1 枚必須。
- 既存の PNG が自動で上書きされると思い込む。デフォルトは skip。上書き
  したいときだけ `--overwrite` を付ける。
- `C:\...` や `\\wsl.localhost\...` は絶対に失敗すると思い込む。よくある
  形は自動で Linux パスに変換した。

## 参照した公式ドキュメント

この文書の主張は、可能な限り一次情報に寄せて確認しています。反対の観察や
より新しい記述が見つかった場合は、そちらが優先されます。

- Codex CLI ドキュメント
  https://developers.openai.com/codex/cli
- Codex sandboxing と Linux/WSL 前提（`bubblewrap`）
  https://developers.openai.com/codex/concepts/sandboxing#prerequisites
- 画像生成ツール利用ガイド
  https://developers.openai.com/api/docs/guides/tools-image-generation
- OpenAI モデルカタログ
  https://developers.openai.com/api/docs/models/all
- GPT Image 1.5 のモデルページ
  https://developers.openai.com/api/docs/models/gpt-image-1.5/
- Codex for (almost) everything
  https://openai.com/index/codex-for-almost-everything/
