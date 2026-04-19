# Codex CLI で画像生成を試した個人メモ（WSL2 Ubuntu / 2026-04-18 時点）

この `share/` フォルダは、外部共有しやすいように切り出した配布用サブセット
です。raw log、手元専用の証跡、メンテナンス用メモは含めていません。

## 3行でわかるこのrepo

- Codex CLI でも画像生成と画像編集が通るのかを、WSL2 Ubuntu + Bash 上で実地に検証した記録です。
- 生成自体は通りましたが、PNG の保存先は期待どおりではなく、`~/.codex/generated_images/<session-id>/` からの回収が必要でした。
- `share/` には、その検証結果・再現用コマンド・補助スクリプト・公開用に絞った画像例だけを残しています。

私（TK2LAB）が Codex と一緒に「Windows 11 の WSL2 Ubuntu + Bash 上で
`codex` を叩いて、画像生成と画像編集が本当にそのまま通るのか」を確かめて
いたところ、実際に出力できたので、自分のための覚書として残したものを、
同じ疑問を持つ皆さん向けに共有するリポジトリです。

## このリポジトリの位置づけ

この `share/` フォルダは、公開向けに切り出した配布用サブセットです。

この内容は、Codex CLI の画像生成・画像編集まわりについて、Windows 11 + WSL2 Ubuntu + Bash 環境で実際に試した内容をまとめた個人メモです。公式手順書ではなく、本環境で動作を確認した結果を、公開しやすい形に整理したものです。

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

本環境では、生成されたPNGが作業ディレクトリではなく、`~/.codex/generated_images/<session-id>/` 配下に保存されることを確認しました。回収手順は [docs/RETEST-2026-04-19.md](docs/RETEST-2026-04-19.md) にまとめています。

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

この `share/` フォルダは、外部共有しやすいように切り出した公開向けサブセットです。次の情報は含めない方針にしています。

- APIキー、アクセストークン、認証情報
- メールアドレス、住所、電話番号などの個人情報
- 非公開プロジェクト名、社内ドメイン、顧客名などの内部情報
- raw log、完全な実行ログ、ローカル環境固有の詳細ログ
- 未公開素材、権利関係が不明な参照画像
- 実在人物やクライアント素材を含む入力画像
- ローカルユーザー名やホームディレクトリ名が含まれるファイルパス

公開している画像・サンプル・ログは、外部共有できる範囲に絞ったものです。完全な raw evidence bundle は公開対象に含めていません。

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

## 最短で把握したい方向け

1. まず [QUICKSTART.ja.md](QUICKSTART.ja.md) /
   [QUICKSTART.en.md](QUICKSTART.en.md) を見て、最小コマンドと保存先の実態を
   把握してください。
2. 次に [docs/RETEST-2026-04-19.md](docs/RETEST-2026-04-19.md) を見て、
   後追い検証で何が覆り、何が維持されたかを確認してください。
3. 実際の出力の雰囲気は
   [examples/gallery/README.md](examples/gallery/README.md) を見てください。
4. まとまった実行や複数参照画像を試すなら `codex-image-batch.sh` と
   `examples/*.json` を参照してください。

## 公開前の最小チェック

- `share/docs/RETEST-2026-04-19.md` の内容が、現時点で共有したい結論と一致しているか
- `share/examples/gallery/*.png` が metadata strip 済みで、公開したくない情報を含まないか
- `share/README.md` と `share/QUICKSTART.*` の導線が、今の公開意図と一致しているか
- まだ実機で生成していない画像や未確認の挙動を、確認済みの事実として書いていないか

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

---

# Codex CLI Image Generation — Personal Notes (WSL2 Ubuntu, as of 2026-04-18)

This `share/` folder is the portable subset intended for external handoff. It
excludes raw logs, local-only evidence bundles, and maintainer-only notes.

I (TK2LAB) was checking with Codex whether `codex` could actually be
driven for image generation and editing from a WSL2 Ubuntu Bash shell on
Windows 11. Output did come through, so I wrote up the memo I was
keeping for myself and am sharing it here for anyone wondering the same
thing.

## Scope of this repository

This `share/` folder is the portable subset intended for external handoff.

This content is a personal technical note about testing Codex CLI image
generation and image editing from a Windows 11 + WSL2 Ubuntu + Bash
environment. It is not an official guide; it records what worked in this
specific setup.

