# MAINTAINER-NOTES.md — Codex 再確認用の内部メモ

> このファイルは公開リポジトリに含まれていますが、読者向けのドキュメントとは
> 別の、**リポジトリのメンテナンス用** のメモです。TK2LAB と Codex が
> 2026-04-18 時点の検証結果をまとめたあと、Codex 側で改めて裏取りして
> ほしい項目、ドキュメントの事実性・表現を確認してほしい項目、追加で
> 生成して掲載する価値がありそうな画像例、運用メモを整理しています。

---

## 0. Codex にハンドオフする手順（このドキュメントの使い方）

このメモは、次に Codex と会話する機会を使って本リポジトリ全体の事実性を
再確認するための台本です。具体的な流れは以下の通りです。

### どこにある文書か

- GitHub 上: https://github.com/TK2F/codex-cli-image-generation-wsl2-notes/blob/main/MAINTAINER-NOTES.md
- ローカル: `publish/codex-cli-image-generation-wsl2-notes/MAINTAINER-NOTES.md`
- 公開状態: private repo（TK2LAB と招待済みコラボレーターのみ閲覧可）

### どう Codex に引き継ぐか

**(A) 新しい Codex 対話セッションを起動し、次のプロンプトテンプレートを貼り付ける。**

```
以下は、私 (TK2LAB) と Codex の 2026-04-18 時点の検証結果を
まとめた個人メモのリポジトリです（private）。

https://github.com/TK2F/codex-cli-image-generation-wsl2-notes

リポジトリ内の次のファイルを順に読んでレビューをお願いします。

- README.md
- README.ja.md
- README.en.md
- QUICKSTART.ja.md
- QUICKSTART.en.md
- CHANGELOG.md
- codex-image-batch.sh
- examples/codex-image-batch.sample.json
- examples/codex-image-edit-batch.sample.json
- MAINTAINER-NOTES.md

確認事項は MAINTAINER-NOTES.md のセクション 1 とセクション 3 に
チェックリスト形式でまとめてあります。各項目について、現行の
Codex CLI / OpenAI 公式ドキュメントと照らし合わせ、次の 3 点を
返してください。

1. 項目番号
2. 状態: ✓ 一致 / ✗ 要修正 / ? 未確定
3. 根拠: 公式ドキュメント URL または再実行結果。要修正の場合は
   該当ファイル名・行番号とともに具体的な改訂案を Markdown で。

応答は、MAINTAINER-NOTES.md のチェックリスト各表の「Codex レビュー
メモ」列にそのまま貼り付けられる行区切りの Markdown 形式で出して
ください。

セクション 2 の追加画像例については、ポリシー・権利・品質の観点
から掲載を推奨するかどうか、推奨する場合の優先度を付けて返して
ください。画像そのものを生成できる環境があれば、指定のコマンドを
実行して `examples/gallery/` に置くところまでお願いします（掲載の
最終判断は私が行います）。

最後に、ドキュメント全体を通じて、事実と異なる記述・誇張・過度な
断定・公開すべきでない情報が残っていないかをスキャンし、見つけた
ものをリスクの高い順で列挙してください。
```

**(B) Codex 側の応答を受け取ったら、私（TK2LAB）が以下の流れで反映する。**

1. Codex の提案する改訂案を読む
2. 事実関係に納得できるものは `git` コミットで反映
3. 不確か・判断保留のものは本ドキュメントに「要再確認」として追記
4. サンプル画像は EXIF 除去・権利確認の上で `examples/gallery/` に配置
5. 反映後、`CHANGELOG.md` に検証日（例: `## 2026-05-xx — review refresh`）として追記

**(C) Codex とのセッションを閉じたら、次回のために本ファイルのチェックリストを更新する。** 状態が `✓` で確定したものは「確認済み」タグを付け、`?` で残ったものは次回の宿題として保持します。

---

## 1. ドキュメント記述の追認チェックリスト

下記の項目は、Codex と TK2LAB で検証しながら書き下ろしたものですが、
内容の最新性・表現の正確さを高めるため、Codex 側でもう一度読み直して
確認してほしい一覧です。「Codex レビューメモ」列に状態と根拠を記入
していってください。

