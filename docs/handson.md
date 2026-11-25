# ひみつ日記 ハンズオン教材

スライドと一緒に使う手順書です。スライドに「教材の 2-3」とあれば、この教材の「2-3」の節を見てください。

- 各ステップは「N-1 読む → N-2 試す → N-3 直す → N-4 確かめる」の順に進みます
- コードは一から書きません。「直す」の節にあるコードを、指定の場所にコピペしてください
- コマンドはすべて手元のターミナルで、リポジトリのフォルダ（`secret_diary`）で実行します
- Rails のコマンドは Docker の中で動かすので、頭に `bin/exec` を付けます（例：`bin/exec bin/rails runner '…'`）
- ファイルを編集すると、再起動しなくてもすぐ反映されます。Gemfile やマイグレーションを変えたときだけ `bin/restart` が必要です

> 試してよいのは、自分の PC で動かしているこのアプリだけです。実在のサービスで同じことをすると、不正アクセス禁止法に違反するおそれがあります。

---

## 0. はじめに

### 0-1. 起動確認

```bash
git checkout step-01-start
./setup.sh          # まだの人だけ。済んでいる人は bin/restart
```

http://localhost:3000 を開いて、日記の一覧が表示されれば OK です。
ログインしていないのに日記が見えていることも確認しておいてください（Step 3 で直します）。

### 0-2. 遅れたとき・次のステップへ進むとき

各ステップの最初に、そのステップの `start` ブランチへ切り替えます。途中のステップからでも合流できます。

```bash
git stash -u                    # 手元の変更を退避（自分の変更を残したまま切り替えるため）
git checkout step-02-start      # 進みたいステップの start ブランチ
bin/restart
bin/exec bin/rails db:reset     # データを作り直す（Step 3 以降は必須）
```

答えを見たいときは、`step-XX-done` ブランチがそのステップの完成形です。

```bash
git diff step-01-start step-01-done    # Step 1 で何を変えたか
```

---

## Step 1 ユーザー登録：パスワードをハッシュ化して保存する

ブランチ：`step-01-start`

### 1-1. 読む

| ファイル | 見るところ |
| --- | --- |
| `config/routes.rb` | `resources :users, only: %i[new create]` |
| `app/controllers/users_controller.rb` | `new` でフォームを表示、`create` で `User.new(user_params).save` |
| `app/views/users/new.html.erb` | `form_with model: @user` が `POST /users` を自動で選ぶ |
| `db/schema.rb` | users テーブルに `password` という列がある |

`password` 列に、入力されたままの文字列を保存しています。

### 1-2. 試す

1. http://localhost:3000/users/new で1人登録する（例：`alice@example.com` / `password123`）
2. DB の中身を見る

```bash
bin/exec bin/rails runner 'pp User.pluck(:email_address, :password)'
# => [["alice@example.com", "password123"]]
```

パスワードがそのまま読めてしまいます。

### 1-3. 直す

書き換えるのは4か所です。

**① Gemfile の bcrypt を有効にする**

```ruby
# Gemfile（行頭の # を消す）
gem "bcrypt", "~> 3.1.7"
```

**② password 列を password_digest 列に入れ替えるマイグレーションを作る**

次の名前で新しいファイルを作り、中身をコピペします（ファイル名もこのとおりにしてください。次のステップのブランチと同じ名前にそろえるためです）。

`db/migrate/20261023000558_replace_password_with_password_digest_on_users.rb`

```ruby
class ReplacePasswordWithPasswordDigestOnUsers < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :password, :string
    add_column :users, :password_digest, :string
  end
end
```

ここまでできたら、再起動します。`bundle install` とマイグレーションが自動で実行されます。

```bash
bin/restart
```

**③ User モデルに has_secure_password を足す**

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_secure_password

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  validates :email_address, presence: true, uniqueness: true
end
```

**④ password_confirmation を受け取れるようにする**

```ruby
# app/controllers/users_controller.rb
def user_params
  params.expect(user: [ :email_address, :password, :password_confirmation ])
