# ひみつ日記（Rails 認証ハンズオン）

Rails 8 で認証機能の仕組みを学ぶ、90分ハンズオン用のアプリです。
各ステップには「動くけれど穴がある」コードが用意されています。コードを読み、穴を試し、核心の数行を書き換えて直します。

## 当日の資料

- [docs/handson.md](docs/handson.md)：**教材**。各ステップの手順とコピペ用のコード（スライドの「教材の 2-3」は、この教材の 2-3 の節）
- [docs/slides/handson-90min.pdf](docs/slides/handson-90min.pdf)：当日投影するスライド（PDF）
- [docs/slides/handson-90min.md](docs/slides/handson-90min.md)：同じ内容の Markdown 版（[Marp](https://marp.app/) 形式、スピーカーノート付き）

## 必要なもの

- Docker Desktop（起動しておいてください）
- git

Ruby や Rails を自分の PC に入れる必要はありません。すべて Docker の中で動きます。

## セットアップ（イベント前に済ませてください）

```bash
git clone <このリポジトリの URL>
cd secret_diary
git checkout step-01-start
./setup.sh
```

「セットアップが完了しました！」と出たら、http://localhost:3000 を開いてください。日記の一覧が表示されれば準備完了です。初回は Docker イメージのダウンロードがあるので数分かかります。

## コマンド

Rails のコマンドは、コンテナの中で動かします。スライドや教材に出てくる `bin/rails …` は、頭に `bin/exec` を付けて実行してください。

| コマンド | 内容 |
| --- | --- |
| `bin/exec <コマンド>` | コンテナの中でコマンドを実行する（例：`bin/exec bin/rails db:reset`） |
| `bin/restart` | サーバーを再起動する。Gemfile やマイグレーションの変更もここで反映される |
| `bin/console` | rails console を開く |
| `bin/logs` | サーバーのログを見る（Ctrl+C で終了） |

ソースコードは手元のフォルダがそのままコンテナに共有されています。ファイルを編集すれば、再起動しなくてもすぐ反映されます（Gemfile を変えたときだけ `bin/restart` が必要です）。

## ブランチ

| ブランチ | 内容 |
| --- | --- |
| `step-01-start` / `step-01-done` | Step 1 ユーザー登録：パスワードを平文で保存 → `has_secure_password` |
| `step-02-start` / `step-02-done` | Step 2 ログイン：エラーメッセージで登録の有無が分かる → `authenticate_by` と `reset_session` |
| `step-03-start` / `step-03-done` | Step 3 自分の日記だけ：`Diary.find` と hidden の `user_id` → `current_user.diaries` |
| `step-04-start` / `step-04-done` | Step 4 パスワードリセット：Base64 のトークン → `password_reset_token`（当日は講師デモ） |
| `step-05-start` | Step 5 CSRF：体験のために CSRF 対策を外した状態（宿題） |
| `main` | 完成版。`bin/exec bin/rails test` で攻撃が塞がれていることを確認できる |

遅れたときは、次のステップの `start` ブランチに切り替えれば合流できます。

```bash
git stash -u                    # 手元の変更を退避（必要なら）
git checkout step-03-start
bin/restart
bin/exec bin/rails db:reset     # Step 3 以降はデータを作り直す
```

## ログイン用のユーザー（Step 3 以降）

`bin/exec bin/rails db:reset` で次の2人が作られます。

| メールアドレス | パスワード |
| --- | --- |
| alice@example.com | password |
| bob@example.com | password |

## 便利な URL

- http://localhost:3000/letter_opener ：開発環境で送ったメールを確認できます（Step 4）

## Step 5（CSRF）の罠ページ

```bash
git checkout step-05-start
bin/restart
docker compose --profile csrf up -d evil
```

ログインした状態で http://localhost:8000 を開くと、日記（ID 1）が削除されます。`step-05-start` でだけ成功します。
終わったら `docker compose --profile csrf stop evil` で止めてください。

## 困ったとき

| 症状 | 対処 |
| --- | --- |
| `Docker が起動していません` と出る | Docker Desktop を起動してから `./setup.sh` をやり直す |
| `bin/exec` で `service "app" is not running` と出る | `./setup.sh` をやり直す |
| 画面に `Migrations are pending` と出る | `bin/restart`。それでも出るときは `bin/exec bin/rails db:reset` |
| ブランチを切り替えたら画面がエラーになった | `bin/restart` のあと `bin/exec bin/rails db:reset` |
| ポート 3000 が使われていると出る | 別で動かしている Rails サーバーなどを止める |
| PC の動きが重い | 終わったら `docker compose stop` でコンテナを止める |
| 全部消してやり直したい | `docker compose down -v` と `rm -f storage/*.sqlite3` のあと `./setup.sh` |

## 注意

ここで試す攻撃は、自分の PC で動かしているこのアプリにだけ行ってください。実在のサービスで同じことをすると、不正アクセス禁止法に違反するおそれがあります。
