json.aid emoji.aid
json.name emoji.name
json.name_id emoji.name_id
json.image_url emoji.image_url if emoji.image.present?

if defined? heavy
  json.description emoji.description
  json.group emoji.group
  json.subgroup emoji.subgroup
end
