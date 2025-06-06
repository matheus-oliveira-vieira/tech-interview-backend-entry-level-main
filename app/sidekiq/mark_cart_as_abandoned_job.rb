class MarkCartAsAbandonedJob
  include Sidekiq::Job

  def perform(*args)
    Cart.abandoned.where(abandoned: false).find_each do |cart|
      cart.mark_as_abandoned!
    end

    Cart.to_be_removed.destroy_all
  end
end
