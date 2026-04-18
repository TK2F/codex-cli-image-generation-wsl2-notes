# クイックスタート

WSL 上で最短で動かすための手順です。

## 1. 共有フォルダへ移動

```bash
cd /path/to/share
```

## 2. 環境を確認

```bash
bash ./codex-image-batch.sh --doctor
```

もし `codex` が `PATH` に無い場合は、実体を明示して同じ診断を実行します。

```bash
CODEX_BIN="$HOME/.nvm/versions/node/<your-version>/bin/codex" \
  bash ./codex-image-batch.sh --doctor
```

`<your-version>` は自分の Node バージョンに置き換えてください。

## 3. preview で確認

```bash
bash ./codex-image-batch.sh --spec ./examples/codex-image-batch.sample.json --preview
```

この段階では画像生成は走らず、prompt と command だけが表示されます。

## 4. sample batch を実行

```bash
bash ./codex-image-batch.sh --spec ./examples/codex-image-batch.sample.json --pause-at-end
```

## 5. 手入力で 1 本だけ試す

```bash
bash ./codex-image-batch.sh --manual --pause-at-end
```

## よく使うフラグ

- `--preview`
  生成せずに確認だけする
- `--doctor`
  依存関係と Codex の検出状況を確認する
- `--overwrite`
  既存出力を上書きする
- `--pause-at-end`
  実行後に Enter 待ちにする
- `--list-presets`
  組み込みの aspect/style preset を表示する

## 何か失敗したら

- 詳細は `README.ja.md` を読む
- もう一度 `--doctor` を実行する
- まず `--preview` で確認する
- 各ジョブの raw log と summary JSON を確認する
