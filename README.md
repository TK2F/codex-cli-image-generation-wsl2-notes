# Codex CLI で画像生成 × WSL2 Ubuntu — 検証記録と batch runner

Windows 11 の WSL2 Ubuntu 上の Bash から `codex` を呼び出して、画像生成と
画像編集が本当にできるのかを実地で確かめた記録と、1 枚から複数枚に
スケールするための小さな runner をまとめたリポジトリです。

> TK2LAB と Codex が手を動かして確かめた小さな実験の記録です。正式な
> ベンチマークや網羅的な検証ではありません。環境や時期が違えば同じように
> 動かない可能性がある点をご了承ください。

**Validated:** 2026-04-19 / `codex-cli 0.121.0`
**Shell:** WSL2 Ubuntu の Bash（Windows PowerShell ネイティブ実行は対象外）
**Validators:** TK2LAB, Codex

## どこから読むか

| 目的 | 開く |
| --- | --- |
| まず 1 枚生成してみたい（前提のインストールから） | [QUICKSTART.ja.md](QUICKSTART.ja.md) / [QUICKSTART.en.md](QUICKSTART.en.md) |
| 仕様、debunk、アスペクト比、JSON spec の全体像 | [README.ja.md](README.ja.md) / [README.en.md](README.en.md) |
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

> This is a small, hands-on experiment by TK2LAB and Codex, not a formal
> benchmark. Your mileage may vary as environments and CLI versions
> evolve — claims here are limited to what was actually observed.

**Validated:** 2026-04-19 / `codex-cli 0.121.0`
**Shell:** Bash inside WSL2 Ubuntu (native Windows PowerShell is out of scope)
**Validators:** TK2LAB, Codex

## Start here

| If you want to... | Open |
| --- | --- |
| Get one image out today, from zero setup | [QUICKSTART.en.md](QUICKSTART.en.md) / [QUICKSTART.ja.md](QUICKSTART.ja.md) |
| See the full notes, debunked assumptions, and references | [README.en.md](README.en.md) / [README.ja.md](README.ja.md) |
| Review release history | [CHANGELOG.md](CHANGELOG.md) |

## What ships with this package

- `codex-image-batch.sh` — a small WSL/Bash runner for one-off prompts,
  JSON batches, and image edits, with doctor, preview, retry, and
  fallback recovery
- `examples/codex-image-batch.sample.json` — five generation jobs
- `examples/codex-image-edit-batch.sample.json` — three edit jobs
- `examples/input/README.md` — placeholder for edit-input images
