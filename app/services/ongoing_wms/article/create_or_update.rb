module OngoingWms
  module Article
    class CreateOrUpdate < ApplicationService
      attr_reader :distributor, :article

      def initialize(args = {})
        super
        @distributor = args[:distributor]
        @article = args[:article]
      end

      def call
        begin
          create_or_update_article(article_data)
        rescue ServiceError => error
          add_to_errors(error.messages)
        end

        completed_without_errors?
      end

      private

      def create_or_update_article(article_data)
        @response =  if article.external_product_id?
                      SpreeOngoingWms::Api.new(distributor).update_article(article.external_product_id, article_data)
                     else
                      SpreeOngoingWms::Api.new(distributor).create_article(article_data)
                     end
        if @response.success?
          @response = JSON.parse(@response.body, symbolize_names: true)
          store_external_product_id
          puts @response
        else
          raise ServiceError.new([Spree.t(:error, response: @response)])
        end
      end

      def article_data
        {
          goodsOwnerId: distributor.goods_owner_id,
          articleNumber: article.id,
          # articleGroup: {
          #   code: "aliquip",
          #   name: "aliqua laboris commodo"
          # },
          articleCategory: {
            code: article.category&.permalink,
            name: article.category&.name
          },
          # articleColor: {
          #   code: "in labore nostrud Lorem",
          #   name: "nulla"
          # },
          # articleSize: {
          #   code: "aliquip ad labore",
          #   name: "sunt veniam voluptate nisi laboris"
          # },
          articleName: article.name,
          productCode: article.ean,
          unitCode: article.inventory_unit&.code,
          description: article.description,
          # isStockArticle: "<boolean>",
          supplierInfo: {
            # supplierArticleNumber: "<string>",
            supplierNumber: article.vendor&.contact_phone,
            supplierName: article.vendor&.name
          },
          barCodeInfo: {
            barCode: article.sku,
            # barCodePackage: "<string>",
            # barCodePallet: "<string>",
            # alternativeBarCodes: [
            #   {
            #     barCode: "<string>",
            #     quantityPerBarCode: "<decimal>",
            #     barCodeType: {
            #       value: "<Error: Too many levels of nesting to fake this schema>"
            #     }
            #   },
            #   {
            #     barCode: "<string>",
            #     quantityPerBarCode: "<decimal>",
            #     barCodeType: {
            #       value: "<Error: Too many levels of nesting to fake this schema>"
            #     }
            #   }
            # ]
          },
          quantityPerPackage: article.sales_unit_size,
          quantityPerPallet: article.consumer_package_size,
          weight: article.weight.to_f / 1000,
          length: article.depth.to_f / 1000,
          width: article.width.to_f / 1000,
          height: article.height.to_f / 1000,
          # volume: "<decimal>",
          # purchasePrice: "<decimal>",
          # stockValuationPrice: "<decimal>",
          customerPrice: article.price,
          purcaseCurrencyCode: article.cost_currency,
          countryOfOriginCode: article&.vendor&.addresses&.default&.country_iso,
          # statisticsNumber: "<string>",
          # articleNameTranslations: [
          #   {
          #     languageCode: "<string>",
          #     articleName: "<string>"
          #   },
          #   {
          #     languageCode: "<string>",
          #     articleName: "<string>"
          #   }
          # ],
          # stockLimit: "<integer>",
          # minimumReorderQuantity: "<decimal>",
          netWeight: article.weight.to_f / 1000,
          # linkToPicture: "<string>",
          # structureDefinition: {
          #   articleKind: "<string>",
          #   rows: [
          #     {
          #       articleNumber: "<string>",
          #       numberOfItems: "<decimal>"
          #     }
          #   ]
          # }
        }.to_json
      end

      def store_external_product_id
        article.update_columns(external_product_id: @response[:articleSystemId])
      end
    end
  end
end
