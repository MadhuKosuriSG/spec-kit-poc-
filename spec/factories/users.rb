FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email.downcase }
    password { Faker::Internet.password(min_length: 8) }
  end
end
