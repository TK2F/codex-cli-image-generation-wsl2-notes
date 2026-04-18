# 外部共有向けガイド

このガイドは、何を検証し、何を目的にし、受け取った側が何を期待してよいかを外部共有向けに整理した要約です。

検証者:

- TK2LAB
- Codex

検証日:

- 2026-04-19
- `codex-cli 0.121.0`

## 目的

このパッケージは、Codex の画像生成・画像編集バッチ処理を、元の作成者のマシン構成を知らなくても WSL2 Ubuntu 上で使いやすくするためのものです。

## 残したもの

- ランナー本体
- 動く sample JSON
- 初心者向けのセットアップ手順と使い方
- 実運用で役立つ検証から得られた知見

## 検証したこと

- ランナーが構文エラーなく help を表示できる
- preview mode が使える
- doctor mode が使える
- `codex` を `PATH`、nvm fallback、`CODEX_BIN` のいずれかで検出できる
- Linux パス、Windows drive path、WSL の UNC path を受け付けられる
- 出力済みファイルが存在しても preview が動く
- summary と log の参照が可能な限り相対パスになる

## 実運用でのおすすめ順序

1. まず `--doctor`
2. 次に `--preview`
3. sample batch を実行
4. sample JSON を自分用に書き換える
5. 1 回限りなら manual mode を使う

## 安全寄りのデフォルト

- `--no-prompt` を付けない限り本実行前に確認が入る
- 既存出力は `--overwrite` を付けない限り skip する
- 失敗ジョブは retry できる
- `--stop-on-job-error` を付けない限り 1 件失敗しても全体は継続する

## 制約

- このパッケージは実際に検証した WSL2 Ubuntu の shell workflow 向けであり、Windows PowerShell ネイティブ実行は対象外
- Codex や OS 依存パッケージの自動インストールまでは行わない
- 実際の画像品質や生成結果は、その時点の Codex CLI とモデルの挙動に依存する
- `~/.codex/generated_images` からの fallback 回収は best effort であり、常に確実な代替ではない

## 拡張が必要になるケース

次の用途では、さらに手を入れる価値があります。

- チーム専用の JSON template を持ちたい
- ファイル命名ルールをもっと厳しくしたい
- style preset を増やしたい
- CI や自動化用の wrapper を追加したい
- zip 配布に checksum や署名を付けたい
