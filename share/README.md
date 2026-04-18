# Codex CLI で画像生成を試した個人メモ（WSL2 Ubuntu / 2026-04-18 時点）

この `share/` フォルダは、外部共有しやすいように切り出した配布用サブセット
です。raw log、手元専用の証跡、メンテナンス用メモは含めていません。

私（TK2LAB）が Codex と一緒に「Windows 11 の WSL2 Ubuntu + Bash 上で
`codex` を叩いて、画像生成と画像編集が本当にそのまま通るのか」を確かめて
いたところ、実際に出力できたので、自分のための覚書として残したものを、
同じ疑問を持つ皆さん向けに共有するリポジトリです。

**ここでいう「皆さん」とは、次のような方を想定しています。**

- Codex CLI や WSL2 をこれから触ろうとしていて、画像生成が実際に動く
  のかを手元で確かめたい方
- 公式のドキュメントで概要は掴んだけれど、「自分の環境で通るコマンドの
  最小形」を具体例で見たい方
- 複数の画像生成を JSON や Bash でまとめて回すときの入口を探している方
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

## どこから読むか

| 目的 | 開く |
| --- | --- |
| このレポジトリの検証結果、テストしたコマンド群をチェックしたい（再現確認） | [QUICKSTART.ja.md](QUICKSTART.ja.md) / [QUICKSTART.en.md](QUICKSTART.en.md) |
| 環境バージョン、検証した結果、アスペクト比、JSON spec、よく見る説明や思い込みを今回の結果と照らして確認したい | [README.ja.md](README.ja.md) / [README.en.md](README.en.md) |
| 変更履歴 | [CHANGELOG.md](CHANGELOG.md) |

## 同梱ファイル

- `codex-image-batch.sh` — 複数枚の生成・編集ジョブを JSON で流せると
  便利だったので書いた個人的な Bash 補助スクリプト。お勧めではなく、
  あくまで参考実装です。より良い書き方・設計はきっとあります。
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
the user-requested workdir path. See the full language-specific READMEs
and QUICKSTART files for the updated recovery steps.

## Start here

| If you want to... | Open |
| --- | --- |
| Check the repository's observed results and tested commands | [QUICKSTART.en.md](QUICKSTART.en.md) / [QUICKSTART.ja.md](QUICKSTART.ja.md) |
| Read the full write-up — versions, observations, aspect ratios, JSON spec, and a check of common claims against the results in this repo | [README.en.md](README.en.md) / [README.ja.md](README.ja.md) |
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

## Current observed examples

These are real outputs already included in this shared subset:

| Example | Preview |
| --- | --- |
| Blue sphere generation | ![Blue sphere example](examples/gallery/blue-sphere-with-enable.png) |
| Black-and-white edit | ![Black and white edit example](examples/gallery/edit-black-and-white.png) |

For prompts and notes, open
[examples/gallery/README.md](examples/gallery/README.md).

Planned top-page landscape hero images are specified in
[docs/FEATURED-HERO-IMAGES.md](docs/FEATURED-HERO-IMAGES.md), but they are not
committed yet because this snapshot does not include a fresh re-test for them.
