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
          order_ids_per_distributor.each do |distributor, ids|
            ids.each { |id| update_order_status(distributor, id) }
          end
        rescue ServiceError => error
          add_to_errors(error.messages)
        end

        completed_without_errors?
      end

      private

      def update_order_status(distributor, external_order_id)
        return unless external_order_id

        # Status code for Released = 300
        @response = SpreeOngoingWms::Api.new(distributor).update_order_status(external_order_id, { orderStatusNumber: 300 }.to_json)
        if @response.success?
          @response = JSON.parse(@response.body, symbolize_names: true)
          store_external_order_id
          puts @response
        else
          raise ServiceError.new([Spree.t(:error, response: @response)])
        end
      end

      def order_ids_per_distributor
        return @items_by_distributor if @items_by_distributor.present?

        @items_by_distributor = {}

        order.vendor_line_items(vendor).each do |item|
          item_distributor = item.product&.distributor || item&.product_line&.distributor

          next unless item_distributor&.ongoing_wms? && item.external_order_id

          @items_by_distributor[item_distributor] ||= []
          @items_by_distributor[item_distributor] << item.external_order_id
        end
        @items_by_distributor
      end
    end
  end
end
