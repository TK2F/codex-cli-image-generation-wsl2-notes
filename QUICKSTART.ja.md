# 再現用クイックガイド — 私が実際に走らせたコマンドの共有（2026-04-18 時点）

Codex CLI で画像生成と画像編集が本当にできるのかを、私（TK2LAB）が Codex と
一緒に確かめていた過程で実際にターミナルへ入力したコマンドを、そのままの
順序で切り出した記録です。自分の覚書として残していたものを、同じ疑問を
持つ方向けに共有しています。**お勧めの手順ではなく、初心者向けの導入
チュートリアルでもありません。** 「こう試したら、こうなった」という一
事例として、ご自身の環境で同じコマンドを走らせて結果を見比べるための
リファレンスとしてお使いください。

> これは 2026-04-18 時点の個人的な検証メモです。Codex CLI はアップデート
> が早いため、今後のリリースや仕様変更、公式発表で挙動が変わる可能性が
> 十分にあります。ここに書いた内容が数週間後も正確とは限らない点を
> 前提に、参考情報としてご利用ください。もっと良いコマンドの書き方、
> フラグの扱い方、ツールの構成はきっとあるはずなので、ぜひご自身でも
> いろいろ試してみてください。

詳しい検証結果、バージョン一覧、アスペクト比の扱い、ツールの全オプション、
このリポジトリで何を検証して、結果どうだったかを整理した内容は [README.ja.md](README.ja.md)
にまとめています。

---

## 私の環境（ここに書き出した全コマンドの前提）

私が動作を確認したのは次の環境です。同じ環境でなければ動かないという
ことではありませんが、結果が合わない場合に最初に見比べたい値でも
あります。

- **Host OS**: Windows 11
- **Runtime**: WSL2 上の Ubuntu（LTS）
- **Shell**: Bash（Windows PowerShell ネイティブは検証範囲外）
- **Codex CLI**: `codex-cli 0.121.0`

