---
marp: true
title: Railsで作って学ぶ 認証ハンズオン（90分版）
paginate: true
---

# Railsで作って学ぶ 認証ハンズオン

用意されたコードを読み、試して、自分の手で直す。

`$ git checkout step-01-start`

**90分** ／ Rails 8 / has_secure_password

<!-- 90分版。各ステップの「素朴な実装」は配布ブランチに最初から入っています。参加者が書くのは、直すための数行だけです。環境構築は事前に済ませてもらっている前提です。 -->

---

## 今日の流れ

| 時間 | ステップ | あなたがやること |
| --- | --- | --- |
| 0:00 | はじめに・起動確認 | アプリが動くか確認 |
| 0:08 | Step 1 ユーザー登録 | 読む・試す・直す |
| 0:25 | Step 2 ログイン・ログアウト | 読む・試す・直す |
| 0:45 | Step 3 自分の日記だけ | 読む・試す・直す |
| 1:10 | Step 4 パスワードリセット | 講師デモを見る |
| 1:20 | まとめ・質疑 | 宿題の案内 |

<!-- 手を動かすのは Step 1〜3 の約60分。Step 3 が一番大事なので25分取っています。押したら Step 4 のデモを短くして調整。 -->

---

## 各ステップの進め方

1. **読む**：用意されたコードを、スライドと一緒に読む
2. **試す**：ブラウザやコマンドで、穴を突いてみる
3. **直す**：核心の数行だけ書き換える
4. **確かめる**：同じことが通らなくなったか見る

遅れても大丈夫。`git checkout step-XX-start` で次のステップから合流できます。

試してよいのは**自分の PC のアプリだけ**。実在のサービスで試すのは違法です。

<!-- コードを一から書かないので、つまずきにくい。「読む」はスライドで講師が解説し、参加者はエディタで同じファイルを開いて追いかける。 -->

---

## 「ひみつ日記」の認証機能を完成させる

| 機能 | ステップ |
| --- | --- |
| 新規登録 | Step 1 ・ 手を動かす |
| ログイン・ログアウト | Step 2 ・ 手を動かす |
| 自分の日記だけ | Step 3 ・ 手を動かす |
| パスワード再設定 | Step 4 ・ デモ |

各機能は「動くけれど、穴がある」状態で用意してあります。

<!-- 起動確認のついでに、ログインせずに日記が見えることを確認してもらってからこのスライドへ。 -->

---

## 認証機能は、この部品でできている

| 部品 | 役割 | 登場 |
| --- | --- | --- |
| User モデル | メールアドレスとパスワードを持つ | Step 1 |
| UsersController | 新規登録 | Step 1 |
| SessionsController | ログイン・ログアウト | Step 2 |
| session ＋ current_user | 今ログインしている人を覚える | Step 2 |
| before_action ＋ 関連 | 自分の日記だけを扱う | Step 3 |
| PasswordsController | パスワード再設定 | Step 4 |

<!-- Devise や sorcery も、中ではこれと同じ部品を持っている。迷子になったらこの表に戻る。 -->

---

# Step 1 ・ 17分　ユーザー登録

パスワードは「ハッシュ化」して保存する

- 読む：登録の流れ
- 試す：DB の中身を見る
- 直す：has_secure_password

<!-- git checkout step-01-start してもらう。 -->

---

## Step 1 ｜ 読む：登録は「表示」と「保存」の2往復

```text
GET  /users/new  →  UsersController#new     →  フォームを表示
POST /users      →  UsersController#create  →  User.new(user_params).save
```

```ruby
# db/schema.rb（users テーブル）
t.string "email_address"
t.string "password"
```

password という列に、**入力されたまま**保存している。

<!-- 開くファイル：config/routes.rb、app/controllers/users_controller.rb、db/schema.rb。scaffold の new / create と同じ形なので、見覚えがあるはず。form_with model: @user が POST /users を自動で選ぶ。 -->

---

## Step 1 ｜ 試す：登録して、DB の中身を見てみる

```console
$ bin/rails runner 'pp User.pluck(:email_address, :password)'
[["alice@example.com", "password123"]]
```

- **DB が漏れたら全員分**：全員のパスワードがそのまま読める。
- **被害は他サービスへ**：使い回している人は、他のサービスにもログインされる。

<!-- 手順：http://localhost:3000/users/new で1人登録 → 上のコマンドを実行。所要3分。 -->

---

## Step 1 ｜ 直す前に：ハッシュ化は元に戻せない形で保存する

| | 入力 | 処理 | 結果 |
| --- | --- | --- | --- |
| 登録時 | password123 ＋ ランダムなソルト | bcrypt | `$2a$12$…` を password_digest に保存 |
| ログイン時 | 入力された値 ＋ 保存済みのソルト | bcrypt | 保存値と同じならログイン成功 |

元のパスワードは**どこにも保存しない**。同じ計算をして比べるだけ。

<!-- この仕組みを丸ごとやってくれるのが has_secure_password。次のスライドで書き換える。 -->

