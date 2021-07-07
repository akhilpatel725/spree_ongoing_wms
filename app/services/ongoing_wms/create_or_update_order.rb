module OngoingWms
  class CreateOrUpdateOrder < ApplicationService
    attr_reader :order, :distributor, :goods_owner_id

    def initialize(args = {})
      super
      @distributor = args[:distributor]
      @order = args[:order]
      @goods_owner_id = args[:goods_owner_id]
    end

    def call
      begin
        create_or_update_order(order_data)
      rescue ServiceError => error
        add_to_errors(error.messages)
      end

      completed_without_errors?
    end

    private

    def create_or_update_order(order_data)
      response = SpreeOngoingWms::Api.new(@distributor).create_or_update_order(order_data)
      if response.success?
        response = JSON.parse(response.body, symbolize_names: true)
        puts response
      else
        raise ServiceError.new([Spree.t(:error, response: response)])
      end
    end

    def order_data
      {
        goodsOwnerId: @goods_owner_id,
        orderNumber: @order.number,
        deliveryDate: 2.days.from_now,
        consignee: consignee_detail,
        # referenceNumber: "<string>",
        # goodsOwnerOrderId: "<string>",
        # salesCode: "<string>",
        # orderRemark: "<string>",
        # deliveryInstruction: "<string>",
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
        customerPrice: @order.total
      }.to_json
    end

    def order_lines
      # [
      #   {
      #     rowNumber: "<string>",
      #     articleNumber: "<string>",
      #     numberOfItems: "<decimal>",
      #     comment: "<string>",
      #     shouldBePicked: "<boolean>",
      #     serialNumber: "<string>",
      #     lineTotalCustomsValue: "<decimal>",
      #     batchNumber: "<string>",
      #     lineType: {
      #       code: "labore Lorem",
      #       name: "exercitation aliqua dolore"
      #     }
      #   },
      #   {
      #     rowNumber: "<string>",
      #     articleNumber: "<string>",
      #     numberOfItems: "<decimal>",
      #     comment: "<string>",
      #     shouldBePicked: "<boolean>",
      #     serialNumber: "<string>",
      #     lineTotalCustomsValue: "<decimal>",
      #     batchNumber: "<string>",
      #     lineType: {
      #       code: "eu nostrud ullamco ut",
      #       name: "fugiat deserunt "
      #     }
      #   }
      # ]
      line_items = []
      @order.line_items.each do |item|
        line_item = {}
        line_item[:rowNumber] = item.id
        line_item[:articleNumber] = item.product.id
        line_item[:numberOfItems] = item.quantity
        line_items << line_item
      end
      line_items
    end

    def consignee_detail
      {
        customerNumber: @order.ship_address.phone,
        name: @order.ship_address.first_name + ' ' + @order.ship_address.last_name,
        address1: @order.ship_address.address1,
        address2: @order.ship_address.address2,
        # address3: "<string>",
        postCode: @order.ship_address.zipcode,
        city: @order.ship_address.city,
        countryCode: @order.ship_address.country.iso,
        # countryStateCode: "<string>",
        # remark: "<string>",
        # doorCode: "<string>"
      }
    end
  end
end
