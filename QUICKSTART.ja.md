# クイックスタート — Windows 11 の WSL2 から Codex で画像生成を試す

このガイドは、**「Codex も WSL2 もまだ触ったことがないが、今日のうちに
画像を 1 枚出してみたい」** という方に向けて、今回のフィールドレポート
で実際に通した流れを、そのまま手順書の形にまとめたものです。通しで
実行すると、手元でも 10〜20 分ほどに収まりました。

検証環境のバージョン一覧、観察内容の詳細、よく流れてくる話と今回の観察の
対比、runner の全オプションなどは [README.ja.md](README.ja.md) に
まとめてあります。

> この手順は、フィールドレポートでたどったのと同じ環境
> （Windows 11 + WSL2 + Ubuntu + Bash + `codex-cli 0.121.0`）で実際に
> 行った操作の記録です。推奨手順ではありません。お手元の環境に
> 合わせて置き換えてください。手元のバージョンを正確に記録したい場合は、
> [README.ja.md の「検証環境のバージョンと確認コマンド」節](README.ja.md#検証環境のバージョンと確認コマンド)
> に、差分を比較するためのコマンド一覧をまとめています。

---

## 0. このガイドの前提

- **OS**: 今回の記録は Windows 11 で取りました。WSL2 が動作する
  Windows 10 でも近い挙動になる可能性はありますが、本レポートでは
  確認していません。
- **アカウント**: OpenAI の ChatGPT アカウント、もしくは Codex を利用
  できるアカウント。初回はブラウザでの認可が入ります。
- **通信**: インストール中と初回ログイン中はインターネット接続が必要。
- **ディスク**: Ubuntu と Node 一式で数 GB 程度の空き。
- **コマンドの前提**: 以降のコマンドはすべて **WSL Ubuntu の Bash** に
  貼り付けて実行します。Windows PowerShell は対象外です。行頭の `$` や
  プロンプト記号は書いていないので、ブロックをそのままコピーして
  Enter で実行できます。
- **バージョンの確認**: 本レポート側の実測値、および手元の値を取るため
  のコマンドは
  [README.ja.md の「検証環境のバージョンと確認コマンド」節](README.ja.md#検証環境のバージョンと確認コマンド)
  にまとめています。差分が気になる場合は先にそちらを走らせておくと、
  後からの見直しが楽です。

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

`bubblewrap` は、Codex の公式ドキュメントで Linux / WSL2 の sandbox 前提
として挙げられているパッケージです（公式: https://developers.openai.com/codex/concepts/sandboxing#prerequisites ）。

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

手元の PNG を 1 枚用意して、今回試した最小の編集コマンドをそのまま
実行します。

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

- 詳しい仕様、アスペクト比の観察、JSON spec の形、および「よく流れて
  くる話と、今回の観察の対比」は
  [README.ja.md](README.ja.md) にまとめてあります。
- 実運用に近づけたい場合は、`examples/` からサンプル JSON を 1 本
  コピーして、prompt だけを自分の用途に差し替える方法が使いやすい
  構成でした。
- 成果物を外部に共有する際は、ログや summary に個人パス・社内固有の
  プロダクト名・ホスト名などが残っていないかをあらかじめ確認しておくと
  安全です。ランナーは可能な範囲で相対パスに丸めて出力しますが、
  prompt や入力画像名は手で整えたほうが確実です。
