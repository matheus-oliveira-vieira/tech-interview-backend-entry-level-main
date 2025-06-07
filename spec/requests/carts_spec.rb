require 'rails_helper'

RSpec.describe 'Carts API', type: :request do
  let(:product) { create(:product, price: 10.0) }

  describe 'GET /cart' do
    it 'returns empty cart when no items' do
      get '/cart'
      expect(response).to have_http_status(:ok)
      expect(json_response[:products]).to be_empty
    end

    it 'returns cart details' do
      post '/cart', params: { product_id: product.id, quantity: 2 }
      get '/cart'
      expect(response).to have_http_status(:ok)
      expect(json_response[:products].first[:id]).to eq(product.id)
      expect(json_response[:products].first[:quantity]).to eq(2)
    end
  end

  describe 'POST /cart' do
    context 'with valid params' do
      it 'adds new product to cart' do
        post '/cart', params: { product_id: product.id, quantity: 2 }
        expect(response).to have_http_status(:created)
        expect(json_response[:total_price]).to eq(20.0)
      end

      it 'updates quantity when product exists in cart' do
        post '/cart', params: { product_id: product.id, quantity: 1 }
        post '/cart', params: { product_id: product.id, quantity: 3 }
        expect(json_response[:products].first[:quantity]).to eq(4)
        expect(json_response[:products].first[:total_price]).to eq(40.0)
      end
    end

    context 'with invalid params' do
      it 'returns error for invalid product' do
        post '/cart', params: { product_id: 999, quantity: 1 }
        expect(response).to have_http_status(:not_found)
      end

      it 'returns error for invalid quantity' do
        post '/cart', params: { product_id: product.id, quantity: 0 }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PUT /cart/add_item' do
    context 'with valid params' do
      it 'updates existing item quantity' do
        post '/cart', params: { product_id: product.id, quantity: 1 }
        put '/cart/add_item', params: { product_id: product.id, quantity: 2 }
        expect(json_response[:products].first[:quantity]).to eq(3)
      end

      it 'adds new item if not exists' do
        put '/cart/add_item', params: { product_id: product.id, quantity: 1 }
        expect(json_response[:products].first[:quantity]).to eq(1)
      end
    end

    context 'with invalid params' do
      it 'returns error for invalid quantity' do
        put '/cart/add_item', params: { product_id: product.id, quantity: -1 }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error for invalid product' do
        put '/cart/add_item', params: { product_id: 999, quantity: 1 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /cart' do
    before do
      post '/cart', params: { product_id: product.id, quantity: 2 }
    end

    it 'removes item from cart' do
      delete "/cart/#{product.id}"
      expect(response).to have_http_status(:ok)
      expect(json_response[:products]).to be_empty
    end

    it 'returns error for non-existent product' do
      delete "/cart/999"
      expect(response).to have_http_status(:not_found)
    end

    it 'updates cart total price' do
      delete "/cart/#{product.id}"
      expect(json_response[:total_price]).to eq(0.0)
    end
  end

  describe 'Session Management' do
    it 'creates new cart when none exists' do
      get '/cart'
      expect(session[:cart_id]).not_to be_nil
      expect(json_response[:id]).to eq(Cart.last.id)
    end

    it 'reuses existing cart' do
      post '/cart', params: { product_id: product.id, quantity: 1 }
      first_cart_id = json_response[:id]
      get '/cart'
      expect(json_response[:id]).to eq(first_cart_id)
    end
  end

  private

  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end
end
