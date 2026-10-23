#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker が見つかりません。Docker Desktop をインストールしてから、もう一度実行してください。"
  exit 1
fi
if ! docker info >/dev/null 2>&1; then
  echo "Docker が起動していません。Docker Desktop を起動してから、もう一度実行してください。"
  exit 1
fi

echo "==> コンテナを起動しています（初回は数分かかります）"
docker compose up -d --build --wait app

chmod +x bin/*

cat <<'MSG'

セットアップが完了しました！
http://localhost:3000 を開いて、日記の一覧が表示されれば準備完了です。

  bin/exec <コマンド>   コンテナの中でコマンドを実行する（例: bin/exec bin/rails db:reset）
  bin/restart          サーバーを再起動する（Gemfile を変えたとき、ブランチを切り替えたとき）
  bin/console          rails console を開く
  bin/logs             サーバーのログを見る

MSG
