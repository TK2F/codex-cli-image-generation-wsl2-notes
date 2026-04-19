# Codex CLI で画像生成を試した個人メモ（WSL2 Ubuntu / 2026-04-18 時点）

私（TK2LAB）が Codex と一緒に「Windows 11 の WSL2 Ubuntu + Bash 上で
`codex` を叩いて、画像生成と画像編集が本当にそのまま通るのか」を確かめて
いたところ、実際に出力できたので、自分のための覚書として残したものを、
同じ疑問を持つ皆さん向けに共有するリポジトリです。

## このリポジトリの位置づけ

このリポジトリは、Codex CLI の画像生成・画像編集まわりについて、Windows 11 + WSL2 Ubuntu + Bash 環境で実際に試した内容をまとめた個人メモです。

公式ドキュメントの内容を整理した手順書ではなく、本環境で動作を確認した結果を、後から見返せるように公開向けに整えたものです。

そのため、ここに書かれている内容は再現保証ではありません。Codex CLI のバージョン、実行環境、設定、将来の仕様変更によって、同じコマンドでも挙動が変わる可能性があります。

本リポジトリでは、できるだけ次のように情報を分けて記載します。

- 公式確認済み: 公式ドキュメントで確認できる仕様・説明
- 本環境で動作確認済み: 本検証環境で実際に試し、動作を確認した内容
- 推定: 検証結果から推測した内容。将来のバージョンでは変わる可能性があります

## 30秒でわかる、本環境で通った方法

> 「Windows 11 + WSL2 上の Codex CLI で、画像生成は実際に通ったのか？」に対する、本検証環境での最短メモです。

**環境**

- Windows 11 + WSL2 (Ubuntu 24.04 LTS)
- bash から Codex CLI を起動
- `codex-cli 0.121.0`
- 検証日: 2026-04-18 / 2026-04-19

※ 本環境では、`image_generation` は初期状態では有効化されていないように見えました。
※ この挙動は、Codex CLI のバージョンや将来の更新により変わる可能性があります。

**本環境で画像生成が通ったコマンド**

```bash
codex exec --enable image_generation "猫の肖像画を描いて"
```

本環境では、上記のコマンドで画像生成が動作することを確認しました。
また、本検証では、縦長 (9:16) / 横長 (16:9) / 正方形 (1:1) の指定でも生成が通ることを確認しました。

**毎回フラグを付けない場合**

本環境では、`~/.codex/config.toml` に以下を追記したところ、毎回 `--enable image_generation` を付けなくても画像生成が通ることを確認しました。

```toml
[features]
image_generation = true
```

これは本検証環境で確認した挙動です。Codex CLI の今後の更新により、必要な設定や挙動が変わる可能性があります。

**保存先に注意**

本環境では、生成されたPNGが作業ディレクトリではなく、`~/.codex/generated_images/<session-id>/` 配下に保存されることを確認しました。

そのため、このリポジトリの補助スクリプトでは、Codex CLI 実行後に該当セッションディレクトリから生成画像を回収する処理を入れています。詳しい回収手順は [docs/RETEST-2026-04-19.md](docs/RETEST-2026-04-19.md) にまとめています。

詳しいコマンド全量と再現手順は [QUICKSTART.ja.md](QUICKSTART.ja.md) / [README.ja.md](README.ja.md) にあります。

## 必要なツールと導入コマンド

上記のコマンドを走らせる前に、WSL2 Ubuntu 側で以下を入れておきます。

```bash
# Codex CLI 本体（Node.js が必要。本検証では Node v24 を使用）
npm install -g @openai/codex
codex --version   # 動作確認

# 同梱ヘルパースクリプトや JSON 操作で使う追加パッケージ
sudo apt update
sudo apt install -y jq python3 bubblewrap coreutils findutils gawk grep
```

実測したバージョンの一覧は [README.ja.md](README.ja.md) の環境表を参照してください。

## ライセンス

MIT License. 詳細は [LICENSE](LICENSE) を参照してください。

## 公開時の安全性について

このリポジトリでは、公開にあたり、次の情報を含めない方針にしています。

- APIキー、アクセストークン、認証情報
- メールアドレス、住所、電話番号などの個人情報
- 非公開プロジェクト名、社内ドメイン、顧客名などの内部情報
- raw log、完全な実行ログ、ローカル環境固有の詳細ログ
- 未公開素材、権利関係が不明な参照画像
- 実在人物やクライアント素材を含む入力画像
- ローカルユーザー名やホームディレクトリ名が含まれるファイルパス

公開している画像・サンプル・ログは、外部共有できる範囲に絞ったものです。完全な raw evidence bundle は公開対象に含めていません。