end
```

```erb
<%# app/views/users/new.html.erb（password の行の下に1行足す） %>
<%= f.password_field :password_confirmation, placeholder: "パスワード（確認）", required: true %>
```

`has_secure_password` の1行で、`password=` / `password_confirmation` / `authenticate` / `password_reset_token` が使えるようになります。
DB の列は `password_digest` なのにフォームでは `password` と書けるのは、`has_secure_password` が `password=` を足してくれるからです。

### 1-4. 確かめる

1. 同じパスワードで2人登録する（例：`carol@example.com` と `dave@example.com`、どちらも `password123`）
2. DB の中身を見る

```bash
bin/exec bin/rails runner 'pp User.pluck(:email_address, :password_digest)'
```

`$2a$12$…` のような値が入っていて、**2人の値が違えば OK** です（ソルトのおかげ）。

| こうなったら | こうする |
| --- | --- |
| `bcrypt` が見つからないエラー | `bin/restart` を忘れていないか確認 |
| `Migrations are pending` | `bin/restart`。それでも出るときは `bin/exec bin/rails db:reset` |
| 登録画面で `Password confirmation doesn't match` | 確認欄に同じパスワードを入れる |

---

## Step 2 ログイン・ログアウト：エラーメッセージから登録の有無を漏らさない

ブランチ：`step-02-start`（切り替え方は 0-2）

### 2-1. 読む

| ファイル | 見るところ |
| --- | --- |
| `app/controllers/sessions_controller.rb` | `create` でメールアドレスを探して、なければ「登録されていません」、パスワードが違えば「パスワードが違います」 |
| `app/controllers/application_controller.rb` | `current_user`：`session[:user_id]` から User を引く。`helper_method` でビューからも使える |

### 2-2. 試す

**A：cookie を書き換える**

1. ログインする
2. DevTools → Application → Cookies → `_secret_diary_session` の値を1文字変えて、リロード
3. ログアウトされる。中身が暗号化されているので、他人にはなれない（Rails が守ってくれている部分）

**B：エラーメッセージを比べる**

1. ログアウトして、未登録のアドレスでログインしてみる →「そのメールアドレスは登録されていません」
2. 登録済みのアドレスで、間違ったパスワードを入れる →「パスワードが違います」
3. メッセージが違うので、**どのアドレスが登録済みか分かってしまう**

### 2-3. 直す

`app/controllers/sessions_controller.rb` の `create` と `destroy` を、次のように書き換えます。

```ruby
def create
  if user = User.authenticate_by(email_address: params[:email_address], password: params[:password])
    reset_session
    session[:user_id] = user.id
    redirect_to diaries_path, notice: "ログインしました"
  else
    flash.now[:alert] = "メールアドレスまたはパスワードが違います"
    render :new, status: :unprocessable_content
  end
end

def destroy
  reset_session
  redirect_to new_session_path, notice: "ログアウトしました"
end
```

- `authenticate_by`：探す＋パスワード照合を1回で行う。合えば user、違えば nil。ユーザーがいないときもハッシュ計算をするので、応答時間の差でも登録の有無が分からない
- `reset_session`：ログイン前の session を引き継がない。ログアウトでも session を丸ごと消す

### 2-4. 確かめる

未登録のアドレスでも、登録済みでパスワード違いでも、**同じメッセージ**（「メールアドレスまたはパスワードが違います」）が出れば OK です。

---

## Step 3 自分の日記だけ：ログインできることと、見てよいことは別

ブランチ：`step-03-start`（切り替え方は 0-2。**`bin/exec bin/rails db:reset` を必ず実行**）

`db:reset` で次の2人と、それぞれの日記が作られます。

| ユーザー | メールアドレス | パスワード | 日記 |
| --- | --- | --- | --- |
| アリス | alice@example.com | password | ID 1「アリスの日記」 |
| ボブ | bob@example.com | password | ID 2「ボブの日記」 |

### 3-1. 読む

