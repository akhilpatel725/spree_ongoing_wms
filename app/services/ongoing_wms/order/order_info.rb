module OngoingWms
  module Order
    class OrderInfo < ApplicationService
      attr_reader :vendor, :order
      MAX_ARTICLES_TO_GET = 20

      def initialize(args = {})
        super
        @vendor = args[:vendor]
        @order = args[:order]
      end

      def call
        begin
          get_order_info
        rescue ServiceError => error
          add_to_errors(error.messages)
        end

        completed_without_errors?
      end

      private

      def get_order_info
        return unless order_id

        @response = SpreeOngoingWms::Api.new(vendor.distributor).get_order(order_id)
        if @response.success?
          @response = JSON.parse(@response.body, symbolize_names: true)
          update_order_status
          puts @response
        else
          raise ServiceError.new([Spree.t(:error, response: response)])
        end
      end

      def order_id
        @order_id ||= vendor_line_items.first&.external_order_id
      end

      def vendor_line_items
        @vendor_line_items ||= order.vendor_line_items(vendor)
      end

      def vendor_shipments
        @vendor_shipments ||= order.vendor_shipments(vendor)
      end

      def update_order_status
        status = @response[:orderInfo][:orderStatus][:number] rescue nil

        case status
        when 450
          # Status is "sent" in Ongoing WMS == Shipped
          vendor_shipments.each { |shipment| shipment.ship! unless shipment.shipped? }
        end
      end
    end
  end
end
