FactoryBot.define do
  factory :cart_item do
    quantity { rand(1..5) }
    association :cart
    association :product

    trait :with_high_quantity do
      quantity { 10 }
    end

    trait :with_low_quantity do
      quantity { 1 }
    end
  end
end