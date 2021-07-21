module OngoingWms
  module Article
    class InventoryInfo < ApplicationService
      attr_reader :vendor

      def initialize(args = {})
        super
        @vendor = args[:vendor]
      end

      def call
        begin
          get_inventory_info
        rescue ServiceError => error
          add_to_errors(error.messages)
        end

        completed_without_errors?
      end

      private

      def get_inventory_info
        vendor.products.each do |product|
          response = SpreeOngoingWms::Api.new(vendor.distributor).get_inventory_info(article_data(product))
          if response.success?
            response = JSON.parse(response.body, symbolize_names: true)
            puts response
          else
            raise ServiceError.new([Spree.t(:error, response: response)])
          end
        end
      end

      def article_data(product)
        {
          goodsOwnerId: vendor.distributor.goods_owner_id,
          articleNumbers: [product.id],
        }.to_query
      end
    end
  end
end