## 公開前チェックリスト

- [ ] APIキー、トークン、認証情報が含まれていない
- [ ] raw log、完全な実行ログ、ローカル専用の証跡を含めていない
- [ ] ローカルユーザー名、ホームディレクトリ名、社内パスが含まれていない
- [ ] メールアドレス、住所、電話番号などの個人情報が含まれていない
- [ ] 非公開プロジェクト名、顧客名、社内ドメインが含まれていない
- [ ] 入力画像に、実在人物、クライアント素材、未公開素材、権利不明の画像が含まれていない
- [ ] 公開サンプル画像のメタデータに、不要な内部情報が残っていない
- [ ] README上で、公式仕様と本環境での検証結果を混同していない
- [ ] `--output-dir` など、公式オプションと誤解される表現を避けている
- [ ] Codex CLI のバージョンと検証日を明記している

**ここでいう「皆さん」とは、次のような方を想定しています。**

- Codex CLI や WSL2 をこれから触ろうとしていて、画像生成が実際に動く
  のかを手元で確かめたい方
- AI × CLI でのワークフローに興味があり、他の人の検証記録を参考にしたい方

> これは 2026-04-18 時点での、私一人 + Codex 分の検証結果をまとめた
> 個人的な覚書です。同じコマンドや同じ手順を皆さんに推奨しているわけでは
> ありません。Codex CLI はアップデートが早く、今後のリリース、仕様変更、
> 新しい発見、公式の発表などで、ここに書いている内容が変わったり、
> 誤解や不備が見つかる可能性は十分にあります。**この時点の 1 つの
> 参考情報** としてご覧ください。もっと良いコマンドの書き方、フラグの
> 指定方法、ツールの構成の仕方はきっとあるはずなので、皆さんご自身の
> 環境でいろいろ試していただけるのが、この共有の本来の意図です。

**検証日:** 2026-04-18
**環境:** Windows 11 + WSL2 + Ubuntu + Bash + `codex-cli 0.121.0`
**検証者:** TK2LAB, Codex（CLI 側）

## レポジトリの全体像と読み進め方

| 目的 | 開く |
| --- | --- |
| このレポジトリの検証結果、テストしたコマンド群をチェックしたい（再現確認） | [QUICKSTART.ja.md](QUICKSTART.ja.md) / [QUICKSTART.en.md](QUICKSTART.en.md) |
| 環境バージョン、検証した結果、アスペクト比、JSON spec、このリポジトリが何を検証して何が分かったのかを確認したい | [README.ja.md](README.ja.md) / [README.en.md](README.en.md) |
| 変更履歴 | [CHANGELOG.md](CHANGELOG.md) |

## 同梱ファイル

- `codex-image-batch.sh` — 複数枚の生成・編集ジョブを JSON で流せると
  便利だったので書いた個人的な Bash 補助スクリプトです。本環境では、
  このスクリプトを使って複数ジョブの実行と生成画像の回収を確認しました。
  ただし、これは公式ツールではなく、あくまで参考実装です。Codex CLI の
  今後の仕様変更、保存先の変更、並列実行、別セッションとの競合などに
  よって、期待どおりに画像を回収できない可能性があります。
- `examples/codex-image-batch.sample.json` — 生成ジョブのサンプル × 6
- `examples/codex-image-edit-batch.sample.json` — 編集ジョブのサンプル × 3
- `examples/input/README.md` — 編集入力用フォルダのプレースホルダ
- `examples/gallery/README.md` — 公開できる範囲に絞った再テスト画像と prompt
  メモ
- `docs/RETEST-2026-04-19.md` — 2026-04-19 の追試結果を、公開向けに
  要約した記録

注意:

- 並列実行時は、別セッションの生成画像を誤って回収しないよう注意してください。
- 可能な限り、セッションIDに紐づくディレクトリから回収してください。
- raw log や一時ファイルには、ローカルパス、プロンプト、環境情報が含まれる可能性があります。公開リポジトリには含めないでください。

---

# Codex CLI Image Generation — Personal Notes (WSL2 Ubuntu, as of 2026-04-18)

I (TK2LAB) was checking with Codex whether `codex` could actually be
driven for image generation and editing from a WSL2 Ubuntu Bash shell on
Windows 11. Output did come through, so I wrote up the memo I was
keeping for myself and am sharing it here for anyone wondering the same
thing.

## 30-second walkthrough

> The shortest answer to "How did you actually run image generation with Codex on Windows 11 + WSL2?"

**Environment**

- Windows 11 + WSL2 (Ubuntu 24.04 LTS)
- Bash shell driving Codex CLI
- `codex-cli 0.121.0`
- Note: `image_generation` appeared to be `false` by default

