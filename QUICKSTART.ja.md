# 再現用クイックガイド — 私が実際に走らせたコマンドの共有

この文書は、Codex CLI による画像生成・画像編集がどこまで動くかを
調べる過程で、私（TK2LAB）と Codex が実際にターミナルに入力した
コマンドを、そのままの順序で切り出した記録です。**初心者向けの導入
手順書でも、推奨手順でもありません。** 同じ結果が得られるかどうかを、
お手元の環境で確かめるためのリファレンスとしてお使いください。

> 「こうすればこうなります」ではなく、「このコマンドを私が走らせた
> とき、こういう結果だった」という形で書いています。再現性の確認や、
> ご自身の環境との差分を見比べる起点として読んでいただけると幸いです。

詳しい観察、バージョン一覧、アスペクト比の扱い、ツールのオプション、
よく流れてくる話と今回の観察の対比などは
[README.ja.md](README.ja.md) にまとめています。

---

## 私の環境（ここに書き出した全コマンドの前提）

当方で動作を確認した環境は次のとおりです。同じ環境でなければ動かないと
いうことではありませんが、結果が合わない場合に最初に見比べたい値でも
あります。

- **Host OS**: Windows 11
- **Runtime**: WSL2 上の Ubuntu（LTS）
- **Shell**: Bash
- **Codex CLI**: `codex-cli 0.121.0`
- **Codex feature 状態**: `codex features list` 上で `image_generation`
  が有効

