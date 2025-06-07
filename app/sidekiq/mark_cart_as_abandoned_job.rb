class MarkCartAsAbandonedJob
  include Sidekiq::Job

  def perform(*args)
     Cart.to_be_marked_as_abandoned.find_each(&:mark_as_abandoned!)

    Cart.to_be_removed.destroy_all
  end
end
