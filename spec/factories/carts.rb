FactoryBot.define do
  factory :cart do
    total_price { 0 }

    trait :active do
      updated_at { 2.hours.ago }
    end

    trait :to_be_marked_as_abandoned do
      updated_at { 4.hours.ago }
      abandoned { false }
    end

    trait :freshly_abandoned do
      updated_at { 4.hours.ago }
      abandoned { true }
    end

    trait :to_be_removed do
      updated_at { 8.days.ago }
      abandoned { true }
    end

    trait :with_items do
      transient do
        items_count { 3 }
      end

      after(:create) do |cart, evaluator|
        create_list(:cart_item, evaluator.items_count, cart: cart)
        cart.update_total_price
      end
    end

    trait :just_before_abandonment do
      updated_at { 3.hours.ago + 1.minute }
      abandoned { false }
    end

    trait :just_before_removal do
      updated_at { 7.days.ago + 1.hour }
      abandoned { true }
    end
  end
end