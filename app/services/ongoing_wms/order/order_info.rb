module OngoingWms
  module Order
    class OrderInfo < ApplicationService
      attr_reader :distributor, :order
      MAX_ARTICLES_TO_GET = 20

      def initialize(args = {})
        super
        @distributor = args[:distributor]
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
        return unless external_order_id

        @response = SpreeOngoingWms::Api.new(distributor).get_order(external_order_id)
        if @response.success?
          @response = JSON.parse(@response.body, symbolize_names: true)
          update_order_status
          puts @response
        else
          raise ServiceError.new([Spree.t(:error, response: response)])
        end
      end

      def external_order_id
        @external_order_id = order_line_items_for_distributor.map(&:external_order_id).uniq.compact.first
      end

      def order_line_items_for_distributor
        order.line_items.for_distributor(distributor)
      end

      def update_order_status
        status = @response[:orderInfo][:orderStatus][:number] rescue nil
        case status
        when 450
          # Status is "sent" in Ongoing WMS == Shipped
          order.shipments.where.not(state: 'shipped').each do |shipment|
            shipment.line_items.select { |item| item.external_order_id == order_id }.each { |item| item.update_columns(shipped: true) }
            shipment.reload
            shipment.ship! unless shipment.line_items.pluck(:shipped).include?(false)
          end
        end
      end
    end
  end
end
