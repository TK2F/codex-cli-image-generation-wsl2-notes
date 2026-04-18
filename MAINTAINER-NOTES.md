# MAINTAINER-NOTES.md — Codex 再確認用の内部メモ

> このファイルは公開リポジトリに含まれていますが、読者向けのドキュメントとは
> 別の、**リポジトリのメンテナンス用** のメモです。TK2LAB と Codex が
> 2026-04-18 時点の検証結果をまとめたあと、Codex 側で改めて裏取りして
> ほしい項目、ドキュメントの事実性・表現を確認してほしい項目、追加で
> 生成して掲載する価値がありそうな画像例を整理しています。

---

## 1. Codex に追認してほしいチェックリスト

下記の項目は、Codex と私（TK2LAB）で検証しながら書き下ろしたものですが、
内容の最新性・表現の正確さを高めるため、**Codex 側でもう一度読み直して
確認してほしい** 一覧です。該当箇所の引用とともに、Codex 視点で「事実と
ずれている」「表現が誤解を招く」「最新バージョンでは違う」といったコメント
があれば、この表の右端に追記していってください。

| # | 確認して欲しい点 | 該当ドキュメント | 現在の記述の趣旨 | Codex レビューメモ |
| --- | --- | --- | --- | --- |
| 1 | `codex features list` の出力上で `image_generation` が既定で `false` として表示される点は、最新版の Codex CLI でも同じか | README.ja.md / README.en.md の「`image_generation` は既定で無効だったので…」 | 2026-04-18 時点の検証結果として `false` だったと記載 | |
| 2 | `codex exec --enable image_generation` が確実に有効なサブコマンド / フラグの組み合わせであること | README.ja.md / README.en.md の同節、および最小コマンド例 | 当該フラグで一時的に有効化したと記載 | |
| 3 | `~/.codex/config.toml` の `[features]` セクションに `image_generation = true` を書くことで、恒久的に有効化できる挙動が現行 CLI にあること | 上記同節 | 私で動作を確認した方法として明示 | |
| 4 | `codex exec` に対する `-i` フラグで画像添付ができる挙動、2 枚以上の `-i` を重ねて指定したときの解釈（1 枚目 base、2 枚目 reference）が現行仕様か | 最小コマンド節、`printf` 節 | `-i` を 2 つ重ねた場合の挙動として 1 枚目 base / 2 枚目 reference と記載 | |
| 5 | `codex exec -` での stdin 経由 prompt 受け渡しが現行 CLI でも正式にサポートされている挙動か | `printf` を使った理由と読み方 | POSIX `printf` と組み合わせて最小コマンドを構成できるとして記載 | |
| 6 | 画像サイズについて、現行モデルが `1024x1024` / `1024x1536` / `1536x1024` を中心的にサポートする旨を OpenAI 公式ドキュメントで確認できること | アスペクト比節、ファクト対比節 | 検証でこの 3 サイズに収束したと記載、API docs を参照 | |
| 7 | Codex が `gpt-image-1.5` を画像生成で利用する旨を公式発表で確認できること、現時点でも同じ案内が生きていること | ファクト対比節、参照先 | OpenAI 発表を引用している | |
| 8 | `bubblewrap` が Codex sandbox の prerequisite として公式ドキュメントに記載されていること | QUICKSTART と README の環境節 | 公式 sandbox docs を参照 | |
| 9 | 生成物の `~/.codex/generated_images` 保存先が、現行の Codex でも fallback / 実保存先として使われていること | 同梱スクリプトの fallback recovery 節 | 私の検証結果で確認、公式仕様かどうかは別途確認が必要 | |
| 10 | 本文中の「日本語 prompt と英語 prompt がどちらも通った」の記述が、ポリシー上・実装上どちらの意味でも問題ない言い回しであること | 日本語 prompt と英語 prompt 節 | 多言語対応を検証結果として記載 | |
| 11 | `--skip-git-repo-check` は現行 `codex exec` のサブフラグとして有効か | codex-image-batch.sh 内で使用 | スクリプトで内部指定している | |
| 12 | 記載内容・表現が公開リポジトリとして問題ない（秘匿情報、内部情報、OpenAI 関係者として不適切な表現が残っていない） | 全ファイル | 最終レビューとして Codex の視点も加えたい | |
| 13 | 図解（Mermaid）の記述が、CLI の内部仕様の誤解を招かない抽象度に収まっていること | README の「環境と処理の全体像」節 | 実装フローを示したもので、CLI 内部仕様の図ではないと明示 | |

