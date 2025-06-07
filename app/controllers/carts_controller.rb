class CartsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  before_action :set_cart, only: [:show, :create, :update, :destroy]

  def show
    render json: cart_response
  end

  def create
    product = Product.find(params[:product_id])
    cart_item = @cart.cart_items.find_by(product_id: product.id)

    if cart_item
      cart_item.quantity += params[:quantity].to_i
    else
      cart_item = @cart.cart_items.build(product: product, quantity: params[:quantity].to_i)
    end

    if cart_item.save
      @cart.touch
      render json: cart_response, status: :created
    else
      render json: cart_item.errors, status: :unprocessable_entity
    end
  end

  def update
    product = Product.find(params[:product_id])
    cart_item = @cart.cart_items.find_by(product_id: product.id)

    if cart_item
      cart_item.quantity += params[:quantity].to_i
    else
      cart_item = @cart.cart_items.build(product: product, quantity: params[:quantity].to_i)
    end

    if cart_item.save
      @cart.touch
      render json: cart_response
    else
      render json: cart_item.errors, status: :unprocessable_entity
    end
  end

  def destroy
    product = Product.find(params[:product_id])
    cart_item = @cart.cart_items.find_by(product_id: product.id)

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
    @cart = current_cart
  end

  def current_cart
    if session[:cart_id]
      Cart.find_by(id: session[:cart_id]) || create_new_cart
    else
      create_new_cart
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
