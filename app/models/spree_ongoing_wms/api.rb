class SpreeOngoingWms::Api
  attr_reader :response, :distributor

  def initialize(distributor)
    @distributor = distributor
    @response = nil
  end

  def get_order(order_id)
    @response = SpreeOngoingWms::Request.new(@distributor).get("/api/v1/orders/#{order_id}")
  end

  def create_or_update_order(data)
    @response = SpreeOngoingWms::Request.new(@distributor).put('/api/v1/orders', data)
  end

  def create_or_update_article(data)
    @response = SpreeOngoingWms::Request.new(@distributor).put('/api/v1/articles', data)
  end
end
