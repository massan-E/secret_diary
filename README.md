# ひみつ日記（Rails 認証ハンズオン）

Rails 8 で認証機能の仕組みを学ぶ、90分ハンズオン用のアプリです。
各ステップには「動くけれど穴がある」コードが用意されています。コードを読み、穴を試し、核心の数行を書き換えて直します。

## セットアップ（イベント前に済ませてください）

```bash
git clone <このリポジトリの URL>
cd secret_diary
git checkout step-01-start
bin/setup
```

`bin/setup` が終わるとサーバーが起動します。http://localhost:3000 を開いて、日記の一覧が表示されれば準備完了です。

## ブランチ

| ブランチ | 内容 |
| --- | --- |
| `step-01-start` / `step-01-done` | Step 1 ユーザー登録：パスワードを平文で保存 → `has_secure_password` |
| `step-02-start` / `step-02-done` | Step 2 ログイン：エラーメッセージで登録の有無が分かる → `authenticate_by` と `reset_session` |
| `step-03-start` / `step-03-done` | Step 3 自分の日記だけ：`Diary.find` と hidden の `user_id` → `current_user.diaries` |
| `step-04-start` / `step-04-done` | Step 4 パスワードリセット：Base64 のトークン → `password_reset_token`（当日は講師デモ） |
| `step-05-start` | Step 5 CSRF：体験のために CSRF 対策を外した状態（宿題） |
| `main` | 完成版。`bin/rails test` で攻撃が塞がれていることを確認できる |

遅れたときは、次のステップの `start` ブランチに切り替えれば合流できます。

```bash
git stash -u            # 手元の変更を退避（必要なら）
git checkout step-03-start
bin/rails db:reset      # Step 3 以降はデータを作り直す
```

## ログイン用のユーザー（Step 3 以降）

`bin/rails db:reset` で次の2人が作られます。

| メールアドレス | パスワード |
| --- | --- |
| alice@example.com | password |
| bob@example.com | password |

## 便利な URL

- http://localhost:3000/letter_opener ：開発環境で送ったメールを確認できます（Step 4）

## Step 5（CSRF）の罠ページ

```bash
python3 -m http.server 8000 --directory evil_site
```

ログインした状態で http://localhost:8000 を開くと、日記（ID 1）が削除されます。`step-05-start` でだけ成功します。

## 注意

ここで試す攻撃は、自分の PC で動かしているこのアプリにだけ行ってください。実在のサービスで同じことをすると、不正アクセス禁止法に違反するおそれがあります。
