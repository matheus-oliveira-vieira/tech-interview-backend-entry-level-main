require 'rails_helper'

RSpec.describe CartItem, type: :model do
  describe 'Associations' do
    it { should belong_to(:cart) }
    it { should belong_to(:product) }
  end

  describe 'Validations' do
    it { should validate_numericality_of(:quantity).is_greater_than(0) }

    context 'with valid attributes' do
      it 'is valid with quantity greater than 0' do
        cart_item = build(:cart_item)
        expect(cart_item).to be_valid
      end
    end

    context 'with invalid attributes' do
      it 'is invalid with zero quantity' do
        cart_item = build(:cart_item, quantity: 0)
        expect(cart_item).not_to be_valid
        expect(cart_item.errors[:quantity]).to include('must be greater than 0')
      end

      it 'is invalid with negative quantity' do
        cart_item = build(:cart_item, quantity: -1)
        expect(cart_item).not_to be_valid
        expect(cart_item.errors[:quantity]).to include('must be greater than 0')
      end

      it 'is invalid without cart' do
        cart_item = build(:cart_item, cart: nil)
        expect(cart_item).not_to be_valid
        expect(cart_item.errors[:cart]).to include('must exist')
      end

      it 'is invalid without product' do
        cart_item = build(:cart_item, product: nil)
        expect(cart_item).not_to be_valid
        expect(cart_item.errors[:product]).to include('must exist')
      end
    end
  end

  describe '#total_price' do
    let(:product) { create(:product, price: 15.99) }
    let(:cart_item) { create(:cart_item, product: product, quantity: 3) }

    it 'calculates correct total price' do
      expect(cart_item.total_price).to eq(47.97)
    end

    context 'with high quantity' do
      it 'calculates large totals correctly' do
        high_quantity_item = create(:cart_item, :with_high_quantity, product: product)
        expect(high_quantity_item.total_price).to eq(product.price * 10)
      end
    end

    context 'with low quantity' do
      it 'calculates small totals correctly' do
        low_quantity_item = create(:cart_item, :with_low_quantity, product: product)
        expect(low_quantity_item.total_price).to eq(product.price * 1)
      end
    end
  end
end
