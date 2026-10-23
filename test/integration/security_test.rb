require "test_helper"

class SecurityTest < ActionDispatch::IntegrationTest
  setup do
    @alice = User.create!(email_address: "alice@example.com", password: "password")
    @bob = User.create!(email_address: "bob@example.com", password: "password")
    @bobs_diary = @bob.diaries.create!(title: "ボブの日記", body: "秘密")
  end

  def login(user)
    post session_path, params: { email_address: user.email_address, password: "password" }
  end

  test "step1: password is not stored in plain text" do
    assert_not_equal "password", @alice.password_digest
    assert @alice.password_digest.start_with?("$2a$")
  end

  test "step2: same error message for unknown email and wrong password" do
    post session_path, params: { email_address: "nobody@example.com", password: "x" }
    a = flash[:alert]
    post session_path, params: { email_address: "alice@example.com", password: "x" }
    assert_equal a, flash[:alert]
  end

  test "step2: session id changes on login" do
    get new_session_path
    before = cookies["_secret_diary_session"]
    login(@alice)
    assert_not_equal before, cookies["_secret_diary_session"]
  end

  test "step3: login required" do
    get diaries_path
    assert_redirected_to new_session_path
  end

  test "step3: cannot read other's diary" do
    login(@alice)
    get diary_path(@bobs_diary)
    assert_response :not_found
  end

  test "step3: cannot post as other user" do
    login(@alice)
    post diaries_path, params: { diary: { title: "なりすまし", body: "x", user_id: @bob.id } }
    assert_equal @alice, Diary.last.user
  end

  test "step4: reset token works once, then invalid" do
    token = @alice.password_reset_token
    put password_path(token), params: { password: "newpass", password_confirmation: "newpass" }
    assert_redirected_to new_session_path
    put password_path(token), params: { password: "again", password_confirmation: "again" }
    assert_redirected_to new_password_path
  end

  test "step4: tampered token rejected" do
    get edit_password_path("MQ==")
    assert_redirected_to new_password_path
  end

  test "step4: expired token rejected" do
    token = @alice.password_reset_token
    travel 16.minutes
    get edit_password_path(token)
    assert_redirected_to new_password_path
  end

  test "step4: same response for unknown email" do
    post passwords_path, params: { email_address: "nobody@example.com" }
    assert_redirected_to new_session_path
  end

  test "step5: request without CSRF token is rejected" do
    login(@alice)
    diary = @alice.diaries.create!(title: "t", body: "b")
    ActionController::Base.allow_forgery_protection = true
    delete diary_path(diary), headers: { "Origin" => "http://localhost:8000" }
    assert_response :unprocessable_content
    assert Diary.exists?(diary.id)
  ensure
    ActionController::Base.allow_forgery_protection = false
  end
end