| ファイル | 見るところ |
| --- | --- |
| `app/models/user.rb` / `app/models/diary.rb` | `has_many :diaries` / `belongs_to :user`。diaries テーブルに user_id 列 |
| `app/controllers/application_controller.rb` | `before_action :require_login`：未ログインならログイン画面へ |
| `app/controllers/diaries_controller.rb` | 一覧（`index`）は `current_user.diaries`。でも `set_diary` は `Diary.find` のまま |
| `app/views/diaries/_form.html.erb` | `hidden_field :user_id` で持ち主を送っている |

### 3-2. 試す

アリス（`alice@example.com` / `password`）でログインします。

**A：他人の日記を読む**

1. http://localhost:3000/diaries/1 を開く（アリスの日記）
2. URL を `/diaries/2` に書き換える → ボブの日記が読める。編集・削除もできる

**B：他人の名義で書く**

1. 「New diary」で新規作成画面を開く
2. DevTools → Elements で `<input type="hidden" name="diary[user_id]" value="1">` を探し、value を `2` に書き換える
3. タイトルと本文を入れて送信
4. シークレットウィンドウでボブ（`bob@example.com` / `password`）としてログイン → ボブの日記が増えている

一覧に出さないことと、アクセスできないことは別です。ブラウザから来る値（URL・hidden・パラメータ）は全部書き換えられます。

### 3-3. 直す

**① app/controllers/diaries_controller.rb を4か所書き換える**

```ruby
# new
@diary = current_user.diaries.build

# create
@diary = current_user.diaries.build(diary_params)

# set_diary（private の中）
@diary = current_user.diaries.find(params.expect(:id))

# diary_params（private の中）：:user_id を消す
params.expect(diary: [ :title, :body ])
```

**② app/views/diaries/_form.html.erb の hidden_field を消す**

```erb
<%# この行を削除 %>
<%= form.hidden_field :user_id, value: current_user.id %>
```

持ち主は、ブラウザから送られてきた値ではなく、サーバーが知っている `current_user` で決めます。
`set_diary` は show / edit / update / destroy で共通なので、1か所直せば全部に効きます。

発行される SQL はこうなります。他人の日記は見つかりません。

```sql
SELECT * FROM diaries WHERE user_id = 1 AND id = 2
```

### 3-4. 確かめる

1. アリスで `/diaries/2` を開く → `ActiveRecord::RecordNotFound` のエラー画面になれば OK（本番では 404）
2. 新規作成画面で、DevTools から `<input type="hidden" name="diary[user_id]" value="2">` を足して送信 → 作られた日記がアリスのものになっていれば OK

---

## Step 4 パスワードリセット：URL を持っている人を本人とみなす（当日は講師デモ・宿題）

ブランチ：`step-04-start`（切り替え方は 0-2）

送ったメールは http://localhost:3000/letter_opener で見られます。

### 4-1. 読む

| ファイル | 見るところ |
| --- | --- |
| `app/controllers/passwords_controller.rb` | `create` でトークンを `Base64.urlsafe_encode64(user.id.to_s)` で作っている。`update` はそれをデコードして User を探す |
| `app/mailers/passwords_mailer.rb` / `app/views/passwords_mailer/reset.text.erb` | トークン付きの URL をメールで送る |

### 4-2. 試す

1. ログアウトして http://localhost:3000/passwords/new でアリスのアドレスを入れる
2. http://localhost:3000/letter_opener でメールを開く → URL は `/passwords/MQ==/edit`
3. 中身を確かめる

```bash
bin/exec bin/rails runner 'puts Base64.urlsafe_decode64("MQ==")'   # => 1（アリスの ID）
bin/exec bin/rails runner 'puts Base64.urlsafe_encode64("2")'      # => Mg==（ボブの ID）
```

4. http://localhost:3000/passwords/Mg==/edit を開いて新しいパスワードを入れる → ボブのパスワードが変わり、ボブとしてログインできてしまう

