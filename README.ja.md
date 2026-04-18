# WSL2 Ubuntu から Codex CLI で画像生成 — 実地検証と batch runner

「Windows 11 の WSL2 から Codex CLI を呼び出して、本当にそのまま画像を
生成・編集できるのか？」を出発点に、最小コマンド、日本語 / 英語 prompt の
通り方、アスペクト比の実挙動、`printf` 経由の one-liner 構文、複数枚を
まとめて回すときの JSON バッチまでを、動かした順で記録したドキュメント
です。誇張を避け、できたことだけを書き、公式ドキュメントでの裏取りも
付けています。

> このリポジトリは、TK2LAB と Codex が手を動かして確かめた**小さな実験の
> 記録**です。正式なベンチマークや網羅的な検証ではありません。記載内容は
> 今回の条件で実際に動いたもの・観測したものに限定しており、そこから外れる
> 挙動について断定はしていません。環境や時期が変われば同じようには動かない
> 可能性がある点を前提に読んでいただけると幸いです。

検証者: TK2LAB, Codex
検証日: 2026-04-19
CLI: `codex-cli 0.121.0`
対象シェル: WSL2 Ubuntu の Bash
対象外: Windows PowerShell ネイティブ実行

---

## 目次

1. [はじめに（最低限の前提だけ）](#はじめに最低限の前提だけ)
2. [30 秒サマリ（結論だけ先に）](#30-秒サマリ結論だけ先に)
3. [検証範囲とサンプルの立ち位置](#検証範囲とサンプルの立ち位置)
4. [最小の「本当に動くか」証明](#最小の本当に動くか証明)
5. [`printf` を使う理由と読み方](#printf-を使う理由と読み方)
6. [日本語 prompt と英語 prompt](#日本語-prompt-と英語-prompt)
7. [アスペクト比の現実](#アスペクト比の現実)
8. [1 枚から複数枚へ — runner の役割](#1-枚から複数枚へ--runner-の役割)
9. [doctor → preview → run の順序](#doctor--preview--run-の順序)
10. [JSON spec の形と読み方](#json-spec-の形と読み方)
11. [組み込みプリセット](#組み込みプリセット)
12. [Fact check と debunk](#fact-check-と-debunk)
13. [共有する前のチェック](#共有する前のチェック)
14. [オプション早見表](#オプション早見表)
15. [ハマりやすい落とし穴](#ハマりやすい落とし穴)
16. [参照した公式ドキュメント](#参照した公式ドキュメント)

---

## はじめに（最低限の前提だけ）

この章は、Codex CLI も WSL2 も初めてという読者向けの軽い補足です。すでに
知っている方は読み飛ばしてかまいません。

- **Codex CLI とは**: OpenAI が配布しているコマンドラインツールで、
  `codex` コマンドで起動します。対話モードと、`codex exec` のような
  非対話実行の両方を持ちます。公式ドキュメント: https://developers.openai.com/codex/cli
- **WSL2 とは**: Windows 10/11 上で Linux を動かせる公式の仕組みです。
  スタートメニューから「Ubuntu」を開くと、Linux のターミナル（= Bash）が
  立ち上がります。インストール未済の場合は、PowerShell を管理者で開いて
  `wsl --install` を一度だけ実行するのが標準手順です。
- **PowerShell と Bash は別物**: 画面は似ていますが、コマンドの文法と
  エスケープが違います。このリポジトリのコマンドはすべて **WSL の
  Bash** を前提にしています。Windows 側の PowerShell や cmd にそのまま
  貼っても、多くの場合は動きません。
- **コマンドの読み方**: 本文中の `$` やプロンプト記号は書いていません。
  コードブロックの中身をそのままターミナルに貼り付けて Enter で実行
  できます。`# ...` はコメントなので実行には関係しません。
- **`codex` が動く前提**: この文書は、WSL2 Ubuntu の中に `codex` が
  インストール済みで、一度ログインとサンドボックス設定が済んでいる状態を
  出発点にしています。未インストールの場合は上記 Codex CLI 公式 docs に
  従ってください。
- **「やっちゃダメ」な操作**: 本文のコマンドは、読むだけなら副作用が無い
  ものから順に並んでいます。迷ったら先に `--doctor` と `--preview` を
  実行してください。この 2 つは画像を生成しません。

これ以降は、実際に何が動いたかの記録です。

---

## 30 秒サマリ（結論だけ先に）

- WSL2 Ubuntu の Bash から `codex exec` で画像生成・画像編集ができた。
- 最初の 1 枚は `printf ... | codex exec -` の 1 行で十分。
- 画像編集は `codex exec -i ./input.png "..."` の 1 行で十分。2 枚同時は
  `-i` を 2 つ並べる。
- 日本語 prompt でも英語 prompt でも、生成・編集のどちらも通った。
- サイズは **`1024x1024`**, **`1024x1536`**, **`1536x1024`** の 3 実寸で
  考えるのが素直。任意比率は希望扱いで、近い実寸に寄る前提で書く。
- 画像が 1 枚から複数枚になった段階で、JSON spec を読ませる runner が
  明確に効いてくる。
- 裏取り: Codex CLI docs は CLI 自体での画像生成/編集をサポートすると
  明記している（[参照](#参照した公式ドキュメント)）。

## 検証範囲とサンプルの立ち位置

- プラットフォーム: Windows 11 + WSL2 + Ubuntu + Bash。
- CLI: `codex-cli 0.121.0`。
- text 側のモデル flow としては GPT-5.4 系を観測した。ただし「CLI が
  内部でどの image model alias を選んだか」までは直接は確認していない。
- 実寸 `1024x1024`, `1024x1536`, `1536x1024` の 3 サイズで安定して
  使えることを確認。
- `codex exec` は stdin から prompt を受ける形と、引数文字列として
  prompt を渡す形のどちらも動作。
- 生成物の保存先として、カレントディレクトリへのコピーと、
  `~/.codex/generated_images` への保存のどちらも観測した。
- 公開できない内部固有名（キャラクター名、マシン名、ホームディレクトリ、
  私用メールなど）は、すべてこのリポジトリから外してある。

断定していないこと:

- CLI が毎回どの image model alias を選んでいるか。
- GPT-5.4 より前のモデル世代でも同じ挙動が出るか。
- 任意サイズ指定（例: `1408x768`）がモデル側で字義どおりに反映されるか。
- Windows PowerShell ネイティブでの同等動作。

## 最小の「本当に動くか」証明

やれることから順に、もっとも短い形で 3 つ。

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

最初に動かす前の確認はこの 2 行でよい。

```bash
codex --version
codex features list
```

`codex features list` の出力に `image_generation` が含まれており、有効に
なっているかを眺めます。

## `printf` を使う理由と読み方

one-liner では **`printf`** を使っています。これは偶然ではなく理由が
あります。

- `echo` は shell 実装によって `\n` の扱いが変わるのに対し、`printf` は
  POSIX で明確に定義されているため、改行入りの複数行 prompt を安全に
  送れる。
- `| codex exec -` の末尾 `-` は「stdin から prompt を読む」という
  `codex exec` の明示的な指定で、多行 prompt を素直に渡せる。

分解するとこうなります。

```bash
printf 'line1\nline2\nline3\n' | codex exec -
#  ^^^^^^                      ^     ^^^^^^^^^^
#  標準出力へ複数行を           パイプ   stdin 経由で prompt を渡す呼び出し
#  改行付きで出力
```

`-i ./input.png` が無い形（上の生成例）は「添付画像なしで生成」、ある
形は「添付画像を読み込んで編集」と、そのまま挙動が切り替わります。

好みで、複数行を素直に書きたければ heredoc でもよい。

```bash
codex exec - <<'EOS'
Use the built-in image generation capability only.
Generate a square 1:1 image of a blue sphere on a white background.
No text, no logo, no watermark.
EOS
```

`<<'EOS'` のシングルクォートは、bash の変数展開や history 展開を
prompt 側で起こさないための守りです。`$` を含む prompt を送るときに
効きます。

## 日本語 prompt と英語 prompt

実運用で両方通ることを確認しています。組み合わせは 4 通り。

- 生成 × 日本語
- 生成 × 英語
- 編集 × 日本語
- 編集 × 英語

例: 日本語の生成 prompt を手入力する場合。

```bash
printf 'built-in の画像生成機能だけを使ってください。\n正方形 1:1、1024x1024 で、白背景に青い球体を 1 枚描いてください。\n文字、ロゴ、透かしは入れないでください。\n' | codex exec -
```

例: 日本語での編集指示。

```bash
codex exec -i ./input.png "built-in の画像編集機能だけを使ってください。背景だけを白に変更し、被写体、構図、色味は維持してください。文字、ロゴ、透かしは加えないでください。"
```

運用上のコツは次の 2 つ。

- 「built-in の画像生成機能だけを使ってください」「built-in の画像編集
  機能だけを使ってください」と明示する。これは「SVG で代用する」「HTML
  で描く」といった別経路の回避になります。
- 「文字、ロゴ、透かしは入れないでください」は、少なくとも量産運用では
  テンプレの最後に固定で入れる価値があります。

## アスペクト比の現実

確認した限り、実用的に考えるべきサイズは 3 つです。

- `1024x1024` — 正方形
- `1024x1536` — 縦長
- `1536x1024` — 横長

これは OpenAI の image model ドキュメントで公開されているサイズと整合
します（[参照](#参照した公式ドキュメント)）。

よくある希望比率、たとえば Instagram Story の 9:16、Instagram フィードの
4:5、ヒーローバナーの 16:9 は、モデル側の実サイズが上記 3 つに寄る前提で
扱うのが素直でした。runner 側の aspect preset も、その前提で以下のように
内部マッピングしています（`--list-presets` で同内容を表示できます）。

| preset            | 実寸の扱い                               |
| ----------------- | ---------------------------------------- |
| `square`          | 1024x1024                                |
| `portrait`        | 1024x1536                                |
| `landscape`       | 1536x1024                                |
| `instagram_story` | 実運用では縦長（1024x1536 寄り）で扱う想定 |
| `instagram_post`  | 実運用では縦長で扱う想定                 |
| `hero_banner`     | 実運用では横長（1536x1024 寄り）で扱う想定 |
| `custom`          | `1408x768` のような `WIDTHxHEIGHT`      |

`custom` はモデル側で字義どおりに反映される保証のない「希望値」です。
近い公開サイズに寄る可能性を含んで運用してください。

## 1 枚から複数枚へ — runner の役割

1 枚なら one-liner で十分。ただし複数枚をまとめて回す段階で、次の 7 点を
毎回自前で書くと急に面倒になります。

- 実行前の prompt 目視確認（preview）
- 失敗時の retry
- ジョブ間の間隔
- Linux パス / Windows ドライブパス / WSL UNC パスの混在処理
- 生成物が期待先にコピーされなかった場合の `~/.codex/generated_images`
  からの回収
- 1 run ぶんの summary JSON と、ジョブごとの raw log
- 既存 PNG のうっかり上書き防止（デフォルト skip、明示で上書き）

`codex-image-batch.sh` はこの 7 点だけを素朴にカバーするための Bash 実装
です。特別な依存は持ちません（必要なのは `jq` と `python3` くらい）。

## doctor → preview → run の順序

新しいマシンで初めて触るときは、この順序が一番迷いが少ない。

```bash
bash ./codex-image-batch.sh --doctor
```

`--doctor` は、`jq` / `python3` など必要コマンド、`codex` の `PATH`、
`~/.nvm/.../bin/codex` のような fallback 候補、`image_generation`
feature の状態までまとめて表示します。

`codex` が `PATH` に無い場合は、実体を明示して同じ診断を走らせられます。

```bash
CODEX_BIN="$HOME/.nvm/versions/node/<your-version>/bin/codex" \
  bash ./codex-image-batch.sh --doctor
```

`<your-version>` は自分の Node バージョンに差し替えます。

```bash
bash ./codex-image-batch.sh --spec ./examples/codex-image-batch.sample.json --preview
```

`--preview` は、最終 prompt と実行予定の `codex exec` コマンドだけを
印字します。実際の生成は行われません。

```bash
bash ./codex-image-batch.sh --spec ./examples/codex-image-batch.sample.json --pause-at-end
```

デフォルトでは本実行の前に確認プロンプトが入ります。CI などで止めたく
ない時だけ `--no-prompt` を明示します。

```bash
bash ./codex-image-batch.sh --manual --pause-at-end
```

`--manual` は、JSON を書かずに対話で 1 ジョブだけ実行するモードです。

## JSON spec の形と読み方

ランナーが受け付ける JSON の root は 3 通りです。

- 単一ジョブの object
- ジョブ配列
- `defaults` と `jobs` を持つ object

実務では 3 つ目がいちばん扱いやすく、後から option を追加しやすい形。

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

ポイントは次の通り。

- `codex_model` は `codex exec --model` にそのまま渡る「モデル override」
  です。ランナーは値の妥当性チェックをしません。どの model 名を受け
  付けるかは、その時点の Codex CLI / アカウント側の挙動に依存します。
- 相対パスは、シェルの cwd ではなく **spec ファイル自身の場所** を基準に
  解決されます。フォルダを動かしても spec が壊れないのはこのためです。
- `mode` は `generate` か `edit`。`edit` のときは `input_image` または
  `input_images` を最低 1 つ指定します。
- `subject` と `scene` を分けて書くと、ランナー側が style/aspect と
  組み合わせて prompt を組み立てます。単純に書きたい時は `prompt` を
  1 本書けばそちらが優先されます。

同梱の sample は 2 本です。

- `examples/codex-image-batch.sample.json` — 生成系 5 ジョブ
- `examples/codex-image-edit-batch.sample.json` — 編集系 3 ジョブ

## 組み込みプリセット

アスペクト preset は上記「アスペクト比の現実」の通り。スタイル preset は
意図的に少なく置いてあります。

- `none`
- `watercolor`
- `cinematic`
- `pixel_art`
- `product_render`

`--list-presets` で常に最新の一覧を出せます。

## Fact check と debunk

よく耳にするが、そのままでは事実として扱えない話を整理します。

**「画像生成は Codex desktop app でしかできない」**

正確ではありません。Codex CLI の公式ドキュメントでは、CLI 自体で画像生成
と画像編集の両方をサポートする旨が明記されています（[参照](#参照した公式ドキュメント)）。
今回の検証も CLI 単体で完結しています。

**「GPT-5.4 と表示されているなら、GPT-5.4 本体が PNG を描いている」**

そこまで強くは言えません。観測できたのは「CLI の text 側で GPT-5.4 系が
使われていたこと」と「画像は Codex built-in の画像生成経由で出ていたこと」
までです。OpenAI の発表では Codex が `gpt-image-1.5` を使うと案内されて
いますが、CLI 上で内部の image model alias まではこちらから確認できて
いません。

**「OpenAI の API を直接叩かないと画像生成はできない」**

違います。API は便利ですが必須ではありません。CLI 単体で、このリポジトリ
のサンプルまで完結します。API ドキュメントは「モデル側が何サイズを公式に
サポートするか」の裏取りとして参照しました。

**「任意サイズ指定は字義どおりに返ってくる」**

観測の範囲ではそうなっていませんでした。実用上の現実は
`1024x1024`, `1024x1536`, `1536x1024` の 3 実寸に寄ります。

**「WSL の前提はどうでもいい」**

Codex の sandbox ドキュメントで、Linux / WSL2 では `bubblewrap` が推奨
前提として案内されています。環境が整っているほど失敗の原因切り分けが
早くなるので、無視しないほうが結果的に楽でした。

**「古いモデルでも同じように動く」**

このリポジトリでは証明していません。断定しないでください。この記録は
あくまで `codex-cli 0.121.0` + GPT-5.4 世代での観測に限定されています。

## 共有する前のチェック

このリポジトリ自身もそうですが、手元の検証結果を外に渡すときは、この
観点を通しておくと安全です。

- 個人のホームディレクトリ絶対パスが prompt / log / summary に残って
  いないか。ランナーは可能な限り相対パスに丸めて書き出します。
- 固有のキャラクター名やプロダクト名が残っていないか。サンプル prompt は
  汎用のもの（glass bottle, blue sphere, generic product photo など）に
  差し替えると安全です。
- ホスト名、Windows ユーザー名、私用メールアドレス、API キー、トークン、
  Node の固定バージョン文字列などが環境依存のメモに紛れていないか。
- 出力フォルダにそのまま共有できない画像が残っていないか。`.gitignore`
  は `examples/outputs/`, `examples/edited-outputs/`, `*.log.txt` を
  除外しています。

## オプション早見表

- `--spec PATH` — JSON spec ファイルのパス
- `--output-root PATH` — 出力ルートの上書き
- `--codex-bin PATH` — codex 実体を明示（環境変数 `CODEX_BIN` でも可）
- `--ui-mode auto|cli` — 入力モード選択（デフォルト `auto`）
- `--manual` — JSON を使わず手入力で 1 ジョブ
- `--preview` — prompt と command を表示するだけ
- `--doctor` — 環境診断のみ実行
- `--list-presets` — 組み込み preset の一覧
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
- `-h`, `--help` — ヘルプ

## ハマりやすい落とし穴

- Windows PowerShell でそのまま実行する。このパッケージは WSL の Bash
  向けです。
- JSON ファイルではなくフォルダのパスを貼る。ランナーが警告を出します。
- 新しい spec で preview をせずに本実行する。`--preview` は安価な安全装置。
- edit mode で入力画像を指定し忘れる。edit ジョブは最低 1 枚必要。
- 既存 PNG が自動上書きされると思い込む。デフォルトは skip。上書きしたい
  ときだけ `--overwrite`。
- `C:\...` や `\\wsl.localhost\...` は絶対に失敗すると思い込む。よくある
  形はランナー側で自動変換されます。

## 参照した公式ドキュメント

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
