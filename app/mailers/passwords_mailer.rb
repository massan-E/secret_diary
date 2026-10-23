class PasswordsMailer < ApplicationMailer
  def reset(user, token)
    @user = user
    @token = token
    mail subject: "パスワードの再設定", to: user.email_address
  end
end