---

## Step 1 ｜ 直す：書き換えるのは4か所

1. Gemfile の bcrypt を有効化 → `bundle install` → **サーバー再起動**
2. password 列を password_digest 列に入れ替える（教材のマイグレーションをコピペ）
3. User モデルに `has_secure_password` を1行
4. `user_params` とフォームに `password_confirmation`

この1行で増えるもの：`password=` / `password_confirmation` / `authenticate` / `password_reset_token`

確かめる：同じパスワードで2人登録 → runner で `password_digest` を見る。値が2人とも違えば OK

<!-- つまずきポイント：bundle install 後にサーバーを再起動しないと bcrypt が読み込まれずエラーになる。DB の列名は password_digest なのに password と書けるのは、has_secure_password が password= を足すから。値が2人で違うのはソルトのおかげ。 -->

---

## Step 1 ｜ ひとこと解説：暗号化じゃダメなの？

| 暗号化 | ハッシュ化 |
| --- | --- |
| 鍵があれば元に戻せる。鍵ごと盗まれたら終わり。 | 戻す方法がそもそもない。サーバーも元の値を知らなくていい。 |

<!-- 2026年10月にも「パスワードを暗号化して保存していたが、復号できるシステムに侵入されて平文で流出した」という事件が報じられている（ソースネクスト）。質問が出たら紹介する程度で OK。Step 2 で出てくる cookie は、サーバーが中身を読む必要があるので暗号化を使う、と予告しておく。 -->

---

# Step 2 ・ 20分　ログイン・ログアウト

ログインとは、session に user_id を書くこと

- 読む：session と current_user
- 試す：cookie・エラーメッセージ
- 直す：authenticate_by

<!-- git checkout step-02-start してもらう。 -->

---

## Step 2 ｜ 読む：session は「ユーザーごとのメモ帳」

| 書く（ログイン） | 読む（次のページ） | 消す（ログアウト） |
| --- | --- | --- |
| `session[:user_id] = user.id` | `session[:user_id]` | `reset_session` |

中身は**暗号化**されて cookie としてブラウザへ → ブラウザは毎回のリクエストに cookie を**自動で**付ける

<!-- HTTP は前のページで何をしたかを覚えていないので、session で覚えておく。cookie はサーバーが中身を読む必要があるから、ハッシュではなく暗号化（Step 1 の話とつなげる）。 -->

---

## Step 2 ｜ 読む：用意されているログインのコード

```ruby
# sessions_controller.rb（create）
user = User.find_by(email_address: …)
if user.nil?
  「登録されていません」
elsif user.authenticate(params[:password])
  session[:user_id] = user.id
else
  「パスワードが違います」
end
```

```ruby
# application_controller.rb
helper_method :current_user

def current_user
  @current_user ||=
    User.find_by(id: session[:user_id])
end
```

`helper_method` でビューからも使える。`||=` で DB を引くのは1回だけ。

<!-- 左は「親切な」エラーメッセージを出している素朴な実装。何が問題かは次で試す。右の current_user はこの後のステップでずっと使う。ログインしていなければ nil、していれば User。実際のコードには「if session[:user_id]」も付いている。 -->

---

## Step 2 ｜ 試す：2つ試してみる

**A　cookie を書き換える**
DevTools → Application → Cookies で、値を1文字変えてリロード
→ ログアウトされる。暗号化されているので、**他人にはなれない**（これは Rails が守ってくれている）

**B　エラーメッセージを比べる**
未登録のアドレス／登録済みで間違ったパスワード
→ メッセージが違うので、**どのアドレスが登録済みか**分かってしまう

<!-- A は「失敗する攻撃」で、Rails が既に守ってくれている部分。B が直すべき穴。集めたアドレスは、他サービスから漏れたパスワードを試す攻撃に使われる。所要5分。 -->

---

## Step 2 ｜ 直す：create と destroy を書き換える

```ruby
if user = User.authenticate_by(
     email_address: params[:email_address],
     password: params[:password])
  reset_session
  session[:user_id] = user.id
else
  「メールアドレスまたはパスワードが違います」
end
```

- `authenticate_by`：探す＋照合を1回で。合えば user、違えば nil
- `reset_session`：ログイン前の session を引き継がない。destroy でも使う

確かめる：未登録でもパスワード違いでも、同じメッセージが出れば OK

<!-- authenticate_by はユーザーが存在しないときもハッシュ計算をするので、応答時間の差でも登録の有無が分からないようになっている。詳しいコードは教材の 2-3 をコピペ。 -->

---

# Step 3 ・ 25分　自分の日記だけ

ログインできることと、見てよいことは別

- 読む：関連と before_action
- 試す：URL と hidden を書き換える
- 直す：current_user.diaries

<!-- git checkout step-03-start → bin/rails db:reset でアリスとボブのデータを入れる。今日いちばん大事なステップ。 -->

---

## Step 3 ｜ 読む：用意されている2つの仕組み

**日記に持ち主を付ける**

