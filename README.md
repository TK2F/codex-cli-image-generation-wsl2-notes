# Codex CLI で画像生成を試した個人メモ（WSL2 Ubuntu / 2026-04-18 時点）

私（TK2LAB）が Codex と一緒に「Windows 11 の WSL2 Ubuntu + Bash 上で
`codex` を叩いて、画像生成と画像編集が本当にそのまま通るのか」を確かめて
いたところ、実際に出力できたので、自分のための覚書として残したものを、
同じ疑問を持つ方向けに共有するリポジトリです。

> これは 2026-04-18 時点での、私一人 + Codex 分の検証結果をまとめた
> 個人的な覚書です。同じコマンドや同じ手順を読者に推奨しているわけでは
> ありません。Codex CLI はアップデートが早く、今後のリリース、仕様変更、
> 新しい発見、公式の発表などで、ここに書いている内容が変わったり、
> 誤解や不備が見つかる可能性は十分にあります。**この時点の 1 つの
> 参考情報** としてご覧ください。もっと良いコマンドの書き方、フラグの
> 指定方法、ツールの構成の仕方はきっとあるはずなので、ご自身の環境で
> いろいろ試していただけるのがこの共有の本来の意図です。

**検証日:** 2026-04-18
**環境:** Windows 11 + WSL2 + Ubuntu + Bash + `codex-cli 0.121.0`
**検証者:** TK2LAB, Codex（CLI 側）

## どこから読むか

| 目的 | 開く |
| --- | --- |
| 私が実際に走らせたコマンドだけを追いたい（再現確認） | [QUICKSTART.ja.md](QUICKSTART.ja.md) / [QUICKSTART.en.md](QUICKSTART.en.md) |
| 環境バージョン、観察、アスペクト比、JSON spec、よく聞く話との対比まで読みたい | [README.ja.md](README.ja.md) / [README.en.md](README.en.md) |
| 変更履歴 | [CHANGELOG.md](CHANGELOG.md) |

## 同梱ファイル

- `codex-image-batch.sh` — 複数枚の生成・編集ジョブを JSON で流せると
  便利だったので書いた個人的な Bash 補助スクリプト。お勧めではなく、
  あくまで参考実装です。より良い書き方・設計はきっとあります。
- `examples/codex-image-batch.sample.json` — 生成ジョブのサンプル × 5
- `examples/codex-image-edit-batch.sample.json` — 編集ジョブのサンプル × 3
- `examples/input/README.md` — 編集入力用フォルダのプレースホルダ

---

# Codex CLI Image Generation — Personal Notes (WSL2 Ubuntu, as of 2026-04-18)

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

## Start here

| If you want to... | Open |
| --- | --- |
| Reproduce the exact commands I ran | [QUICKSTART.en.md](QUICKSTART.en.md) / [QUICKSTART.ja.md](QUICKSTART.ja.md) |
| Read the full write-up — versions, observations, aspect ratios, JSON spec, and a review of common claims against what I saw here | [README.en.md](README.en.md) / [README.ja.md](README.ja.md) |
| Review release history | [CHANGELOG.md](CHANGELOG.md) |

## What ships with this package

- `codex-image-batch.sh` — a small Bash helper I put together because
  running several image jobs from a JSON spec was convenient for my own
  workflow. It is a reference implementation shared as-is, not a
  recommended tool. Cleaner designs almost certainly exist.
- `examples/codex-image-batch.sample.json` — five sample generation jobs
- `examples/codex-image-edit-batch.sample.json` — three sample edit jobs
- `examples/input/README.md` — placeholder for edit-input images