**Smallest command that worked**

```bash
codex exec --enable image_generation "Portrait of a cat"
```

Image generation went through. Portrait (9:16), landscape (16:9), and square (1:1) all worked.

**To enable it persistently without the flag**

Add this to `~/.codex/config.toml`:

```toml
[features]
image_generation = true
```

After this, `--enable image_generation` is no longer needed.

**Where the PNGs land**

In this environment, the generated PNGs were stored under `~/.codex/generated_images/<session-id>/` rather than the working directory expected by the prompt or helper script. Recovery steps are in [docs/RETEST-2026-04-19.md](docs/RETEST-2026-04-19.md).

Full commands and observations live in [QUICKSTART.en.md](QUICKSTART.en.md) / [README.en.md](README.en.md).

## Prerequisites and setup commands

Before running the command above, install the following on WSL2 Ubuntu:

```bash
# Codex CLI itself (requires Node.js; this run used Node v24)
npm install -g @openai/codex
codex --version   # sanity check

# Extra packages used by the bundled helper script and JSON workflows
sudo apt update
sudo apt install -y jq python3 bubblewrap coreutils findutils gawk grep
```

For the exact versions I measured on my machine, see the environment table in [README.en.md](README.en.md).

## License

MIT License. See [LICENSE](LICENSE).

> This is a personal record of what one person plus Codex observed on
> 2026-04-18. It is not a recommendation of the exact commands or the
> exact steps used here. Codex CLI evolves quickly, and future releases,
> behavior changes, new findings, or official announcements may render
> parts of this report outdated or incorrect. **Treat it as a single
> reference point in time.** Better commands, flag choices, and helper-script
> designs almost certainly exist — exploring variations on your side is
> the intended spirit of this share.

**Date of observation:** 2026-04-18
**Environment:** Windows 11 + WSL2 + Ubuntu + Bash + `codex-cli 0.121.0`
**Observers:** TK2LAB and Codex (on the CLI side)

**2026-04-19 re-test note:** A later follow-up run in the same repo
confirmed that image generation and editing still worked, but the PNGs
were stored under `~/.codex/generated_images/<session-id>/` rather than
the working-directory location expected by the prompt or helper flow.
See the full language-specific READMEs and QUICKSTART files for the
updated recovery steps.

## Start here

| If you want to... | Open |
| --- | --- |
| Check the repository's tested commands and confirmed results | [QUICKSTART.en.md](QUICKSTART.en.md) / [QUICKSTART.ja.md](QUICKSTART.ja.md) |
| Read the full write-up — versions, test notes, aspect ratios, JSON spec, and what this repository set out to verify and found | [README.en.md](README.en.md) / [README.ja.md](README.ja.md) |
| Review release history | [CHANGELOG.md](CHANGELOG.md) |

## What ships with this package

- `codex-image-batch.sh` — a small Bash helper I put together because
  running several image jobs from a JSON spec was convenient for my own
  workflow. It is a reference implementation shared as-is, not a
  recommended tool. Cleaner designs almost certainly exist.
- `examples/codex-image-batch.sample.json` — six sample generation jobs
- `examples/codex-image-edit-batch.sample.json` — three sample edit jobs
- `examples/input/README.md` — placeholder for edit-input images
- `examples/gallery/README.md` — selected public-facing re-test images
  with prompt notes
- `docs/RETEST-2026-04-19.md` — sanitized public summary of the
  2026-04-19 re-test

## このメモの読み方

このリポジトリは、Codex CLI の画像生成・画像編集機能について、本環境で実際に試した結果を共有するためのものです。

特に価値があるのは、成功したコマンドそのものだけでなく、次のような「つまずきやすい点」を残していることです。

- `image_generation` の有効化が必要に見えたこと
- 設定ファイルで有効化した場合の挙動
- 画像の保存先が作業ディレクトリではなく Codex 側の `generated_images` 配下だったこと
- 生成画像の回収処理が必要だったこと
- raw log や非公開素材を公開しないように整理したこと

一方で、この内容は公式仕様の説明ではなく、本環境での検証記録です。
そのため、他の環境で同じ手順を試す場合は、Codex CLI のバージョン、公式ドキュメント、実際の保存先、認証状態を確認しながら進めてください。

## Public example images from the re-test

These are currently committed, re-tested example outputs with prompt notes:

| Example | Preview |
| --- | --- |
| Blue sphere generation | ![Blue sphere example](examples/gallery/blue-sphere-with-enable.png) |
| Black-and-white edit | ![Black and white edit example](examples/gallery/edit-black-and-white.png) |

For the full prompt list and notes, see
[examples/gallery/README.md](examples/gallery/README.md).