```ruby
User  has_many :diaries
Diary belongs_to :user
```

diaries テーブルに user_id 列。`current_user.diaries` で「自分の日記」が取れる。

**ログインしていない人を止める**

```ruby
before_action :require_login
```

全アクションの前に実行。未ログインならログイン画面へ。登録・ログイン画面だけ skip。

一覧は `current_user.diaries` で自分の分だけ。**……でも、詳細画面は？**

<!-- 開くファイル：app/models/user.rb、diary.rb、application_controller.rb、diaries_controller.rb。DiariesController の set_diary が scaffold のまま Diary.find になっていることに気づかせたい。 -->

---

## Step 3 ｜ 試す：アリスとしてログインして試す

**A　他人の日記を読む**
`/diaries/1` → `/diaries/2`
URL を書き換えるだけで、ボブの日記が読める。編集もできる。

**B　他人の名義で書く**
新規作成フォームの hidden `diary[user_id]` の value を DevTools で `2` に書き換えて送信。ボブの日記が増える。

一覧に出さないこと ≠ **アクセスできないこと**。ブラウザから来る値は全部書き換えられる。

<!-- ログイン情報：alice@example.com / password。B の結果はシークレットウィンドウで bob@example.com としてログインして確認。A の穴は IDOR と呼ばれ、実際の情報流出事故でも頻出。所要8分。 -->

---

## Step 3 ｜ 直す：日記は必ず current_user から取る

```ruby
# 直す前
Diary.find(id)
Diary.new(diary_params)
[:title, :body, :user_id]

# 直した後
current_user.diaries.find(id)
current_user.diaries.build(…)
[:title, :body]
```

```sql
SELECT * FROM diaries WHERE user_id = 1 AND id = 2  -- → 見つからない
```

フォームの hidden_field も削除。持ち主は送られてきた値ではなく、サーバーが知っている current_user で決める。

<!-- set_diary は show / edit / update / destroy 共通なので、1か所直せば全部に効く。確かめる：/diaries/2 が RecordNotFound（本番は 404）、hidden を足して送っても自分の日記になる。 -->

---

# Step 4 ・ 講師デモ 10分　パスワードリセット

「URL を持っている人 = 本人」とみなす仕組み

メールアドレス入力 → トークン付き URL をメール → 新しいパスワードを保存

<!-- 手を動かすのは宿題。ここでは講師の画面を見てもらうだけ。だからこそ「トークンを推測・偽造できたら誰のアカウントでも乗っ取れる」がポイント。 -->

---

## Step 4 ｜ デモ①：トークンが Base64(user_id) だったら

| メールで届いた URL | 誰でも作れる URL |
| --- | --- |
| `/passwords/MQ==/edit` | `/passwords/Mg==/edit` |
| `MQ==` → 1（アリス） | 2 → `Mg==`（ボブ） |

Base64 は暗号化ではなく、ただの変換。鍵がないので誰でも戻せるし、誰でも作れる。

<!-- デモ：step-04-start で、アリスのリセットメールを letter_opener で開く → MQ== をデコード → Mg== を作ってボブのパスワードを変える → ボブとしてログインできてしまう。 -->

---

## Step 4 ｜ デモ②：Rails の password_reset_token

```text
eyJfcmFpbHMiOnsiZGF0YSI6WzEs…--b58f09ba4871a8ee…
```

| `--` の前：中身 | `--` の後：署名 |
| --- | --- |
| ユーザー ID・有効期限（15分）・用途。デコードすれば読める | 中身を1文字でも変えると一致しない。パスワードを変えると古いトークンも無効 |

has_secure_password を書いた時点で、**これはもう使える**。

<!-- デモ：step-04-done でトークンをデコードして中身を見せる → ID を書き換えると弾かれる → 一度使ったリンクがもう使えない。Step 1 で書いた has_secure_password がここで効いてくる、とつなげる。 -->

---

## まとめ：今日あなたが直したもの

| 機能 | 書いたコード | 防いだこと |
| --- | --- | --- |
| 新規登録 | `has_secure_password` | パスワードの丸見え |
| ログイン | `authenticate_by` / `reset_session` | 登録済みアドレスの漏れ |
| 日記 | `current_user.diaries` | 他人の日記の閲覧・なりすまし |

そして、フォームには Rails が最初から **CSRF トークン**という安全装置を入れてくれている（宿題で体験）。

<!-- Devise や sorcery を使っても、中ではこれと同じことが行われている。中身を知っていれば、ライブラリの設定やカスタマイズで迷わなくなる。 -->

---

## 宿題：続きは自分の手で

| | 内容 |
| --- | --- |
| Step 4 | パスワードリセットを自分で直す（今日のデモの再現） |
| Step 5 | CSRF：罠ページを開くだけで日記が消える体験 |
| 答え合わせ | `bin/rails generate authentication` と自作版の diff を取る |
| レートリミット | `rate_limit` で総当たりを止める |

<!-- 手順は README と各ブランチを参照。 -->