Where possible, the notes distinguish between:

- Officially documented: behavior or options confirmed in official documentation
- Confirmed in this environment: behavior that was tested and worked in this specific setup
- Inferred: behavior inferred from test results and subject to change in future versions

## 30-second summary: what worked in this environment

> This is the shortest summary of what worked in this specific Windows 11 + WSL2 Ubuntu + Bash test environment.

**Environment**

- Windows 11 + WSL2 (Ubuntu 24.04 LTS)
- Bash shell driving Codex CLI
- `codex-cli 0.121.0`
- Test dates: 2026-04-18 / 2026-04-19

Note: In this environment, `image_generation` appeared not to be enabled by default.
This behavior may change depending on the Codex CLI version or future updates.

**Command that worked in this environment**

```bash
codex exec --enable image_generation "Portrait of a cat"
```

In this environment, the command above successfully produced an image. Portrait (9:16), landscape (16:9), and square (1:1) outputs also worked in the same test environment.

**Enabling the feature persistently**

In this environment, adding the following to `~/.codex/config.toml` allowed image generation to run without passing `--enable image_generation` every time.

```toml
[features]
image_generation = true
```

This is a behavior confirmed in this test environment. Required settings or behavior may change in future Codex CLI versions.

**Where the PNGs landed**

In this environment, the generated PNGs were stored under `~/.codex/generated_images/<session-id>/` rather than the working directory expected by the prompt or helper script. Recovery steps are in [docs/RETEST-2026-04-19.md](docs/RETEST-2026-04-19.md).

Full commands and test notes live in [QUICKSTART.en.md](QUICKSTART.en.md) / [README.en.md](README.en.md).

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

## Public-safety note

This `share/` folder is intended to contain only public-facing notes and sanitized examples.

The following should not be committed:

- API keys, access tokens, or credentials
- Email addresses, phone numbers, addresses, or other personal information
- Private project names, customer names, internal domains, or non-public URLs
- Raw logs or full execution traces
- Local machine-specific paths that reveal usernames or private directories
- Unpublished assets or reference images with unclear rights
- Real-person or client-provided input images

The committed examples are intended to be a public subset only. Full raw evidence bundles should remain local/private.

> This is a personal record of what one person plus Codex confirmed on
> 2026-04-18. It is not a recommendation of the exact commands or the
> exact steps used here. Codex CLI evolves quickly, and future releases,
> behavior changes, new findings, or official announcements may render
> parts of this report outdated or incorrect. **Treat it as a single
> reference point in time.** Better commands, flag choices, and helper-script
> designs almost certainly exist — exploring variations on your side is
> the intended spirit of this share.

**Test date:** 2026-04-18
**Environment:** Windows 11 + WSL2 + Ubuntu + Bash + `codex-cli 0.121.0`
**Observers:** TK2LAB and Codex (on the CLI side)

## Fast path

1. Start with [QUICKSTART.en.md](QUICKSTART.en.md) /
   [QUICKSTART.ja.md](QUICKSTART.ja.md) for the minimum commands and the real
   storage behavior.
2. Then read [docs/RETEST-2026-04-19.md](docs/RETEST-2026-04-19.md) to see
   what the follow-up re-test confirmed or corrected.
3. For concrete outputs, open
   [examples/gallery/README.md](examples/gallery/README.md).
4. If you want batch runs or multi-reference inputs, then move on to
   `codex-image-batch.sh` and the sample JSON files.

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

## How to read this memo

This `share/` folder keeps only the externally shareable subset of what was tested in this environment for Codex CLI image generation and editing.

Its value is not only the successful commands, but also the operational details that are easy to miss: feature enablement, config behavior, PNG storage location, file recovery, and public-safe cleanup.

This is not a statement of official product behavior. If you try the same flow elsewhere, verify the Codex CLI version, official documentation, auth state, and actual output location on your own machine.

## Current example outputs

These are real outputs already included in this shared subset:

| Example | Preview |
| --- | --- |
| Blue sphere generation | ![Blue sphere example](examples/gallery/blue-sphere-with-enable.png) |
| Black-and-white edit | ![Black and white edit example](examples/gallery/edit-black-and-white.png) |

For prompts and notes, open
[examples/gallery/README.md](examples/gallery/README.md).
