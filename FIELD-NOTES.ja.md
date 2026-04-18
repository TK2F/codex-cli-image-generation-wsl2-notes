# 検証ノート: WSL2 Ubuntu 上の Codex CLI 画像生成

これは、実際に試して分かったことだけを残した公開向けの記録です。  
何が動いたか、何はまだ断定していないか、どこが実用の分かれ目だったかを、あとから見返して役に立つ形でまとめています。

private GitHub に置く前提で、他の人にも役立つだけの情報は残しつつ、個人パスやマシン名のような不要な情報は落としました。

検証者:

- TK2LAB
- Codex

検証日:

- 2026-04-19
- `codex-cli 0.121.0`

## 何が面白かったのか

青い球を 1 枚出せたこと自体より、Codex CLI の画像生成が「ただのデモ」ではなく、少し整えると実務の入口として十分使えると分かったのが面白いポイントでした。

要するに効いたのは次の 4 つです。

- feature gate がどこにあるか
- 環境をどう確認するか
- 出力ファイルが実際にはどこへ落ちるか
- 1 回限りの prompt から、繰り返し使える batch へどう移るか

このへんが分かると、次の人が同じところで詰まらずに済みます。

## 今回の検証で見たかったこと

焦点は 4 つでした。

1. WSL2 Ubuntu 上の Codex CLI で本当に画像生成と画像編集が回るか
2. 安定して使う前に何を有効化・確認すべきか
3. まず使える最小コマンドは何か
4. どの段階から補助ツールを足す価値が出るか

## 確認できたこと

- Codex CLI から WSL2 Ubuntu の terminal workflow のまま画像生成と画像編集ができた
- この検証環境では `codex-cli 0.121.0` が `image_generation` feature を持っていた
- 生成は `codex exec -` の one-liner で回った
- 編集は `codex exec -i ...` で回った
- 日本語 prompt でも英語 prompt でも通った
- 実用上のサイズ感は次の 3 バケットで考えるのが分かりやすかった
  - square
  - portrait
  - landscape
- 画像が 1 枚から複数枚に増えた時点で、小さな runner を持つ価値が出た

## 今回の検証環境

- WSL2
- Ubuntu
- Bash
- Codex CLI `0.121.0`
- GPT-5.4 系の text model flow を観測

つまり、この文書で事実として言っているのはこの範囲です。ここから外れる環境は「たぶん動くかもしれない」ではあっても、「ここで検証した」とは書きません。

## 断定していないこと

- 各 run で CLI の内部がどの image-model alias を選んでいたかは直接確認していない
- どんな任意サイズでも字義通りに出せるとは言っていない
- native Windows PowerShell が最良の実行面だとは言っていない
- プロダクト発表だけで CLI の詳細すべてを証明したとは扱っていない

## Fact Check と Debunk

### 「画像生成は desktop app 限定では？」

そこまでは言えません。

公式の Codex CLI docs には、CLI で画像生成や画像編集を直接行えると書かれています。

参照:
- https://developers.openai.com/codex/cli

### 「GPT-5.4 と出ているなら、GPT-5.4 自体が PNG を吐いているんでしょ？」

そこまで強くは言えません。

今回観測したのは:

- CLI の text 側のモデルとして GPT-5.4 系を使っていたこと
- 画像生成は Codex の built-in image generation capability 経由で動いていたこと

一方で OpenAI の公式発表では、Codex は `gpt-image-1.5` を使って画像生成と反復ができると案内されています。ただし、CLI 上で内部の image-model alias までは見えていませんでした。

参照:
- https://openai.com/index/codex-for-almost-everything/
- https://developers.openai.com/codex/cli

### 「API を直接叩かないと使えないのでは？」

違います。

API は便利ですが必須ではありません。CLI 単体でも十分に意味のある workflow になりました。API docs は、OpenAI 側の画像モデルや practical size の理解に役立つ参照先として使いました。

参照:
- https://developers.openai.com/api/docs/guides/tools-image-generation
- https://developers.openai.com/api/docs/models/all

### 「指定サイズは何でもそのまま通るのでは？」

そうは見えませんでした。

実務上は次の 3 バケットで考えるのが素直でした。

- `1024x1024`
- `1024x1536`
- `1536x1024`

これは OpenAI の image model docs に出ている size とも整合します。

参照:
- https://developers.openai.com/api/docs/models/gpt-image-1.5/
- https://developers.openai.com/api/docs/models/gpt-image-1

### 「WSL の前提は気にしなくていいのでは？」

気にした方がいいです。

公式の sandboxing docs でも、Linux / WSL2 では `bubblewrap` が推奨前提として案内されています。実際、環境の整い方で体験の滑らかさは変わります。

参照:
- https://developers.openai.com/codex/concepts/sandboxing#prerequisites

### 「GPT-5.4 より前のモデルでも同じように動くはず」

それはこの文書では事実として書きません。

今回ここで確認したのは、GPT-5.4 世代の Codex CLI workflow だけです。より前の model については、この package を「同じように動く証拠」として読まないでください。

## 実際に役立ったコマンド

### まずは最小の生成

```bash
printf 'Use the built-in image generation capability only.\nGenerate a square 1:1 image of a blue sphere on a white background.\nNo text, no logo, no watermark.\n' | codex exec -
```

### 1 枚画像の編集

```bash
codex exec -i ./input.png "Use the built-in image editing capability only. Change the background to white. Keep the subject, composition, and colors intact. No text, no logo, no watermark."
```

### 2 枚画像の編集

```bash
codex exec -i ./base.png -i ./reference.png "Use the first image as the base. Transfer the palette and mood from the second image while preserving the composition and main subject of the first image. No text, no logo, no watermark."
```

### 最初にやる確認

```bash
codex --version
codex features list
```

## どこから「ツールを足す価値がある」になったか

1 回限りなら one-liner で十分でした。  
ただし、複数枚をまとめて回す段階で次が効いてきました。

- JSON spec
- preview
- retry
- ジョブ間待機
- Windows / WSL 混在環境での path 正規化
- summary JSON
- raw log

そのため、この配布物には direct usage の説明と runner の両方を入れています。

## セキュリティと公開前レビュー

この package は、workflow として役に立つ部分だけを残し、公開に不要なローカル事情を引きずらない形に整えています。

## 実務的なおすすめ順

初見ならこの順が一番混乱が少ないです。

1. `--doctor`
2. `--preview`
3. direct one-liner を 1 本
4. その後で JSON と runner へ進む

最初から全部を覚えるより、この順の方が早いです。

## 実際に参照した公式ドキュメント

- Codex CLI docs  
  https://developers.openai.com/codex/cli
- Codex sandboxing と WSL/Linux 前提  
  https://developers.openai.com/codex/concepts/sandboxing#prerequisites
- Image generation tool guide  
  https://developers.openai.com/api/docs/guides/tools-image-generation
- OpenAI models catalog  
  https://developers.openai.com/api/docs/models/all
- GPT Image 1.5 model page  
  https://developers.openai.com/api/docs/models/gpt-image-1.5/
- Product announcement: Codex for (almost) everything  
  https://openai.com/index/codex-for-almost-everything/