Base64 は暗号化ではなく、ただの変換です。鍵がないので、誰でも戻せるし、誰でも作れます。

### 4-3. 直す

**① app/controllers/passwords_controller.rb を書き換える**

```ruby
class PasswordsController < ApplicationController
  skip_before_action :require_login
  before_action :set_user_by_token, only: %i[edit update]

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      PasswordsMailer.reset(user).deliver_later
    end
    redirect_to new_session_path, notice: "登録済みのアドレスであれば、再設定用のメールを送信しました"
  end

  def edit
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      redirect_to new_session_path, notice: "パスワードを変更しました"
    else
      redirect_to edit_password_path(params[:token]), alert: "パスワードが一致しません"
    end
  end

  private

  def set_user_by_token
    @user = User.find_by_password_reset_token!(params[:token])
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to new_password_path, alert: "リンクが無効か、有効期限が切れています"
  end
end
```

**② app/mailers/passwords_mailer.rb：token を受け取らない**

```ruby
class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    mail subject: "パスワードの再設定", to: user.email_address
  end
end
```

**③ app/views/passwords_mailer/reset.text.erb：Rails のトークンを使う**

```erb
以下のリンクからパスワードを再設定してください（15分間有効）。
<%= edit_password_url(@user.password_reset_token) %>
```

`password_reset_token` は、Step 1 で書いた `has_secure_password` の時点で使えるようになっています。

### 4-4. 確かめる

1. アリスでリセットメールを送り、letter_opener で URL を開く。トークンは `eyJfcmFpbHMi…--b58f09…` のような形になる
2. `--` の前は中身（ユーザー ID・有効期限・用途）。デコードすれば読める

```bash
bin/exec bin/rails runner 'puts Base64.decode64("ここに -- の前の部分を貼る")'
```

3. URL のトークンを1文字変えて開く →「リンクが無効か、有効期限が切れています」になれば OK
4. 一度パスワードを変えたあと、同じ URL をもう一度開く → 無効になっていれば OK（パスワードを変えると古いトークンも無効になる）
5. `/passwords/Mg==/edit` を開く → 無効になっていれば OK

---

## Step 5 CSRF：罠ページを開くだけで日記が消える（宿題）

ブランチ：`step-05-start`（体験のために CSRF 対策を外してあります）

### 5-1. 試す

```bash
git stash -u
git checkout step-05-start
bin/restart
bin/exec bin/rails db:reset
docker compose --profile csrf up -d evil
```

1. アリスでログインする
2. 同じブラウザで http://localhost:8000 （罠ページ）を開く
3. アリスの日記（ID 1）が消えている

ブラウザは、別のサイトから送られたリクエストにも cookie を自動で付けます（Step 2 の話）。だから、ログイン中のアリスが罠ページを開いただけで「アリスとして」削除が実行されてしまいます。

### 5-2. 直す

`app/controllers/diaries_controller.rb` の先頭にある次の1行を消します。

```ruby
skip_forgery_protection # Step 5 の体験用。終わったら必ず消す
```

Rails は最初から、フォームに CSRF トークンという合言葉を埋め込んで、送られてきたリクエストが自分のフォームから来たかを確かめています。この1行は、その仕組みを外していました。

### 5-3. 確かめる

`bin/exec bin/rails db:reset` で日記を戻し、もう一度アリスでログインして罠ページを開く → 日記が消えなければ OK。

終わったら罠ページを止めます。

```bash
docker compose --profile csrf stop evil
```

---

## もっとやりたい人へ

| 内容 | やり方 |
| --- | --- |
| 答え合わせ | 別のフォルダで `rails new` したアプリに `bin/rails generate authentication` を実行し、生成されたコードと自分の版を比べる |
| レートリミット | `SessionsController` に `rate_limit to: 10, within: 3.minutes, only: :create` を足して、総当たりを止める |
| 全部の穴が塞がったか確かめる | `git checkout main` → `bin/restart` → `bin/exec bin/rails test`（攻撃のテストが入っています） |
