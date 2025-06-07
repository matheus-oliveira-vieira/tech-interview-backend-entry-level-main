class CartsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  before_action :set_cart, only: [:show, :create, :update, :destroy]
  before_action :set_product, only: [:create, :update, :destroy]

  def show
    render json: cart_response
  end

  def create
    cart_item = find_or_initialize_cart_item

    save_cart_item(cart_item, :created)
  end

  def update
    cart_item = find_or_initialize_cart_item

    save_cart_item(cart_item)
  end

  def destroy
    cart_item = @cart.cart_items.find_by(product_id: @product.id)

    if cart_item
      cart_item.destroy
      @cart.touch
      render json: cart_response
    else
      render json: { error: 'Product not found in cart' }, status: :not_found
    end
  end

  private

  def set_cart
    @cart = Cart.find_by(id: session[:cart_id]) || create_new_cart
  end

  def set_product
    @product = Product.find(params[:product_id])
  end

  def find_or_initialize_cart_item
    cart_item = @cart.cart_items.find_by(product_id: @product.id)

    if cart_item
      cart_item.quantity += params[:quantity].to_i
    else
      cart_item = @cart.cart_items.build(product: @product, quantity: params[:quantity].to_i)
    end
    cart_item
  end

  def save_cart_item(cart_item, success_status = :ok)
    if cart_item.save
      @cart.touch
      render json: cart_response, status: success_status
    else
      render json: cart_item.errors, status: :unprocessable_entity
    end
  end

  def create_new_cart
    cart = Cart.create(total_price: 0)
    session[:cart_id] = cart.id
    cart
  end

  def cart_response
    {
      id: @cart.id,
      products: @cart.cart_items.includes(:product).map do |item|
        {
          id: item.product.id,
          name: item.product.name,
          quantity: item.quantity,
          unit_price: item.product.price.to_f,
          total_price: item.total_price.to_f
        }
      end,
      total_price: @cart.total_price.to_f
    }
  end

  def record_not_found(exception)
    render json: { error: exception.message }, status: :not_found
  end
end
