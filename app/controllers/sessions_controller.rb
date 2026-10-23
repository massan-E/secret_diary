class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email_address: params[:email_address])
    if user.nil?
      flash.now[:alert] = "そのメールアドレスは登録されていません"
      render :new, status: :unprocessable_content
    elsif user.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to diaries_path, notice: "ログインしました"
    else
      flash.now[:alert] = "パスワードが違います"
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    session.delete(:user_id)
    redirect_to new_session_path, notice: "ログアウトしました"
  end
end
