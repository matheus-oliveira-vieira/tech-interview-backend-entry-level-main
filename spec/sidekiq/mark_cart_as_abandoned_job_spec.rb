require 'rails_helper'

RSpec.describe MarkCartAsAbandonedJob, type: :job do
  include ActiveSupport::Testing::TimeHelpers

  describe '#perform' do
    let!(:active_cart) { create(:cart, :active) }
    let!(:to_be_marked_cart) { create(:cart, :to_be_marked_as_abandoned) }
    let!(:freshly_abandoned_cart) { create(:cart, :freshly_abandoned) }
    let!(:to_be_removed_cart) { create(:cart, :to_be_removed) }

    it 'marks eligible carts as abandoned' do
      expect {
        described_class.new.perform
      }.to change { to_be_marked_cart.reload.abandoned }.from(false).to(true)
    end

    it 'does not mark active carts' do
      described_class.new.perform
      expect(active_cart.reload.abandoned).to be_falsey
    end

    it 'does not mark already abandoned carts' do
      expect {
        described_class.new.perform
      }.not_to change { freshly_abandoned_cart.reload.abandoned }
    end

    it 'removes old abandoned carts' do
      expect {
        described_class.new.perform
      }.to change { Cart.exists?(to_be_removed_cart.id) }.from(true).to(false)
    end

    it 'does not remove recently abandoned carts' do
      described_class.new.perform
      expect(Cart.exists?(freshly_abandoned_cart.id)).to be true
    end
  end

  describe 'scheduling' do
    before { Sidekiq::Worker.clear_all }
    it 'enqueues the job' do
      expect {
        described_class.perform_async
      }.to change { Sidekiq::Queues['default'].size }.by(1)
    end

    it 'runs successfully when enqueued' do
      Sidekiq::Testing.inline! do
        create(:cart, :to_be_marked_as_abandoned)
        expect {
          described_class.perform_async
        }.to change { Cart.abandoned.count }.by(1)
      end
    end
  end
end
