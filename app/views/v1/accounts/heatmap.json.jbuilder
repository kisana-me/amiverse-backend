json.days @days do |day|
  json.date day[:date]
  json.count day[:count]
  json.visited day[:visited]
end
json.max @max
