module OngoingWms
  class CreateOrUpdateArticle < ApplicationService
    attr_reader :article, :distributor, :goods_owner_id

    def initialize(args = {})
      super
      @distributor = args[:distributor]
      @article = args[:article]
      @goods_owner_id = args[:goods_owner_id]
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
      response = SpreeOngoingWms::Api.new(@distributor).create_or_update_article(article_data)
      if response.success?
        response = JSON.parse(response.body, symbolize_names: true)
        puts response
      else
        raise ServiceError.new([Spree.t(:error, response: response)])
      end
    end

    def article_data
      {
        goodsOwnerId: @goods_owner_id,
        articleNumber: @article.id,
        # articleGroup: {
        #   code: "aliquip",
        #   name: "aliqua laboris commodo"
        # },
        articleCategory: {
          code: @article.category&.permalink,
          name: @article.category&.name
        },
        # articleColor: {
        #   code: "in labore nostrud Lorem",
        #   name: "nulla"
        # },
        # articleSize: {
        #   code: "aliquip ad labore",
        #   name: "sunt veniam voluptate nisi laboris"
        # },
        articleName: @article.name,
        # productCode: "<string>",
        # unitCode: "<string>",
        description: @article.description,
        # isStockArticle: "<boolean>",
        supplierInfo: {
          # supplierArticleNumber: "<string>",
          # supplierNumber: "<string>",
          supplierName: @article.vendor&.name
        },
        barCodeInfo: {
          barCode: @article.sku,
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
        # quantityPerPackage: "<integer>",
        # quantityPerPallet: "<integer>",
        weight: @article.weight,
        # length: "<decimal>",
        width: @article.width,
        height: @article.height,
        # volume: "<decimal>",
        # purchasePrice: "<decimal>",
        # stockValuationPrice: "<decimal>",
        customerPrice: @article.price,
        purcaseCurrencyCode: @article.cost_currency,
        # countryOfOriginCode: "<string>",
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
        netWeight: @article.weight,
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
  end
end
