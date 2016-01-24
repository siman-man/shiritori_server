module ShiritoriServer
  class Main
    attr_reader :current_object, :chain_count, :used_method_list, :server

    METHOD_PATTERN = /[\w|\?|\>|\<|\=|\!|\[|\[|\]|\*|\/|\+|\-|\^|\~|\@|\%|\&|]+/.freeze
    DEFAULT_PORT = 46106

    # timelimit is 1 second
    TIME_LIMIT = 1

    def start(port: DEFAULT_PORT)
      begin
        init()
        @server = TCPServer.open(port)
        run
      rescue Exception => ex
        puts ex.message
      ensure
        server&.close
      end
    end

    def update(action: nil, object: nil)
      if action
        @all_method.delete(action)
        @used_method_list[action] = true
        @current_object = object
        @chain_count += 1
      end

      begin
        @current_class = current_object.class
      rescue NoMethodError => ex
        @current_class = 'Undefined'
      end

      @success = true
    end

    def send_message(socket, message)
      $logger.info("send message =>")

      begin
        message['current_class'] = @current_class
        message['current_chain'] = @current_chain.join
        message['chain_count'] = @chain_count
        socket.puts(message.to_json)
      rescue Exception => ex
        puts ex.message
      ensure
        socket.close
      end
    end

    def receive_message(socket)
      $logger.info("receive message =>")

      message = JSON.parse(socket.gets)
      message['command'] = message['command']&.sub(/^\./, '')

      message
    end

    def init(port: DEFAULT_PORT, object: 'Hello Ruby!')
      @all_method = SearchMethod::get_all_methods
      @current_class = Object
      @current_chain = []
      @used_method_list = {}
      @current_object = object
      @chain_count = 0
      @success = false

      # if do before included, #get_all_methods search these Class methods.
      require 'socket'
      require 'timeout'
      require 'json'
      require 'logger'

      $logger = Logger.new(STDOUT)
      $logger.info("init =>")
    end

    def run
      loop do
        $logger.info("Waiting message...")
        socket = server.accept
        message = receive_message(socket)

        begin
          $logger.info("chain: message #{message}")
          result = exec_method_chain(message, current_object)

          action = result[:action]
          object = result[:object]

          if @all_method.include?(action)
            @current_chain << message['command']
            update(action: action, object: object)
          elsif used_method_list[action]
            raise ShiritoriServer::UseSameMethodError
          end
        rescue Exception => ex
          result[:error_message] = ex.message
        end

        send_message(socket, result)
      end
    end

    def exec_method_chain(message, object)
      command = message['command']
      method_name = command.scan(METHOD_PATTERN)&.first&.to_sym
      result = {action: method_name}

      $logger.info("method_name: #{method_name}")

      begin
        Thread.new do
          raise NoMethodError unless object.respond_to?(method_name)

          Timeout.timeout(TIME_LIMIT) do
            result[:object] = eval('object.' + command)
          end
        end.join

        result[:state] = :success
      rescue Exception => ex
        result[:object] = current_object
        result[:error_message] = ex.message
        result[:state] = :failed
      end

      result
    end
  end
end
