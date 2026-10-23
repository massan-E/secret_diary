class PasswordsController < ApplicationController
  skip_before_action :require_login

  def new
  end

  def create
    user = User.find_by(email_address: params[:email_address])
    if user
      token = Base64.urlsafe_encode64(user.id.to_s)
      PasswordsMailer.reset(user, token).deliver_later
      redirect_to new_session_path, notice: "再設定メールを送信しました"
    else
      redirect_to new_password_path, alert: "そのメールアドレスは登録されていません"
    end
  end

  def edit
  end

  def update
    user = User.find(Base64.urlsafe_decode64(params[:token]))
    if user.update(params.permit(:password, :password_confirmation))
      redirect_to new_session_path, notice: "パスワードを変更しました"
    else
      redirect_to edit_password_path(params[:token]), alert: "パスワードが一致しません"
    end
  end
end
