module OngoingWms
  module Article
    class ArticleInfo < ApplicationService
      attr_reader :distributor, :article

      def initialize(args = {})
        super
        @distributor = args[:distributor]
        @article = args[:article]
      end

      def call
        begin
          get_article_info
        rescue ServiceError => error
          add_to_errors(error.messages)
        end

        completed_without_errors?
      end

      private

      def get_article_info
        return unless article.external_product_id

        @response = SpreeOngoingWms::Api.new(distributor).get_article(article.external_product_id)
        if @response.success?
          @response = JSON.parse(@response.body, symbolize_names: true)
          update_product_stock
          puts @response
        else
          raise ServiceError.new([Spree.t(:error, response: response)])
        end
      end

      def update_product_stock
        return if article.vendor&.stock_locations.blank?

        current_qty = article.stock_items.pluck(:count_on_hand).sum
        stock_location = article.vendor.stock_locations.first
        stock_item = article.stock_items.find_or_create_by(stock_location: stock_location)
        stock_movement = stock_location.stock_movements.build(quantity: @response[:inventoryInfo][:sellableNumberOfItems].to_i - current_qty)
        stock_movement.stock_item = stock_location.set_up_stock_item(article.default_variant)
        stock_movement.save
      end
    end
  end
end
