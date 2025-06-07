require 'rails_helper'

RSpec.describe CartsController, type: :controller do
  let(:product) { create(:product, price: 10.0) }
  let(:cart) { create(:cart) }

  before { session[:cart_id] = cart.id }

  describe 'GET #show' do
    let!(:cart_item) { create(:cart_item, cart: cart, product: product) }

    it 'returns cart details' do
      get :show
      expect(response).to have_http_status(:ok)
      expect(json_response[:id]).to eq(cart.id)
      expect(json_response[:products].first[:id]).to eq(product.id)
    end

    it 'returns empty cart when no items' do
      cart_item.destroy
      get :show
      expect(json_response[:products]).to be_empty
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'adds new product to cart' do
        post :create, params: { product_id: product.id, quantity: 2 }
        expect(response).to have_http_status(:created)
        expect(cart.reload.cart_items.count).to eq(1)
        expect(json_response[:total_price]).to eq(20.0)
      end

      it 'updates quantity when product exists in cart' do
        create(:cart_item, cart: cart, product: product, quantity: 1)
        post :create, params: { product_id: product.id, quantity: 3 }
        expect(json_response[:products].first[:quantity]).to eq(4)
        expect(json_response[:products].first[:total_price]).to eq(40.0)
      end
    end

    context 'with invalid params' do
      it 'returns error for invalid product' do
        post :create, params: { product_id: 999, quantity: 1 }
        expect(response).to have_http_status(:not_found)
      end

      it 'returns error for invalid quantity' do
        post :create, params: { product_id: product.id, quantity: 0 }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      it 'updates existing item quantity' do
        create(:cart_item, cart: cart, product: product, quantity: 1)
        put :update, params: { product_id: product.id, quantity: 2 }
        expect(json_response[:products].first[:quantity]).to eq(3)
      end

      it 'adds new item if not exists' do
        put :update, params: { product_id: product.id, quantity: 1 }
        expect(json_response[:products].first[:quantity]).to eq(1)
      end
    end

    context 'with invalid params' do
      it 'returns error for invalid quantity' do
        put :update, params: { product_id: product.id, quantity: -1 }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error for invalid product' do
        put :update, params: { product_id: 999, quantity: 1 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:cart_item) { create(:cart_item, cart: cart, product: product) }

    it 'removes item from cart' do
      delete :destroy, params: { product_id: product.id }
      expect(response).to have_http_status(:ok)
      expect(cart.reload.cart_items.count).to eq(0)
    end

    it 'returns error for non-existent product' do
      delete :destroy, params: { product_id: 999 }
      expect(response).to have_http_status(:not_found)
    end

    it 'updates cart total price' do
      delete :destroy, params: { product_id: product.id }
      expect(json_response[:total_price]).to eq(0.0)
    end
  end

  describe 'Session Management' do
    it 'creates new cart when none exists' do
      session[:cart_id] = nil
      get :show
      expect(session[:cart_id]).not_to be_nil
      expect(json_response[:id]).to eq(Cart.last.id)
    end

    it 'reuses existing cart' do
      get :show
      expect(json_response[:id]).to eq(cart.id)
    end
  end

  private

  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end
end
