class SpreeOngoingWms::Api
  attr_reader :response, :distributor

  def initialize(distributor)
    @distributor = distributor
    @response = nil
  end

  def get_order(order_id)
    @response = SpreeOngoingWms::Request.new(@distributor).get("/api/v1/orders/#{order_id}")
  end
end
