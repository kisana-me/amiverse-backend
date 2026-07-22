require "test_helper"

class SignupFlowTest < ActionDispatch::IntegrationTest
  # 既存の accounts fixture は aid を持たず投入に失敗するため使わない
  self.fixture_table_names = []

  # 確認コードの保留も rate_limit のカウンタも Rails.cache に乗るため、テスト毎に消す
  setup do
    Rails.cache.clear
    ENV["CLOUDFLARE_TURNSTILE_SECRET_KEY"] = nil
  end

  test "コードなしでは登録できない" do
    assert_no_difference "Account.count" do
      post "/v1/signup", params: { account: { name: "たろう", name_id: "taro_123", email: "taro@example.com", is_agreed: true }, code: "000000" }, as: :json
    end
    assert_response :unprocessable_entity
  end

  test "同意していないと登録できない" do
    code = SignupCode.issue("taro@example.com")
    assert_no_difference "Account.count" do
      post "/v1/signup", params: { account: { name: "たろう", name_id: "taro_123", email: "taro@example.com", is_agreed: false }, code: code }, as: :json
    end
    assert_response :unprocessable_entity
    assert_equal "利用規約とプライバシーポリシーへの同意が必要です", response.parsed_body["message"]
  end

  test "name_id が不正ならコードは消費されない" do
    code = SignupCode.issue("taro@example.com")
    post "/v1/signup", params: { account: { name: "たろう", name_id: "ng", email: "taro@example.com", is_agreed: true }, code: code }, as: :json
    assert_response :unprocessable_entity

    assert_difference "Account.count", 1 do
      post "/v1/signup", params: { account: { name: "たろう", name_id: "taro_123", email: "taro@example.com", is_agreed: true }, code: code }, as: :json
    end
    assert_response :created
  end

  test "正しいコードで登録され、メール確認済みと同意日時が入る" do
    code = SignupCode.issue("taro@example.com")
    assert_difference "Account.count", 1 do
      post "/v1/signup", params: { account: { name: "たろう", name_id: "taro_123", email: "TARO@example.com", is_agreed: true }, code: code }, as: :json
    end
    assert_response :created

    account = Account.find_by(email: "taro@example.com")
    assert account.email_verified
    assert account.agreed_at.present?
  end

  test "コードは使い捨て" do
    code = SignupCode.issue("taro@example.com")
    post "/v1/signup", params: { account: { name: "たろう", name_id: "taro_123", email: "taro@example.com", is_agreed: true }, code: code }, as: :json
    assert_response :created

    reset!
    assert_no_difference "Account.count" do
      post "/v1/signup", params: { account: { name: "じろう", name_id: "jiro_123", email: "jiro@example.com", is_agreed: true }, code: code }, as: :json
    end
    assert_response :unprocessable_entity
  end

  test "サインイン済みなら登録できない" do
    code = SignupCode.issue("taro@example.com")
    post "/v1/signup", params: { account: { name: "たろう", name_id: "taro_123", email: "taro@example.com", is_agreed: true }, code: code }, as: :json
    assert_response :created

    post "/v1/signup/code", params: { email: "jiro@example.com", turnstile_token: "dummy" }, as: :json
    assert_response :forbidden
  end

  test "シークレット未設定なら Turnstile 検証に失敗してコードを送らない" do
    assert_no_emails do
      post "/v1/signup/code", params: { email: "taro@example.com", turnstile_token: "dummy" }, as: :json
    end
    assert_response :unprocessable_entity
  end

  test "不正なメールアドレスは弾く" do
    post "/v1/signup/code", params: { email: "not-an-email", turnstile_token: "dummy" }, as: :json
    assert_response :unprocessable_entity
    assert_equal "メールアドレスが不正です", response.parsed_body["message"]
  end

  test "連投は throttle される" do
    SignupCode.issue("taro@example.com")
    post "/v1/signup/code", params: { email: "taro@example.com", turnstile_token: "dummy" }, as: :json
    assert_response :too_many_requests
  end

  test "IP単位のバースト制限が効く" do
    6.times do |i|
      post "/v1/signup/code", params: { email: "user#{i}@example.com", turnstile_token: "dummy" }, as: :json
    end
    assert_response :too_many_requests
    # アドレス単位の throttle も 429 なので、バースト制限であることをメッセージで区別する
    assert_match(/集中/, response.parsed_body["message"])
  end

  test "バースト制限は Turnstile 検証より先に効く" do
    5.times { |i| post "/v1/signup/code", params: { email: "user#{i}@example.com" }, as: :json }
    post "/v1/signup/code", params: { email: "last@example.com" }, as: :json
    assert_response :too_many_requests
  end
end
