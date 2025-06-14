class Cart < ApplicationRecord
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  validates_numericality_of :total_price, greater_than_or_equal_to: 0

  after_touch :update_total_price

  scope :active, -> { where('updated_at >= ?', 3.hours.ago) }
  scope :to_be_marked_as_abandoned, -> {
    where('updated_at < ? AND abandoned = ?', 3.hours.ago, false)
  }
  scope :abandoned, -> { where(abandoned: true) }
  scope :to_be_removed, -> { where('updated_at < ?', 7.days.ago) }

  def update_total_price
    update(total_price: cart_items.sum(&:total_price))
  end

  def mark_as_abandoned!
    update(abandoned: true)
  end

  def self.clean_abandoned_carts
    to_be_marked_as_abandoned.find_each(&:mark_as_abandoned!)
    to_be_removed.destroy_all
  end
end
