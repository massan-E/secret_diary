class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    mail subject: "パスワードの再設定", to: user.email_address
  end
end
