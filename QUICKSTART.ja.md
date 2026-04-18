# クイックスタート — Windows 11 の WSL2 から Codex で画像生成を試す

このガイドは、**「Codex も WSL2 もまだ触ったことがないが、今日のうちに
画像を 1 枚出してみたい」** という方を、最短で生成と編集まで案内する
ためのものです。通しで実行しても 10〜20 分ほどに収まる想定です。

詳しい検証内容、仕様、debunk、アスペクト比の扱いなどは
[README.ja.md](README.ja.md) にまとまっています。

> これは TK2LAB と Codex が手を動かして試した実験の記録です。正式な
> ベンチマークや網羅的な検証ではないので、環境が少し違うだけでも挙動が
> 変わる可能性があります。ここに書いているのは「今回の条件で実際に動いた
> こと」に限定してあります。

---

## 0. このガイドの前提

- **OS**: Windows 11（Windows 10 でも WSL2 が動いていれば可）
- **アカウント**: OpenAI の ChatGPT アカウント、もしくは Codex を利用
  できるアカウント。ログイン時にブラウザでの認可が入ります。
- **通信**: インストール中と初回ログイン中はインターネット接続が必要。
- **ディスク**: Ubuntu と Node 一式で数 GB 程度の空き。
- **コマンドの前提**: ここから先のコマンドはすべて **WSL Ubuntu の
  Bash** に貼り付けて実行します。Windows PowerShell ではありません。
  （コマンドブロックはそのままコピーして Enter で OK です。行頭の
  `$` やプロンプト記号は付けていません。）

## 1. WSL2 + Ubuntu を用意する

Windows 側で、スタートメニューから **PowerShell を管理者として** 開き、
1 度だけ次を実行します。すでに Ubuntu が動いている人はここは飛ばして
ください。

```powershell
wsl --install
```

完了後、PC を再起動し、スタートメニューから **Ubuntu** を開きます。
最初の起動で Linux ユーザー名とパスワードを作成する画面になります。

以降の手順はすべて、この Ubuntu のターミナル（Bash）で実行します。

公式: https://learn.microsoft.com/windows/wsl/install

## 2. 基本パッケージと Node.js を入れる

Ubuntu のターミナルで次を実行します。`sudo` のパスワードを 1 回聞かれる
ことがあります。

```bash
sudo apt update
sudo apt install -y curl git jq python3 bubblewrap
```

`bubblewrap` は Codex の sandbox 推奨前提です（公式:
https://developers.openai.com/codex/concepts/sandboxing#prerequisites ）。

Node.js は nvm 経由が扱いやすい。

```bash
curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm install --lts
node --version
```

`node --version` が `v...` を返せば OK。

## 3. Codex CLI をインストールしてログイン

パッケージ名や配布チャネルは時期で変わりうるため、公式ドキュメントの最新
手順に従ってください: https://developers.openai.com/codex/cli

目安として、nvm で入れた Node 上から npm グローバル経由でインストール
したあと、`codex` コマンドが通れば準備完了です。

```bash
codex --version
codex features list
```

`codex --version` が `codex-cli` のバージョンを返し、`codex features list`
の中に `image_generation` が含まれていれば、ここまでの下準備は完了です。

初回はブラウザでのログイン（OpenAI アカウントでの認可）が発生します。
画面の指示に沿って Windows 側ブラウザで認可し、ターミナルに戻ると続行
できます。

`image_generation` が無効表示の場合は、まず `codex` を 1 度対話モードで
起動して画像を 1 枚出すと、機能が自動で有効化されるケースがあります。
手動で設定ファイルを書く方法もあります（`~/.codex/config.toml` に
`[features]` セクションを作り `image_generation = true` を追加）。
後述のランナーは、どちらの場合でも `codex exec --enable image_generation`
を内部で付けて動作します。

## 4. まず 1 枚生成してみる（one-liner）

Codex CLI だけを使った、副作用の少ない最小コマンドはこれです。カレント
ディレクトリを気にせず、まずは `~` でもデスクトップでも好きな場所で
OK。

