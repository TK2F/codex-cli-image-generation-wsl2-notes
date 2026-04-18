# Codex CLI で画像生成 × WSL2 Ubuntu — 検証記録と batch runner

Windows 11 の WSL2 Ubuntu 上の Bash から `codex` を呼び出して、画像生成と
画像編集が本当にできるのかを実地で確かめた記録と、1 枚から複数枚に
スケールするための小さな runner をまとめたリポジトリです。

> これは TK2LAB と Codex が、Windows 11 + WSL2 + Ubuntu + Bash +
> `codex-cli 0.121.0` という具体的な組み合わせで確かめた一人称の
> フィールドレポートです。「この環境でこう試した」「結果はこうだった」
> 「公式ドキュメントにはこう書かれていた」を並べた記録であり、同じ
> セットアップを推奨するものでも、同じ手順を読者に勧めるものでも
> ありません。詳細なバージョン一覧と確認コマンドは
> [README.ja.md](README.ja.md#検証環境のバージョンと確認コマンド) /
> [README.en.md](README.en.md#environment-versions-and-how-to-check-them)
> にまとめています。ぜひお手元で同じコマンドを走らせて、差分を比較して
> みてください。

**Validated:** 2026-04-19 / `codex-cli 0.121.0`
**Shell:** WSL2 Ubuntu の Bash（Windows PowerShell ネイティブ実行は対象外）
**Validators:** TK2LAB, Codex

## どこから読むか

| 目的 | 開く |
| --- | --- |
| まず 1 枚生成してみたい（前提のインストールから） | [QUICKSTART.ja.md](QUICKSTART.ja.md) / [QUICKSTART.en.md](QUICKSTART.en.md) |
| 検証環境のバージョン、観察詳細、アスペクト比、JSON spec、よく流れてくる話と今回の観察の対比 | [README.ja.md](README.ja.md) / [README.en.md](README.en.md) |
| 変更履歴 | [CHANGELOG.md](CHANGELOG.md) |

## 同梱ファイル

- `codex-image-batch.sh` — WSL/Bash 向けの runner
  （one-off / JSON batch / edit、`--doctor` / `--preview` / retry / fallback
  リカバリ付き）
- `examples/codex-image-batch.sample.json` — 生成ジョブ × 5
- `examples/codex-image-edit-batch.sample.json` — 編集ジョブ × 3
- `examples/input/README.md` — 編集入力用フォルダのプレースホルダ

---

# Codex CLI Image Generation in WSL2 Ubuntu — Field Test and Batch Runner

This repository is a hands-on record of generating and editing images with
Codex CLI from a Bash shell inside WSL2 Ubuntu on Windows 11, plus a
small runner that smooths out the rough edges once one-off commands are
not enough.

> This is a first-person field report by TK2LAB and Codex, carried out
> on Windows 11 + WSL2 + Ubuntu + Bash + `codex-cli 0.121.0`. It is not
> a recommendation of that exact stack or of the steps used. Please
> validate on your own environment. The full version table and the
> commands used to read each version are in
> [README.en.md](README.en.md#environment-versions-and-how-to-check-them).

**Validated:** 2026-04-19 / `codex-cli 0.121.0`
**Shell:** Bash inside WSL2 Ubuntu (native Windows PowerShell is out of scope)
**Validators:** TK2LAB, Codex

## Start here

| If you want to... | Open |
| --- | --- |
| Get one image out today, from zero setup | [QUICKSTART.en.md](QUICKSTART.en.md) / [QUICKSTART.ja.md](QUICKSTART.ja.md) |
| See the full environment table, observations, claim review, and references | [README.en.md](README.en.md) / [README.ja.md](README.ja.md) |
| Review release history | [CHANGELOG.md](CHANGELOG.md) |

## What ships with this package

- `codex-image-batch.sh` — a small WSL/Bash runner for one-off prompts,
  JSON batches, and image edits, with doctor, preview, retry, and
  fallback recovery
- `examples/codex-image-batch.sample.json` — five generation jobs
- `examples/codex-image-edit-batch.sample.json` — three edit jobs
- `examples/input/README.md` — placeholder for edit-input images