他のパッケージ（Node.js, npm, jq, python3, bubblewrap など）の実測値と、
同じ値を取得するためのコマンド一覧は、
[README.ja.md の「検証環境のバージョンと確認コマンド」節](README.ja.md#検証環境のバージョンと確認コマンド)
にまとめてあります。

## 環境を揃える場合のフロー概要（公式ドキュメント中心）

各ツールのインストール手順は、私が複製するより一次情報を読んでいただく
ほうが正確です。私が辿った順序と、公式ドキュメントへのリンクだけを
ここに残します。

1. **Windows 11 + WSL2 + Ubuntu を用意する**
   Microsoft の公式手順に従うのが早いです。基本は管理者 PowerShell で
   `wsl --install` を一度だけ実行する流れです。
   公式: https://learn.microsoft.com/windows/wsl/install
2. **Linux 側の基本パッケージ**
   私は Ubuntu 上で `jq` / `python3` / `bubblewrap` / `curl` / `git`
   を使える状態にしました。`bubblewrap` は Codex の sandbox 前提として
   公式ドキュメントに記載されています。
   公式: https://developers.openai.com/codex/concepts/sandboxing#prerequisites
3. **Node.js**
   私は nvm 経由で LTS を入れました。Node の入れ方はいろいろあるので、
   お好みのやり方で問題ありません。
   参考: https://nodejs.org/
4. **Codex CLI のインストールと初回ログイン**
   インストール、ブラウザ認可、feature の状態確認はすべて公式ドキュ
   メントに書かれています。
   公式: https://developers.openai.com/codex/cli

これらを済ませた状態で `codex --version` と `codex features list` が
通ることが、以降のコマンドの前提です。私の環境では `codex --version`
が `codex-cli 0.121.0` を返しました。

## `image_generation` まわりで、追試後も残った実運用上の結論

インストール直後の私の環境では、`codex features list` の出力で
`image_generation` が無効側（`false`）に表示されていました。これは私が
見えた状態であり、公式の初期値としての断定ではありません。2026-04-19
の追試（`review-evidence/20260419-054302/`）では
`image_generation = true` の状態で生成・編集とも通りました。そこまで
踏まえた実運用上の結論は次の 3 通りです。

**方法 A: `~/.codex/config.toml` に設定を書く**

```toml
[features]
image_generation = true
```

継続的に使うなら、この経路が一番安定していました。

**方法 B: Codex の feature 管理サブコマンドを使う**

```bash
codex features enable image_generation
```

これは Codex 側のコマンドで同じ設定を書き込む方法です。

**方法 C: `codex exec` の実行時に `--enable image_generation` を付ける**

```bash
codex exec --enable image_generation -
```

このフラグは有効な指定ですが、2026-04-19 の追試では
`image_generation = true` が既に入っている環境では実質 no-op でした。
同梱スクリプトの `codex-image-batch.sh` は、feature が既に有効な場合は
付けず、未有効の場合だけ内部で `--enable image_generation` を追加する
実装にしています。

新しい CLI バージョンでは既定値や有効化の手順が変わる可能性もあります。
今後試される場合は、まず `codex features list` の表示を確認し、公式
ドキュメントを優先してください。

## 私が実際に入力したコマンド（順序通り）

以下は、私が順に実行したコマンドです。どれも 1 行に収まる最小形で、
私の環境では画像生成・編集自体は通りました。ただし 2026-04-19 の追試
では、ユーザー指定の保存先には PNG が出ませんでした。

### 生成（画像 1 枚、英語 prompt、白背景の青い球）

```bash
printf 'Use the built-in image generation capability only.\nGenerate a square 1:1 image of a blue sphere on a white background.\nNo text, no logo, no watermark.\n' | codex exec --enable image_generation -
```

2026-04-19 の追試では、Codex が表示した "Output path" は実在しないこと
がありました。実ファイルは
`~/.codex/generated_images/<session-id>/ig_*.png` にのみ保存されました。

（`config.toml` で `image_generation = true` を有効化済みの環境なら、
`--enable image_generation` のフラグは省略しても通りました。）

### 生成（日本語 prompt）

```bash
printf 'built-in の画像生成機能だけを使ってください。\n正方形 1:1、1024x1024 で、白背景に青い球体を 1 枚描いてください。\n文字、ロゴ、透かしは入れないでください。\n' | codex exec --enable image_generation -
```

私の環境では日本語 prompt でも生成が通りました。英語 prompt と同じ
構造（冒頭で built-in 機能を明示、末尾で no text / logo / watermark）
に揃えると、後から比較しやすい形でした。

### 編集（入力画像 1 枚）

```bash
codex exec --enable image_generation -i ./input.png "Use the built-in image editing capability only. Change the background to white. Keep the subject, composition, and colors intact. No text, no logo, no watermark."
```

編集モードでは `-i ./input.png` で添付画像を指定します。私の環境では
背景差し替えのような指示で通りました。

### 編集（入力画像 2 枚、1 枚目を base、2 枚目を reference）

```bash
codex exec --enable image_generation -i ./base.png -i ./reference.png "Use the first image as the base. Transfer the palette and mood from the second image while preserving the composition and main subject of the first image. No text, no logo, no watermark."
```

`-i` を 2 つ並べたケースは prompt どおりに通りましたが、これは
「1 枚目 base / 2 枚目 reference」という CLI 仕様を保証するものでは
ありません。今回の prompt がそう解釈されただけ、と読むのが安全です。
3 枚以上は今回試していません。

## PNG の実保存先

2026-04-19 の追試で一番大きかった差分はここです。画像生成と画像編集は
成功しましたが、Codex は prompt で指示した workdir 直下には PNG を
置きませんでした。実際の保存先は次の形でした。

```text
~/.codex/generated_images/<session-id>/ig_*.png
```

回収するときは、ログ冒頭の `session id` を見て手動コピーします。

```bash
session_id="019da255-d906-7831-8a2d-0912b86d3e00"
cp ~/.codex/generated_images/"$session_id"/*.png ./recovered-output.png
```

同じ追試では `--full-auto -c sandbox_workspace_write.network_access=true`
を付けても挙動は変わりませんでした。この範囲では network access は
必須ではありませんでした。

## 私が書いた補助スクリプトについて

画像 1 枚の動作確認が済んだ段階で、「複数枚を JSON にまとめて順に
流せると便利だな」という個人的な理由で、小さな Bash スクリプトを
書いておきました。それが同梱の `codex-image-batch.sh` です。
**お勧めのツールとして配布するものではなく、私の作業の都合で書いた
簡易ユーティリティをそのまま共有しているだけです。** 同じ目的には、
並列実行、Make / Taskfile、独自の Python ドライバ、既存の CI 系
ツールなど、もっと洗練された選択肢があるはずなので、ご自身の作業に
合わせて自由に差し替えて試してみてください。

私が手元の確認に使ったコマンドはこの 4 つです。

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

入力 JSON の形式（単一 object / 配列 / `defaults` + `jobs`）、preset 一覧、
全オプション、挙動の詳細は [README.ja.md](README.ja.md) にまとめてあり
ます。

## 不具合時に試した切り分けポイント

私の環境で発生した不具合と試した方法を共有します。

- `codex` が見つからない: nvm の初期化が shell に反映されていない
  可能性があります。新しいターミナルを開くか、`~/.bashrc` で nvm が
  `source` されているかをご確認ください。
- `image_generation` が無効表示のまま: 上記の方法 A
  （`~/.codex/config.toml`）、方法 B（`codex features enable
  image_generation`）、方法 C（`--enable image_generation`）を確認して
  ください。追試では、config が入っている環境では方法 C は冗長でした。
- 指定した保存先に PNG がない: ログ先頭の `session id` を見て、
  `~/.codex/generated_images/<session-id>/` を確認してください。
- `bubblewrap` の警告が出る: Ubuntu では `sudo apt install -y
  bubblewrap` で入ります。
- PowerShell でコマンドが通らない: この文書のコマンドはすべて WSL の
  Bash 前提です。Windows PowerShell ネイティブは私の検証範囲外です。

## 最後に

この文書は 2026-04-18 時点の私の環境で試した結果の記録にすぎません。お手元の
環境で同じ結果が得られない、ということは十分に考えられます。差分が
出たときは「このレポートのどこが古くなっている」あるいは「間違っている」
可能性を示しているので、公式リリースノートやコミュニティ情報等と
突き合わせていただければ幸いです。

より良いコマンドの書き方、prompt の組み立て方、補助ツールの設計は
きっと他にもあります。ここにある内容を起点に、ぜひご自身の環境で
いろいろ試してみてください。
