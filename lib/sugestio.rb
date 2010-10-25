require 'oauth'
require 'json'

class Sugestio
  
  class SugestioError < StandardError; end
  class Unauthorized < SugestioError; end
  class NotFound < SugestioError; end
  class ServerError < SugestioError; end
  class BadRequest < SugestioError; end
  class DecodeError < SugestioError; end
  class UnknownError < SugestioError; end

  VERSION = '0.1'
  URL_BASE = 'http://api.sugestio.com'
  USER_AGENT = "sugestio-ruby/#{VERSION}"
  
  def initialize(username, password)
    super
    @username = username
    @password = password
    
    consumer = OAuth::Consumer.new(@username, @password, :site => URL_BASE)
    @access_token = OAuth::AccessToken.new(consumer)
  end

  def add_user(user)
    return api_request("/sites/#{@username}/users.json", :post, user)
  end
  
  def add_item(item)
    return api_request("/sites/#{@username}/items.json", :post, item)
  end
  
  def add_consumption(consumption)
    return api_request("/sites/#{@username}/consumptions.json", :post, consumption)
  end
  
  def get_recommendations(user_id, options)
    return api_request("/sites/#{@username}/users/#{user_id}/recommendations.json", :get, options)
  end
  
  def get_similar_items(item_id, options)
    return api_request("/sites/#{@username}/items/#{item_id}/similar.json", :get, options)
  end
  
  def get_similar_users(user_id, options)
    return api_request("/sites/#{@username}/users/#{user_id}/similar.json", :get, options)
  end

  def get_analytics
    return api_request("/sites/#{@username}/analytics.json", :get)
  end

  protected
  
  def api_request(path, method, data = {})
    headers = {'User-Agent' => USER_AGENT}
    response = nil
    parsed_response = nil
    
    url = URL_BASE + path
    
    case method
    when :get, :delete
      url = "#{url}?#{build_query_string(data)}"
      response = @access_token.request(method, url, headers)
    when :post, :put
      response = @access_token.request(method, url, data, headers)
    end
    
    puts "Response Code: #{response.code}"
    handle_errors(response)
    
    begin
      parsed_response = JSON.parse(response.body)
    rescue JSON::ParserError
      raise DecodeError, "content: <#{response.body}>"
    end
    
    return parsed_response
  end
  
  def handle_errors(response)
    response_description = "(#{response.code}): #{response.message}"
    response_description += " - #{response.body}"  unless response.body.empty?
    
    case response.code.to_i
    when 400
      raise BadRequest, response_description
    when 401
      raise Unauthorized, response_description
    when 404
      raise NotFound, response_description
    when 500
      raise ServerError, response_description
    else
      unless [200, 201, 202].include?(response.code)
        raise UnknownError, response_description
      end
    end
  end
  
  def build_query_string(data)
    data.map do |key, value|
      [key.to_s, URI.escape(value.to_s)].join('=')
    end.join('&')
  end

end