```bash
printf 'Use the built-in image generation capability only.\nGenerate a square 1:1 image of a blue sphere on a white background.\nNo text, no logo, no watermark.\n' | codex exec -
```

うまく動けば、コマンドの実行ログに画像ファイルのパスが表示されます。
コピー先が指定されていないときは `~/.codex/generated_images/` 以下に
保存されていることが多いので、そこを `ls` で確認してください。

日本語 prompt でも動きます。

```bash
printf 'built-in の画像生成機能だけを使ってください。\n正方形 1:1、1024x1024 で、白背景に青い球体を 1 枚描いてください。\n文字、ロゴ、透かしは入れないでください。\n' | codex exec -
```

## 5. 1 枚の画像を編集する

手元の PNG を 1 枚用意して、それを編集する最短コマンド。

```bash
codex exec -i ./input.png "Use the built-in image editing capability only. Change the background to white. Keep the subject, composition, and colors intact. No text, no logo, no watermark."
```

2 枚使いたい（1 枚目を base、2 枚目を reference）ときは `-i` を 2 つ
並べます。

```bash
codex exec -i ./base.png -i ./reference.png "Use the first image as the base. Transfer the palette and mood from the second image while preserving the composition and main subject of the first image. No text, no logo, no watermark."
```

## 6. `codex-image-batch.sh`（付属ランナー）を使う

この先で複数枚をまとめて回したい、preview で確認してから走らせたい、
失敗時に retry したい、となったら付属ランナーの出番です。

このリポジトリをクローンまたはダウンロードして、WSL 側の任意の場所に
置きます（Windows エクスプローラー上の `\\wsl.localhost\Ubuntu\home\...`
からでもアクセスできます）。以下はリポジトリ直下で実行する前提です。

まずは doctor で環境確認。

```bash
bash ./codex-image-batch.sh --doctor
```

`codex` が `PATH` に無ければ、実体を明示して同じコマンドを叩けます。

```bash
CODEX_BIN="$HOME/.nvm/versions/node/<your-version>/bin/codex" \
  bash ./codex-image-batch.sh --doctor
```

次に sample JSON を preview。実行はされず、prompt と command だけが
表示されます。

```bash
bash ./codex-image-batch.sh --spec ./examples/codex-image-batch.sample.json --preview
```

問題なさそうなら実行。

```bash
bash ./codex-image-batch.sh --spec ./examples/codex-image-batch.sample.json --pause-at-end
```

JSON を書かずに 1 本だけ対話実行したいときは manual モード。

```bash
bash ./codex-image-batch.sh --manual --pause-at-end
```

## 7. うまくいかないとき

- **`codex: command not found`**
  Node のインストールで PATH が反映されていない可能性があります。
  ターミナルを開き直すか、次を実行して再読み込みしてください。
  ```bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  ```
- **`image_generation` が有効にならない**
  1 度 `codex` を対話で起動して簡単な生成を試すか、
  `~/.codex/config.toml` に `[features]\nimage_generation = true` を
  追加します。ランナーは `--enable image_generation` を内部で付けるので
  その上で `codex-image-batch.sh --doctor` を再実行すれば状況が分かります。
- **`bubblewrap` が無いと言われる**
  `sudo apt install -y bubblewrap` を実行し、ターミナルを開き直して
  ください。
- **PowerShell でコマンドがエラーになる**
  このガイドは WSL の Bash 前提です。スタートメニューから Ubuntu を
  開いてください。

## 8. 次にすること

- 詳しい仕様、debunk、アスペクト比の現実、JSON spec の形などは
  [README.ja.md](README.ja.md) にまとめてあります。
- サンプル JSON を `examples/` から 1 本コピーして prompt を差し替える
  のが、実運用に移る一番短い道です。
- 成果物を外部に共有する際は、ログや summary に個人パス・社内固有の
  プロダクト名・ホスト名などが残っていないかをあらかじめ確認しておくと
  安全です。ランナーは可能な範囲で相対パスに丸めて出力しますが、
  prompt や入力画像名は手で整えたほうが確実です。
