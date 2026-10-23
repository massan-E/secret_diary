class UsersController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to diaries_path, notice: "登録しました"
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def user_params
    params.expect(user: [ :email_address, :password ])
  end
end
