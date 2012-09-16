#encoding: utf-8
require 'ice_nine'
require 'immutable'
require 'equalizer'

# Library to build rack compatible responses in a functional style
class Response
  include Immutable, Equalizer.new(:status, :headers, :body)

  # Error raised when finalizing responses with undefined components 
  class InvalidResponseError < RuntimeError; end

  # Undefined response component
  Undefined = Class.new.freeze

  # Return status
  #
  # @return [Fixnum]
  #   when status is set
  #
  # @return [Undefined]
  #   otherwise
  #
  # @example
  #
  #   response = Response.new
  #   response.status  # Response::Undefined
  #   response.with_status(200).status # 200
  #
  # @api public
  #
  attr_reader :status

  # Return headers
  #
  # @return [Hash]
  #   when headers are set
  #
  # @return [Undefined]
  #   otherwise
  #
  # @example
  #
  #   response = Response.new
  #   response.headers # Response::Undefined
  #
  #   response = response.with_headers({'Foo' => 'Bar'})
  #   response.headers # { 'Foo' => 'Bar' }
  #
  # @api public
  #
  attr_reader :headers

  # Return body
  #
  # @return [Object]
  #   when body is set
  #
  # @return [Undefined]
  #   otherwise
  #
  # @example
  #
  #   response = Response.new
  #   response.body # Response::Undefined
  #
  #   response = response.with_body('Foo')
  #   response.headers # 'Foo'
  #
  # @api public
  #
  attr_reader :body

  # Return response with new status
  #
  # @param [Fixnum] status
  #   the status for the response
  #
  # @return [Response]
  #   new response object with status set
  #
  # @example
  #
  #   response = Response.new
  #   response = response.with_status(200)
  #   response.status # => 200
  #
  # @api public
  #
  def with_status(status)
    self.class.new(status, headers, body)
  end

  # Return response with new body
  #
  # @param [Object] body
  #   the body for the response
  #
  # @return [Response]
  #   new response with body set
  #
  # @example
  #
  #   response = Response.new
  #   response = response.with_body('Hello')
  #   response.body # => 'Hello'
  #
  # @api public
  #
  def with_body(body)
    self.class.new(status, headers, body)
  end

  # Return response with new headers
  #
  # @param [Hash] headers
  #   the header for the response
  #
  # @return [Response]
  #   new response with headers set
  #
  # @example
  #
  #   response = Response.new
  #   response = response.with_header({'Foo' => 'Bar'})
  #   response.headers # => {'Foo' => 'Bar'}
  #
  # @api public
  #
  def with_headers(headers)
    self.class.new(status, headers, body)
  end

  # Return response with merged headers
  #
  # @param [Hash] headers
  #   the headers to merge
  #
  # @example
  #
  #   response = Response.new(200, {'Foo' => 'Baz', 'John' => 'Doe'})
  #   response = response.merge_header({'Foo' => 'Bar'})
  #   response.headers # => {'Foo' => 'Bar', 'John' => 'Doe'}
  #
  # @api public
  #
  # @return [Response]
  #   returns new response with merged header
  #
  def merge_headers(headers)
    self.class.new(status, self.headers.merge(headers), body)
  end

  # Return rack compatible array after asserting response is valid
  #
  # @return [Array]
  #   rack compatible array
  #
  # @raise InvalidResponseError
  #   raises InvalidResponseError when request containts undefined components
  #
  # @api private
  #
  def finish
    assert_valid
    rack_array
  end

  # Raise error when request containts undefined components
  #
  # @raise InvalidResponseError
  #   raises InvalidResponseError when request containts undefined components
  #
  # @return [self]
  #
  # @api private
  #
  def assert_valid
    if rack_array.any? { |item| item.equal?(Undefined) }
      raise InvalidResponseError, "Not a valid response: #{self.inspect}"
    end
    
    self
  end

  # Return rack compatible array
  #
  # @return [Array]
  #   rack compatible array
  #
  # @example
  #
  #   response = Response.new(200, {'Foo' => 'Bar'}, 'Hello World')
  #   response.rack_array # => [200, {'Foo' => 'Bar'}, 'Hello World']
  #
  # @api public
  #
  def rack_array
    [status, headers, body] 
  end
  memoize :rack_array

  # Build response with a dsl like interface
  #
  # @example
  #
  #   response = Response.build(200) do |response|
  #     response.
  #       with_headers('Foo' => 'Bar').
  #       with_body('Hello')
  #   end
  #
  #   response.status  # => 200
  #   response.headers # => {'Foo' => 'Bar' }
  #   response.body    # => 'Hello'
  #
  # @return [Array]
  #   rack compatible array
  #
  # @api public
  #
  def self.build(*args)
    response = new(*args)
    response = yield response if block_given?
    response.finish
  end

private

  # Initialize obejct
  #
  # @param [Fixnum] status
  #   http status component
  #   
  # @param [Hash] headers
  #   http header component
  #
  # @param [Object] body
  #   http body component
  #
  # @return [undefined]
  #
  # @api private
  #
  def initialize(status=Undefined, headers={}, body=Undefined)
    @status, @headers, @body = status, headers, body 
  end
end

require 'response/redirect'
require 'response/html'
