FactoryBot.define do
  factory :product do
    sequence(:name) { |n| "Product #{n}" }
    price { rand(10.0..1000.0).round(2) }
  end
end