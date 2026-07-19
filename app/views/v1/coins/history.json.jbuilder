json.status "success"
json.data do
  json.array! @transactions do |tx|
    json.extract! tx, :aid, :amount, :balance_after, :kind, :memo, :created_at
  end
end
