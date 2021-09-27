module OngoingWms
  module Order
    class CreateOrUpdate < ApplicationService
      attr_reader :order, :distributor

      def initialize(args = {})
        super
        @distributor = args[:distributor]
        @order = args[:order]
      end

      def call
        begin
          data = order_data(order_lines)
          create_or_update_order(data)
        rescue ServiceError => error
          add_to_errors(error.messages)
        end

        completed_without_errors?
      end

      private

      def create_or_update_order(order_lines)
        @response = SpreeOngoingWms::Api.new(distributor).create_or_update_order(order_lines)
        if @response.success?
          @response = JSON.parse(@response.body, symbolize_names: true)
          store_external_order_id
          puts @response
        else
          raise ServiceError.new([Spree.t(:error, response: @response)])
        end
      end

      def order_lines
        order_lines = []
        order_line_items_for_distributor.each do |item|
          line_item = {}
          line_item[:rowNumber] = item.id
          line_item[:articleNumber] = item.product.id
          line_item[:numberOfItems] = item.quantity
          order_lines << line_item
        end
        order_lines
      end

      def order_data(order_lines)
        {
          goodsOwnerId: distributor.goods_owner_id,
          orderNumber: order.number,
          deliveryDate: order.completed_at + 2.days,
          consignee: consignee_detail,
          # referenceNumber: "<string>",
          # goodsOwnerOrderId: "<string>",
          # salesCode: "<string>",
          # orderRemark: "<string>",
          deliveryInstruction: order.special_instructions,
          # servicePointCode: "<string>",
          # freeText1: "<string>",
          # freeText2: "<string>",
          # freeText3: "<string>",
          orderType: {
            code: "sunt elit",
            name: "tempor"
          },
          wayOfDelivery: {
            code: "veniam id officia tempor Ut",
            name: "nulla elit am"
          },
          emailNotification: {
            toBeNotified: false,
            # value: "<string>"
          },
          smsNotification: {
            toBeNotified: false,
            # value: "<string>"
          },
          telephoneNotification: {
            toBeNotified: false,
            # value: "<string>"
          },
          transporter: {
            # transporterCode: "<string>",
            # transporterServiceCode: "<string>"
          },
          returnTransporter: {
            # transporterCode: "<string>",
            # transporterServiceCode: "<string>"
          },
          orderLines: order_lines,
          customsInfo: {
            # customsValueCurrencyCode: "<string>"
          },
          # preparedTransportDocumentId: "<string>",
          # freightPrice: "<decimal>",
          # warehouseId: "<integer>",
          # classes: [
          #   {
          #     code: "<string>",
          #     name: "<string>",
          #     comment: "<string>"
          #   },
          #   {
          #     code: "<string>",
          #     name: "<string>",
          #     comment: "<string>"
          #   }
          # ],
          termsOfDeliveryType: {
            code: "ut en",
            name: "Duis proident velit"
          },
          customerPrice: order.total
        }.to_json
      end

      def consignee_detail
        return {} unless order.ship_address

        {
          customerNumber: order.ship_address.phone,
          name: order.ship_address.first_name + ' ' + order.ship_address.last_name,
          address1: order.ship_address.address1,
          address2: order.ship_address.address2,
          # address3: "<string>",
          postCode: order.ship_address.zipcode,
          city: order.ship_address.city,
          countryCode: order.ship_address.country.iso,
          # countryStateCode: "<string>",
          # remark: "<string>",
          # doorCode: "<string>"
        }
      end

      def order_line_items_for_distributor
        @order_line_items_for_distributor ||= order.line_items.for_distributor(distributor)
      end

      def store_external_order_id
        order_line_items_for_distributor.each do |item|
          item.update_columns(external_order_id: @response[:orderId])
        end
      end
    end
  end
end