他のパッケージ（Node.js, npm, jq, python3, bubblewrap など）の実測値と、
同じ値を取得するためのコマンドの一覧は
[README.ja.md の「検証環境のバージョンと確認コマンド」節](README.ja.md#検証環境のバージョンと確認コマンド)
にまとめてあります。

## 環境を揃える場合のフロー概要（公式ドキュメント中心）

各ツールのインストール手順は、当方で複製するよりも一次情報を
お読みいただく方が正確です。公式のリンクと、当方の環境で辿った順序
だけを共有します。

1. **Windows 11 + WSL2 + Ubuntu を用意する**
   Microsoft の公式手順を参照してください。管理者 PowerShell で
   `wsl --install` を実行するのが基本フローです。
   公式: https://learn.microsoft.com/windows/wsl/install
2. **Linux 側の基本パッケージを入れる**
   当方では Ubuntu 上で `jq` / `python3` / `bubblewrap` / `curl` /
   `git` を使える状態にしました。`bubblewrap` は Codex の sandbox
   前提として公式ドキュメントに挙げられています。
   公式: https://developers.openai.com/codex/concepts/sandboxing#prerequisites
3. **Node.js を入れる**
   当方では nvm 経由で LTS 系を使いました。Node のインストール方法は
   選択肢が多いので、好みのやり方で構いません。
   参考: https://nodejs.org/
4. **Codex CLI を入れてログインする**
   インストール方法、初回ログイン（ブラウザ認可）、feature の有効化
   手順は公式ドキュメントが一次情報です。
   公式: https://developers.openai.com/codex/cli

これらを済ませた状態で、`codex --version` と `codex features list` が
通ることが、以降のコマンドの前提になっています。当方での実測値は
`codex-cli 0.121.0` と、`image_generation` が `enabled` 表示でした。
同じでなくても試せますが、differ した場合は最初にここを見比べると
原因切り分けが早くなるはずです。

## 当方で入力したコマンド（順序通り）

以下は当方が順番に実行したコマンドです。同じ出力が得られるかどうかを
確かめる起点としてお使いください。どれも 1 行に収まる最小形です。

### 生成（画像 1 枚、英語 prompt、白背景の青い球）

```bash
printf 'Use the built-in image generation capability only.\nGenerate a square 1:1 image of a blue sphere on a white background.\nNo text, no logo, no watermark.\n' | codex exec -
```

当方の環境では、実行後のログに出力 PNG のパスが表示されました。
パスが示されない場合や、指定先にファイルがなかった場合、
`~/.codex/generated_images/` 以下を `ls` すると該当ファイルが見つかる
ことが何度かありました。

### 生成（日本語 prompt）

```bash
printf 'built-in の画像生成機能だけを使ってください。\n正方形 1:1、1024x1024 で、白背景に青い球体を 1 枚描いてください。\n文字、ロゴ、透かしは入れないでください。\n' | codex exec -
```

当方の環境では、日本語 prompt でも生成が通りました。英語 prompt と
同じ構造（冒頭で built-in 機能の明示、終わりで no text / logo /
watermark）にそろえると、後から比較しやすい形でした。

### 編集（入力画像 1 枚）

```bash
codex exec -i ./input.png "Use the built-in image editing capability only. Change the background to white. Keep the subject, composition, and colors intact. No text, no logo, no watermark."
```

編集モードでは `-i ./input.png` で添付画像を指定します。当方では
背景差し替えのような指示で通りました。

### 編集（入力画像 2 枚、1 枚目を base、2 枚目を reference）

```bash
codex exec -i ./base.png -i ./reference.png "Use the first image as the base. Transfer the palette and mood from the second image while preserving the composition and main subject of the first image. No text, no logo, no watermark."
```

`-i` を 2 つ並べると、2 枚目の画像を reference として扱う形が通り
ました。3 枚以上は今回試していません。

## 当方が書いた補助スクリプトについて

当方では、画像 1 枚の動作確認が済んだ時点で「複数枚を JSON にまとめて
連続実行できると便利だよね」という理由だけで小さなスクリプトを
用意しました。それが同梱の `codex-image-batch.sh` です。**お勧めの
ツールではなく、当方の作業のためだけに書いた簡易ユーティリティ** です。
同じ目的には他のやり方もあります（並列実行、Make / Taskfile、
独自 Python スクリプト等）ので、好みに合わせて差し替えてください。

当方で手元の動作確認に使ったコマンドはこの 4 つでした。

```bash
# 依存と Codex 検出の診断のみ（Codex 本体は呼ばない）
bash ./codex-image-batch.sh --doctor

# サンプル spec の prompt と command を表示するだけ（生成はしない）
bash ./codex-image-batch.sh --spec ./examples/codex-image-batch.sample.json --preview

# サンプル spec を実際に実行（実行前に確認プロンプトあり）
bash ./codex-image-batch.sh --spec ./examples/codex-image-batch.sample.json --pause-at-end

# JSON を書かず 1 ジョブだけ対話で流す
bash ./codex-image-batch.sh --manual --pause-at-end
```

スクリプトの入力スキーマ（単一 object / 配列 / `defaults` + `jobs`）、
preset 一覧、全オプション、挙動の詳細は [README.ja.md](README.ja.md)
にまとめています。

## 結果が合わないとき

当方でも環境再構築のたびに差分が出ました。確認した切り分けの起点を
共有します。

- `codex` が見つからない: nvm の初期化が shell に反映されていない
  可能性があります。新しいターミナルを開くか、`~/.bashrc` で nvm が
  source されているか確認してください。
- `image_generation` が無効表示: 当方の環境では、`codex` を 1 度
  対話で起動して簡単な生成を頼んだ後に有効側に表示が変わることが
  ありました。これは当方の観察で、公式の動作仕様として断定できる
  範囲ではないため、最終的には公式ドキュメントの記述を優先して
  ください。設定ファイルによる有効化例は
  [README.ja.md](README.ja.md) で触れています。
- `bubblewrap` 警告: `sudo apt install -y bubblewrap` で入ります。
- PowerShell でコマンドが通らない: この文書のコマンドは WSL の
  Bash 前提です。Windows PowerShell ネイティブでの挙動は検証範囲外
  です。

## 次にできること

- 同じコマンドを走らせた結果が手元と当方で差があれば、それは当方には
  見えていない貴重な観察です。よろしければ issue や別チャネルで
  共有いただけると、このレポートの信頼性を上げる助けになります。
- サンプル JSON (`examples/`) を 1 本コピーして prompt を差し替える
  形が、簡単に自分のユースケースで試す入口としては軽量でした。
- 当方の環境と異なる条件（別ディストリビューション、別モデル、別
  サイズ等）での結果を独自に追試すると、このレポートの対象外に出ます。
  結果はそちらの観察として扱ってください。