| # | 確認項目 | 該当箇所 | 現在の記述の趣旨 | 受入れ基準 | Codex レビューメモ |
| --- | --- | --- | --- | --- | --- |
| 1 | `codex features list` で `image_generation` が既定で `false` として表示されること（最新 CLI でも同じか） | README.ja.md / README.en.md の「`image_generation` は既定で無効だったので…」 | 2026-04-18 時点の検証結果として `false` だったと記載 | 公式ドキュメントまたは最新版インストール直後のコマンド出力が同様であることを確認できる | |
| 2 | `codex exec --enable image_generation` が有効なフラグの組み合わせであること | README 両版および最小コマンド例、`codex-image-batch.sh` 821, 842 行あたり | 当該フラグで一時的に有効化し画像生成が通ったと記載 | `codex exec --help` または Codex CLI docs で `--enable` が現行フラグとして掲載されている | |
| 3 | `~/.codex/config.toml` の `[features]` セクションに `image_generation = true` を書くことで恒久的に有効化できる挙動が現行 CLI にあること | 上記同節 | 当方で動作を確認した方法として明示 | 公式ドキュメントに同等の設定パスが示されているか、少なくとも同パスで有効化できることを Codex 側でも再現できる | |
| 4 | `codex exec` に対する `-i` フラグで画像添付、2 枚以上の `-i` を重ねたときの解釈（1 枚目 base / 2 枚目 reference）が現行仕様と矛盾しないこと | 最小コマンド節、`printf` 節 | `-i` を 2 つ重ねた場合の挙動として記載 | Codex CLI docs の `exec` セクションでの記述、または再現テストで同挙動 | |
| 5 | `codex exec -` での stdin 経由 prompt 受け渡しが現行 CLI でも正式な使い方であること | 「`printf` を使った理由と読み方」 | POSIX `printf` との組み合わせで最小コマンドを構成できると記載 | `codex exec --help` に `-` による stdin 指定の説明があるか、同等の動作が docs に記載 | |
| 6 | 画像サイズについて、現行モデルが `1024x1024` / `1024x1536` / `1536x1024` を中心にサポートする旨を OpenAI 公式ドキュメントで確認できること | 「アスペクト比で見えた現実」節、ファクト対比節 | 検証でこの 3 サイズに収束したと記載、API docs を参照 | OpenAI の画像モデル docs で同サイズが列挙されている | |
| 7 | Codex が `gpt-image-1.5` を画像生成で利用する旨が公式発表で確認でき、現時点でも案内が生きていること | ファクト対比節、参照先一覧 | OpenAI 発表を引用 | https://openai.com/index/codex-for-almost-everything/ の記述が変更されていない、もしくは同等の後継記述がある | |
| 8 | `bubblewrap` が Codex sandbox の prerequisite として公式ドキュメントに記載されていること | QUICKSTART および README の環境節 | 公式 sandbox docs を参照 | https://developers.openai.com/codex/concepts/sandboxing#prerequisites に同記述あり | |
| 9 | 生成物の `~/.codex/generated_images` 保存先が現行 Codex でも fallback / 実保存先として使われていること | 同梱スクリプトの fallback recovery 節 | 検証で確認と記載、公式仕様かどうかは別途確認が必要 | docs に記載があるか、Codex 再実行で同パスが使われる | |
| 10 | 「日本語 prompt と英語 prompt のどちらも通った」という記述が、ポリシー・実装上どちらの意味でも問題ないこと | 「日本語 prompt と英語 prompt」節 | 多言語対応を検証結果として記載 | OpenAI 利用規約・言語サポート方針と矛盾しない | |
| 11 | `--skip-git-repo-check` が `codex exec` の現行フラグとして有効であること | `codex-image-batch.sh` 821, 841 行 | スクリプトで内部指定 | `codex exec --help` に当該フラグがある | |
| 12 | `--model` オプションへの任意モデル名文字列の引き渡しが現行 CLI で許容されること（サンプル JSON が `gpt-5.4` を指定している） | examples/*.sample.json の `codex_model`、README の JSON 節 | モデル名は override として渡すと記載 | Codex CLI docs に `--model` の説明があり、任意文字列が拒否されないことを確認 | |
| 13 | 記載内容・表現が公開リポジトリとして問題ないこと（秘匿情報、内部情報、OpenAI 関係者・利用者として不適切な表現が残っていない） | 全ファイル | 最終レビューとして Codex の視点も加えたい | PII・内部情報・著作権保護された素材・ポリシー違反となる表現がない | |
| 14 | Mermaid 図の記述が CLI 内部仕様の誤解を招かない抽象度に収まっていること | README の「環境と処理の全体像（図解）」節 | 実装フローを示したもので、CLI 内部仕様の図ではないと明示 | 図に描かれた矢印関係が事実と整合している | |
| 15 | 「私が試した 2 通り」の `--enable image_generation` と `config.toml` 以外に、Codex が想定する標準的な有効化方法がないかの補足 | README の feature 有効化節 | 2 通りのみ記載 | 公式推奨の方法が別にあれば追記、なければその旨を明記 | |

---

## 2. 追加で生成・掲載する価値がありそうな画像例（Codex への提案）

文章だけだと「そのコマンドで本当に画像が出るのか」が伝わりにくいので、
Codex 側で以下のコマンドを再実行し、出力 PNG を参考画像として
`examples/gallery/` に配置して公開する案です。掲載時は、ライセンス・
権利面の最終判断は TK2LAB 側で行います。

| 題材 | 想定コマンド（英語 prompt） | 想定ファイル名 | 優先度（Codex 判定） |
| --- | --- | --- | --- |
| 青い球 × 白背景（最小例） | `printf 'Use the built-in image generation capability only.\nGenerate a square 1:1 image of a blue sphere on a white background.\nNo text, no logo, no watermark.\n' \| codex exec --enable image_generation -` | `examples/gallery/blue-sphere-1024.png` | |
| ガラス瓶のプロダクトカット（square） | "A clean product photo of a glass bottle on a white background." を square で | `examples/gallery/glass-bottle-1024.png` | |
| 風景（landscape 検証用） | "A wide cinematic landscape illustration, soft afternoon light, no text, no logo, no watermark." を landscape で | `examples/gallery/landscape-1536x1024.png` | |
| 縦長のキービジュアル（portrait 検証用） | "A vertical poster-style studio product still life, editorial lighting, no text, no logo, no watermark." を portrait で | `examples/gallery/portrait-1024x1536.png` | |
| 編集例（1 枚入力、背景を白にする） | ベース画像を用意し `codex exec --enable image_generation -i ./input.png "Change the background to white..."` | `examples/gallery/edit-white-bg.png` | |
| 編集例（2 枚入力、palette transfer） | `codex exec --enable image_generation -i ./base.png -i ./reference.png "Transfer the palette from the second image..."` | `examples/gallery/edit-palette-transfer.png` | |

掲載時に Codex 側で事前確認してほしい点:

- **ポリシー**: 掲載画像にモデル利用ポリシー上の懸念が含まれないこと
  （商標、著名人、特定の既存キャラクター等が写り込んでいない）
- **プライバシー**: 画像ファイルの EXIF / メタデータに個人情報が
  残らないこと（掲載前に EXIF 除去）
- **再現性**: 使用した具体の prompt、出力ファイル名、生成日、
  Codex CLI バージョン、画像モデル alias（判明している場合）を
  `examples/gallery/README.md` に添えること
- **ライセンス**: 生成画像の扱いを明記する（OpenAI の利用規約に従う旨、
  このリポジトリが private である旨）

---

## 3. 追加の追認項目（低優先度だが次回見直したい点）

| # | 確認項目 | 該当箇所 | 現在の記述の趣旨 | 受入れ基準 | Codex レビューメモ |
| --- | --- | --- | --- | --- | --- |
| A | リポジトリ内の公式ドキュメント URL（6 件）が現時点でも到達可能・記述がほぼ同内容であること | README 両版末尾、QUICKSTART 両版 | 2026-04-18 時点で到達確認済 | 各 URL へ HTTP 200 が返り、リンク切れや大幅な内容変更がない | |
| B | `codex-image-batch.sh` の依存コマンド一覧（`jq` / `python3` / `realpath` / `find` / `sort` / `awk` / `grep` / `cp`）が Ubuntu LTS で標準または apt で入手可能であること | スクリプト 238 行目 | 最低限の依存で動くと記載 | Codex 側での再インストール時に不足がない | |
| C | 相対パス解決が spec ファイルの場所基準で行われる実装の記述が正確であること | README の JSON spec 節 | 相対パスは spec ファイル基準と記載 | スクリプト `resolve_path` / `spec_dir` の実装と一致 | |
| D | 引退・変更された CLI 仕様が残っていないこと（`codex-cli` のリリースノートと照合） | 全ファイル | 2026-04-18 時点の `codex-cli 0.121.0` に基づく | リリースノートで以後の破壊的変更が見つかれば記載 | |
| E | 図（Mermaid）の日本語ラベルが GitHub 上で正しく描画されていること | README.ja.md / README.en.md の「環境と処理の全体像」 | Mermaid を採用 | GitHub UI 上で 3 図ともレイアウト崩れなく表示 | |
| F | `.gitignore` が公開前に除外すべきパスをすべてカバーしていること | `.gitignore` | 出力・秘密情報・エディタ一時ファイルを除外 | 実行後に残りがちな `codex-image-batch-run-*.json` / `*.log.txt` / `.env*` / `.codex/` などが含まれる | |
| G | `codex-image-batch.sh` の bash 構文が現行 Ubuntu LTS の bash で妥当であること | `codex-image-batch.sh` | `bash -n` で構文チェック済 | `shellcheck` を走らせて critical 指摘なし | |
| H | サンプル JSON の `codex_model` 値 `gpt-5.4` が、記述時点で利用可能なモデル名であること | examples/*.sample.json | 2026-04-18 時点で観測 | 現行 CLI で同一または後継名が使用可能 | |
| I | 本メモ（MAINTAINER-NOTES.md）自体がリンク切れ・個人情報・内部固有名を含んでいないこと | `MAINTAINER-NOTES.md` | 公開リポジトリに含まれる旨を了承済み | GitHub 上で閲覧した際に PII や内部情報が残っていない | |

---

## 4. 想定される今後の変化（Watch List）

Codex CLI と OpenAI 周辺の記述は頻繁に変わるため、少なくとも以下の
項目は更新を受けやすい領域として記録しておきます。次回の見直しで真っ先に
確認する候補です。

- `codex-cli` の minor / patch バージョン上げに伴う `--enable` フラグ
  仕様の変化（名称変更・置き換え・廃止）
- `codex features list` 出力フォーマットの変更
- `codex features` サブコマンド群（`enable` / `disable` 等）の追加
- `~/.codex/config.toml` のセクション構造の変更
- 画像生成モデル世代の切り替え（`gpt-image-1.5` → 後継）
- OpenAI 公式画像サイズラインアップの変更
- sandbox 前提ライブラリ（`bubblewrap` 等）の推奨変更
- `codex exec` の非対話モード `-` の取扱い変更
- GPT 系テキストモデルの世代更新（GPT-5.4 → 後継）

---

## 5. リリース運用メモ

- **公開状態**: Private repo（TK2LAB と招待済みコラボレーターのみ）
- **URL**: https://github.com/TK2F/codex-cli-image-generation-wsl2-notes
- **ブランチ運用**: `main` 単一ライン。dev / PR ワークフローは未整備。
  軽い追従更新は `main` に直接コミットで良い想定。
- **タグ**: 未着手。大きな再検証（Codex の確認レスポンスを反映した
  大規模更新）のタイミングで `v0.1.0` のようなタグを切るかを検討。
- **コミット慣習**: 公開リポジトリのため、commit message に
  Co-Authored-By: などの他者クレジットは付けない運用。
- **push 前チェックリスト**:
  1. `git diff` で秘匿情報・PII が混入していないこと
  2. `bash -n codex-image-batch.sh` が通ること
  3. README の TOC アンカーが実セクションと一致していること
  4. Mermaid ブロックが GitHub で描画崩れしていないこと
  5. CHANGELOG の日付が更新されていること

---

## 6. 第三者レビュー結果の反映記録（2026-04-19）

Claude Code によるセルフレビューと、OpenAI 公式ドキュメント
（[Codex CLI reference](https://developers.openai.com/codex/cli/reference)、
[Features – Codex CLI](https://developers.openai.com/codex/cli/features)、
[Config basics](https://developers.openai.com/codex/config-basic)、
[Sandboxing](https://developers.openai.com/codex/concepts/sandboxing)、
[GPT Image 1.5 model page](https://developers.openai.com/api/docs/models/gpt-image-1.5/)、
[Image generation tool guide](https://developers.openai.com/api/docs/guides/tools-image-generation)、
[Codex for (almost) everything announcement](https://openai.com/index/codex-for-almost-everything/)）
の追認を 2026-04-19 に実施。以下を反映済み。

**確定できたこと（Finding 番号は REVIEW-REQUEST.md と同体系）**

- F-03: `codex exec` の `--enable` / `--skip-git-repo-check` / `-i` /
  stdin `-` 受付は公式 reference で明記された仕様と一致。
- F-06: `gpt-image-1.5` は 2026-04-16 announcement で現行画像モデル
  として記載。
- F-07: 画像サイズ `1024x1024` / `1024x1536` / `1536x1024` は公式
  model docs と完全一致。
- F-08: Linux/WSL2 での `bubblewrap` prerequisite 記述は公式 sandbox
  docs の exact wording と一致。
- F-09: `gpt-5.4` は image generation tool guide のモデル一覧に含まれる。
- F-18: PII / secrets の残留なし（複数回 Grep で確認）。

**公式 docs で裏取りして追記した点（本メモと README に反映済み）**

- F-01 / F-02: 公式 [Features – Codex CLI](https://developers.openai.com/codex/cli/features)
  および [Config basics](https://developers.openai.com/codex/config-basic)
  の feature 一覧に `image_generation` は含まれていない。README では
  「まずフラグ無しで試し、必要なときに 2 通りを試す」という順に
  トーンを変更。
- F-04: `-i` の 1 枚目 / 2 枚目の役割は CLI 仕様ではなく prompt 側で
  明示した結果である旨を明記。
- F-05: `codex features enable/disable/list` サブコマンドは公式に
  存在する。`image_generation` がその feature 名として通るかは未検証
  であり、追認候補として残す（セクション 1 の #1, #15 に反映）。
- F-10 / F-11 / F-12: タイムアウト無し、並行実行リスク、`raw log` の
  機密性について README の「凡ミス」節と英語版に注意追記。
- F-14: `--retry-count` の意味（最大試行回数 = 初回 1 + 再試行 N）を
  オプション早見表に明記。

**未解決 / 次回 Codex 追認で詰めたい点**

1. `image_generation` が Codex CLI 側で実際に有効な feature 名か。
   `--enable image_generation` が実質 no-op なのか、内部的に画像生成
   を開通させているのか。Codex 側の実機で `codex features list` の
   出力と、フラグ有無での挙動差分を取得したい。
2. `codex features enable image_generation` サブコマンドで実際に
   `config.toml` に書き込まれるかどうか。
3. 新規インストール直後に `--enable image_generation` を付けずに
   画像 prompt を送った場合に生成が走るか（built-in `image_gen` tool
   の既定有効性）。
4. `codex exec --help` の現時点の全フラグ一覧と、公式 reference 記載
   との整合。

## 7. ユーザー追試の反映記録（2026-04-19）

`review-evidence/20260419-054302/` に、実ユーザー環境での追試結果を保存。
この追試で、少なくとも `codex-cli 0.121.0` / `gpt-5.4` / WSL2 Ubuntu
の組み合わせでは次が確認できた。

- 画像生成・画像編集そのものは成功した。
- 4 テスト中 4 テストで PNG は生成された。
- 実ファイルは `~/.codex/generated_images/<session-id>/ig_*.png` に保存され、
  prompt や `-o` で指示した workdir 直下のパスには現れなかった。
- LLM が返す `Output path: ...` は、実在しないパスを示すケースがあった。
- `--enable image_generation` は、`image_generation = true` 済み環境では
  実質 no-op だった。
- `--full-auto -c sandbox_workspace_write.network_access=true` を付けても
  保存挙動は変わらず、network access は必須ではなかった。

この結果を踏まえ、README / QUICKSTART / CHANGELOG / スクリプト説明の
更新が必要になった。

## 8. このメモ自体の更新ログ

- **2026-04-19（初版）**: TK2LAB と Codex で 2026-04-18 に実施した
  検証を反映し、公開リポジトリの MAINTAINER-NOTES として配置。
- **2026-04-19（第 1 リビジョン）**: Claude Code によるセルフレビューと
  公式 docs 追認結果を反映。`image_generation` の feature 名
  位置づけに関する注記、`-i` の順序意味論、タイムアウト / 並行実行 /
  ログ機密性に関する注意を本体 README に追記。本メモにセクション 6
  として結果を記録。
- **今後の更新**: Codex 側のレビュー応答を反映したタイミングで、
  各表の「Codex レビューメモ」列を埋めつつ、状態確定項目に
  「確認済み」タグを付け、未確定項目は次回宿題に繰り越す。
