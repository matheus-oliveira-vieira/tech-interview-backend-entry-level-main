require 'rails_helper'

RSpec.describe Product, type: :model do
  describe 'Validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:price) }
    it { should validate_numericality_of(:price).is_greater_than_or_equal_to(0) }

    context 'with valid attributes' do
      it 'is valid' do
        product = build(:product)
        expect(product).to be_valid
      end
    end

    context 'with invalid attributes' do
      it 'is invalid without name' do
        product = build(:product, name: nil)
        expect(product).not_to be_valid
        expect(product.errors[:name]).to include("can't be blank")
      end

      it 'is invalid without price' do
        product = build(:product, price: nil)
        expect(product).not_to be_valid
        expect(product.errors[:price]).to include("can't be blank")
      end

      it 'is invalid with negative price' do
        product = build(:product, price: -1.99)
        expect(product).not_to be_valid
        expect(product.errors[:price]).to include('must be greater than or equal to 0')
      end

      it 'is invalid with non-numeric price' do
        product = build(:product, price: 'dez reais')
        expect(product).not_to be_valid
        expect(product.errors[:price]).to include('is not a number')
      end
    end
  end

  describe 'Behavior' do
    it 'stores price as decimal' do
      product = create(:product, price: 19.99)
      expect(product.price).to be_a(BigDecimal)
      expect(product.price).to eq(19.99.to_d)
    end

    it 'handles large prices' do
      product = create(:product, price: 999_999.99)
      expect(product).to be_valid
    end

    it 'handles zero price' do
      product = create(:product, price: 0)
      expect(product).to be_valid
    end

    it 'validates price format' do
      product = build(:product, price: '10,99')
      expect(product).not_to be_valid
    end
  end
end
