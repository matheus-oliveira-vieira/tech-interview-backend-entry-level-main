require 'rails_helper'

RSpec.describe MarkCartAsAbandonedJob, type: :job do
  include ActiveSupport::Testing::TimeHelpers

  around do |example|
    freeze_time { example.run }
  end

  describe '#perform' do

    it 'marks eligible carts as abandoned' do
      cart = create(:cart, :to_be_marked_as_abandoned)
      expect {
        described_class.new.perform
      }.to change { cart.reload.abandoned }.from(false).to(true)
    end

    it 'does not mark active carts' do
      cart = create(:cart, :active)
      described_class.new.perform
      expect(cart.abandoned).to be_falsey
    end

    it 'does not mark already abandoned carts' do
      cart = create(:cart, :freshly_abandoned)
      expect {
        described_class.new.perform
      }.not_to change { cart.reload.abandoned }
    end

    it 'removes old abandoned carts' do
      cart = create(:cart, :to_be_removed)
      expect {
        described_class.new.perform
      }.to change { Cart.exists?(cart.id) }.from(true).to(false)
    end

    it 'does not remove recently abandoned carts' do
      cart = create(:cart, :freshly_abandoned)
      described_class.new.perform
      expect(Cart.exists?(cart.id)).to be true
    end
  end

  describe 'scheduling' do
    it 'enqueues the job' do
      Sidekiq::Testing.fake! do
        expect {
          described_class.perform_async
        }.to change { Sidekiq::Queues['default'].size }.by(1)
      end
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
