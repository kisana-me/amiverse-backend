json.extract! @account,
  :aid,
  :name,
  :name_id,
  :description,
  :birthdate,
  :visibility,
  :created_at

json.icon_url @account.icon_url
