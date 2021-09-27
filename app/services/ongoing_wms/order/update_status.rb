module OngoingWms
  module Order
    class UpdateStatus < ApplicationService
      attr_reader :order, :distributor

      def initialize(args = {})
        super
        @distributor = args[:distributor]
        @order = args[:order]
      end

      def call
        begin
          update_order_status
        rescue ServiceError => error
          add_to_errors(error.messages)
        end

        completed_without_errors?
      end

      private

      def update_order_status
        return unless external_order_id

        # Status code for Released = 300
        @response = SpreeOngoingWms::Api.new(distributor).update_order_status(external_order_id, { orderStatusNumber: 300 }.to_json)
        if @response.success?
          @response = JSON.parse(@response.body, symbolize_names: true)
          puts @response
        else
          raise ServiceError.new([Spree.t(:error, response: @response)])
        end
      end

      def external_order_id
        @external_order_id = order_line_items_for_distributor.map(&:external_order_id).uniq.compact.first
      end

      def order_line_items_for_distributor
        order.line_items.for_distributor(distributor)
      end
    end
  end
end
