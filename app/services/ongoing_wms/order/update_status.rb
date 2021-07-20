module OngoingWms
  module Order
    class UpdateStatus < ApplicationService
      attr_reader :order, :vendor

      def initialize(args = {})
        super
        @vendor = args[:vendor]
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
        return unless store_external_order_id

        # Status code for Released = 300
        @response = SpreeOngoingWms::Api.new(vendor.distributor).update_order_status(store_external_order_id, { orderStatusNumber: 300 }.to_json)
        if @response.success?
          @response = JSON.parse(@response.body, symbolize_names: true)
          store_external_order_id
          puts @response
        else
          raise ServiceError.new([Spree.t(:error, response: @response)])
        end
      end

      def store_external_order_id
        @store_external_order_id = order.vendor_line_items(vendor).pluck(:external_order_id).uniq.first
      end
    end
  end
end
