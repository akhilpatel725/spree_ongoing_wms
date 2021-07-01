require 'base64'
require 'httparty'

class SpreeOngoingWms::Request
  attr_reader :request, :distributor

  def initialize(distributor)
    @distributor = distributor
    @request = nil
  end

  def get(path)
    header = { 'Authorization': authorization_header, 'Accept': 'application/json' }
    @request = HTTParty.get("#{@distributor.warehouse_system_endpoint}#{path}", headers: header)
  end

  def put(path, data)
    @request = HTTParty.put("#{@distributor.warehouse_system_endpoint}#{path}", body: data, headers: headers)
  end

  def post(path, data)
    @request = HTTParty.post("#{@distributor.warehouse_system_endpoint}#{path}", body: data, headers: headers)
  end

  def headers
    { 'Authorization': authorization_header, 'Accept': 'application/json', 'Content-Type': 'application/json' }
  end

  def authorization_header
    'Basic ' + Base64.encode64(@distributor.warehouse_system_username + ':' + @distributor.warehouse_system_password)
  end

  def body
    @request.body
  end

  def success?
    @request.success?
  end

  def response_code
    @request.code
  end
end
