json.csrf_token form_authenticity_token

json.is_signed_in @current_account.present?
if @current_account
  json.account do
    json.partial! 'v1/accounts/current_account', account: @current_account
  end
end
