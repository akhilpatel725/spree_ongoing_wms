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
          order_ids_per_distributor.each do |distributor, ids|
            ids.each { |id| get_order_info(distributor, id) }
          end
        rescue ServiceError => error
          add_to_errors(error.messages)
        end

        completed_without_errors?
      end

      private

      def get_order_info(distributor, order_id)
        return unless order_id

        @response = SpreeOngoingWms::Api.new(distributor).get_order(order_id)
        if @response.success?
          @response = JSON.parse(@response.body, symbolize_names: true)
          update_order_status(order_id)
          puts @response
        else
          raise ServiceError.new([Spree.t(:error, response: response)])
        end
      end

      def order_ids_per_distributor
        return @items_by_distributor if @items_by_distributor.present?

        @items_by_distributor = {}

        vendor_line_items.each do |item|
          item_distributor = item.product&.distributor || item&.product_line&.distributor

          next unless item_distributor&.ongoing_wms? && item.external_order_id

          @items_by_distributor[item_distributor] ||= []
          @items_by_distributor[item_distributor] << item.external_order_id
        end
        @items_by_distributor
      end

      def vendor_line_items
        @vendor_line_items ||= order.vendor_line_items(vendor)
      end

      def vendor_unshipped_shipments
        @vendor_unshipped_shipments ||= order.vendor_shipments(vendor).where.not(state: 'shipped')
      end

      def update_order_status(order_id)
        status = @response[:orderInfo][:orderStatus][:number] rescue nil

        case status
        when 450
          # Status is "sent" in Ongoing WMS == Shipped
          vendor_unshipped_shipments.each do |shipment|
            shipment.line_items.select { |item| item.external_order_id == order_id }.each { |item| item.update_columns(shipped: true) }
            shipment.reload
            shipment.ship! unless shipment.line_items.pluck(:shipped).include?(false)
          end
        end
      end
    end
  end
end