## 2. 追加で生成・掲載する価値がありそうな画像例（Codex への提案）

文章だけだと「本当にそのコマンドで画像が出るのか」が伝わりにくいので、
Codex 側で以下のコマンドを再実行し、**出力 PNG を参考画像として同梱して
公開に加える** か、リポジトリに `examples/gallery/` のようなディレクトリを
切って添付することをご提案します。掲載時は、ライセンス・権利面の最終
判断は TK2LAB 側で行います。

| 題材 | 想定コマンド（英語 prompt） | 想定ファイル名 |
| --- | --- | --- |
| 青い球 × 白背景（最小例） | `printf 'Use the built-in image generation capability only.\nGenerate a square 1:1 image of a blue sphere on a white background.\nNo text, no logo, no watermark.\n' \| codex exec --enable image_generation -` | `examples/gallery/blue-sphere-1024.png` |
| ガラス瓶のプロダクトカット（正方形） | 汎用 prompt: "A clean product photo of a glass bottle on a white background." を square で | `examples/gallery/glass-bottle-1024.png` |
| 風景（横長、landscape 検証用） | 汎用 prompt: "A wide cinematic landscape illustration, soft afternoon light, no text, no logo, no watermark." を landscape で | `examples/gallery/landscape-1536x1024.png` |
| 縦長のキービジュアル（portrait 検証用） | 汎用 prompt: "A vertical poster-style studio product still life, editorial lighting, no text, no logo, no watermark." を portrait で | `examples/gallery/portrait-1024x1536.png` |
| 編集例（1 枚入力、背景を白にする） | ベース画像を 1 枚用意し、`codex exec --enable image_generation -i ./input.png "Change the background to white..."` を実行 | `examples/gallery/edit-white-bg.png` |
| 編集例（2 枚入力、palette transfer） | `codex exec --enable image_generation -i ./base.png -i ./reference.png "Transfer the palette from the second image..."` を実行 | `examples/gallery/edit-palette-transfer.png` |

掲載時の条件（Codex 側に事前確認していただきたい点）:

- 掲載する画像にモデルポリシー上の懸念事項が含まれないこと（特に商標、
  著名人、キャラクターの写り込みがないこと）。
- 画像ファイルに EXIF などで個人情報が紛れていないこと（掲載前に EXIF 削除）。
- 画像生成に使用した具体の prompt と、出力ファイル名、生成日、使用した CLI
  バージョンをキャプションとして添えること。

## 3. ドキュメントの最新性に関するメモ

- この文書は 2026-04-18 時点のスナップショット。Codex CLI のアップデート
  に応じて以下が変わる可能性があることを本文でも注意喚起済み。
  - `image_generation` の初期値
  - 有効化フラグ名 / TOML キー名
  - 画像モデル alias (`gpt-image-1.5` からの世代更新)
  - 公開画像サイズの選択肢
- 次回の検証では、上記チェックリストの 1〜11 を `codex --version` の
  差分と合わせて再確認する。バージョン差分が大きい場合、README の
  「検証環境のバージョンと確認コマンド」表と `## 検証日` のヘッダを更新。
- ドキュメント内部から本ファイルへ直接リンクは張らない。読者向けの
  主導線を汚さないための配慮。

## 4. リリース運用

- 公開状態: Private repo（https://github.com/TK2F/codex-cli-image-generation-wsl2-notes）
- `main` ブランチが単一の公開ラインで、PR ワークフローや dev ブランチは
  現時点では用意していない。軽い追従更新は main に直接コミット。
- タグの運用は未着手。次の大きな再検証のタイミングで `v0.1.0` のような
  タグを切るかを検討する。
