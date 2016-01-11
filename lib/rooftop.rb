require 'her'
require 'faraday-http-cache'
require 'require_all'
require "active_support/all"

module Rooftop

  DEFAULT_API_NAMESPACE = "wp"
  DEFAULT_API_VERSION = 2

  class << self
    #accessor to set whether we're in privew mode
    attr_accessor :preview, :debug_request, :debug_response

    #access the configuration class as Rooftop.configuration
    attr_accessor :configuration

    #block for configuration.
    def configure
      self.configuration ||= Configuration.new
      yield(configuration)
      self.configuration.configure_connection
    end

  end

  class Configuration
    attr_accessor :api_token, :url, :site_name, :perform_caching, :cache_store, :cache_logger, :ssl_options, :proxy, :post_type_mapping, :logger
    attr_reader :connection,
                :connection_path,
                :api_path, #actually writeable with custom setter
                :extra_headers, #actually writeable with custom setter
                :advanced_options, #actually writeable with custom setter
                :user_agent #actually writeable with custom setter

    def initialize
      @extra_headers = {}
      @connection ||= Her::API.new
      @advanced_options = {}
      @api_path = "/wp-json/"
      @user_agent = "Rooftop CMS Ruby client #{Rooftop::VERSION} (http://github.com/rooftopcms/rooftop-ruby)"
      @perform_caching = false
      @cache_store = ActiveSupport::Cache.lookup_store(:memory_store)
      @cache_logger = nil
      @ssl_options = {}
      @proxy = nil
      @post_type_mapping = {}
      @logger = nil
    end

    def api_path=(path)
      @api_path = path || @api_path
    end

    def user_agent=(agent)
      @user_agent = agent || @user_agent
    end

    def extra_headers=(headers)
      @extra_headers = headers || @extra_headers
    end

    def advanced_options=(opts)
      @advanced_options = opts || @advanced_options
    end

    def user_agent=(agent)
      @user_agent = agent || @user_agent
    end

    # Return the Configuration object as a hash, with symbols as keys.
    # @return [Hash]
    def to_hash
      Hash[instance_variables.map { |name| [name.to_s.gsub("@","").to_sym, instance_variable_get(name)] } ]
    end

    def configure_connection
      if @api_token.nil? || @url.nil?
        raise ArgumentError, "You need to configure Rooftop before instantiating a class with a Rooftop mixin"
      end

      @connection_path = "#{@url}#{@api_path}"

      @connection.setup url: @connection_path, ssl: @ssl_options, proxy: @proxy, send_only_modified_attributes: true do |c|
        if @logger
          c.use Rooftop::DebugMiddleware
        end

        #Headers
        c.use Rooftop::Headers

        # Caching
        if @perform_caching
          c.use Faraday::HttpCache, store: @cache_store, serializer: Marshal, logger: @cache_logger
        end

        # Request
        c.use Faraday::Request::UrlEncoded


        # Response
        c.use Her::Middleware::DefaultParseJSON

        # Adapter
        c.use Faraday::Adapter::NetHttp
      end
    end
  end
end

#load everything after this.
require_rel '.'
