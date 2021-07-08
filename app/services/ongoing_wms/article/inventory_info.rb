module OngoingWms
  module Article
    class InventoryInfo < ApplicationService
      attr_reader :article, :vendor
      MAX_ARTICLES_TO_GET = 20

      def initialize(args = {})
        super
        @vendor = args[:vendor]
        @article_numbers = args[:article_numbers]
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
        @article_numbers.each_slice(20) do |numbers|
          response = SpreeOngoingWms::Api.new(@vendor.distributor).get_inventory_info(article_data(numbers))
          if response.success?
            response = JSON.parse(response.body, symbolize_names: true)
            puts response
          else
            raise ServiceError.new([Spree.t(:error, response: response)])
          end
        end
      end

      def article_data(numbers)
        {
          goodsOwnerId: @vendor.distributor.goods_owner_id,
          # articleSystemIdFrom: nil,
          maxArticlesToGet: MAX_ARTICLES_TO_GET,
          articleNumbers: numbers,
          # warehouseIds:nil
        }.to_query
      end
    end
  end
end
