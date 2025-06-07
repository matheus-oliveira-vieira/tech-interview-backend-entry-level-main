require 'rails_helper'

RSpec.describe Cart, type: :model do
  describe 'Associations' do
    it { should have_many(:cart_items).dependent(:destroy) }
    it { should have_many(:products).through(:cart_items) }
  end

  describe 'Validations' do
    it { should validate_numericality_of(:total_price).is_greater_than_or_equal_to(0) }
  end

  describe 'Callbacks' do
    let(:cart) { create(:cart) }

    it 'updates total_price after touch' do
      product = create(:product, price: 10.0)
      create(:cart_item, cart: cart, product: product, quantity: 2)

      expect { cart.touch }.to change { cart.reload.total_price }.from(0).to(20.0)
    end
  end

  describe 'Scopes' do
    let!(:active_cart) { create(:cart, :active) }
    let!(:to_be_marked_cart) { create(:cart, :to_be_marked_as_abandoned) }
    let!(:freshly_abandoned_cart) { create(:cart, :freshly_abandoned) }
    let!(:to_be_removed_cart) { create(:cart, :to_be_removed) }

    describe '.active' do
      it 'returns carts updated within 3 hours' do
        expect(Cart.active).to include(active_cart)
        expect(Cart.active).not_to include(to_be_marked_cart, freshly_abandoned_cart, to_be_removed_cart)
      end
    end

    describe '.to_be_marked_as_abandoned' do
      it 'returns carts not updated for more than 3 hours and not marked' do
        results = Cart.to_be_marked_as_abandoned
        expect(results).to include(to_be_marked_cart)
        expect(results).not_to include(active_cart, freshly_abandoned_cart, to_be_removed_cart)
      end
    end

    describe '.abandoned' do
      it 'returns all marked carts' do
        results = Cart.abandoned
        expect(results).to include(freshly_abandoned_cart, to_be_removed_cart)
        expect(results).not_to include(active_cart, to_be_marked_cart)
      end
    end

    describe '.to_be_removed' do
      it 'returns abandoned carts older than 7 days' do
        results = Cart.to_be_removed
        expect(results).to include(to_be_removed_cart)
        expect(results).not_to include(active_cart, to_be_marked_cart, freshly_abandoned_cart)
      end
    end
  end

  describe '#update_total_price' do
    let(:cart) { create(:cart, :with_items, items_count: 2) }

    it 'calculates sum of all cart items totals' do
      total = cart.cart_items.sum(&:total_price)
      expect(cart.update_total_price).to be_truthy
      expect(cart.total_price).to eq(total)
    end
  end

  describe '#mark_as_abandoned!' do
    let(:cart) { create(:cart) }

    it 'marks cart as abandoned' do
      expect { cart.mark_as_abandoned! }
        .to change { cart.abandoned }.from(false).to(true)
    end
  end

  describe '.clean_abandoned_carts' do
    let!(:to_be_marked_cart) { create(:cart, :to_be_marked_as_abandoned) }
    let!(:to_be_removed_cart) { create(:cart, :to_be_removed) }

    it 'marks eligible carts and removes old ones' do
      expect { Cart.clean_abandoned_carts }
        .to change { Cart.count }.by(-1)
        .and change { to_be_marked_cart.reload.abandoned }.from(false).to(true)

      expect(Cart.exists?(to_be_removed_cart.id)).to be false
      expect(Cart.exists?(to_be_marked_cart.id)).to be true
    end
  end

  describe 'with_items trait' do
    it 'creates a cart with items and correct total' do
      cart = nil
      expect {
        cart = create(:cart, :with_items, items_count: 2)
      }.to change { CartItem.count }.by(2)

      expect(cart.total_price).to eq(cart.cart_items.sum(&:total_price))
      expect(cart.total_price).to be > 0
    end
  end

  describe 'Edge cases' do
    describe 'just before abandonment' do
      let!(:borderline_cart) { create(:cart, :just_before_abandonment) }

      it 'is not included in to_be_marked_as_abandoned' do
        results = Cart.to_be_marked_as_abandoned
        expect(results).not_to include(borderline_cart)
      end
    end

    describe 'just before removal' do
      let!(:borderline_cart) { create(:cart, :just_before_removal) }

      it 'is not included in to_be_removed' do
        expect(borderline_cart.updated_at).to be > 7.days.ago
        expect(Cart.to_be_removed).not_to include(borderline_cart)
      end
    end
  end

  describe 'State transitions' do
    let(:cart) { create(:cart, :active) }

    it 'transitions correctly through abandonment process' do
      cart.update!(updated_at: 4.hours.ago)
      expect {
        Cart.clean_abandoned_carts
      }.to change { cart.reload.abandoned }.from(false).to(true)

      cart.update!(updated_at: 8.days.ago)
      expect {
        Cart.clean_abandoned_carts
      }.to change { Cart.count }.by(-1)
    end
  end
end
