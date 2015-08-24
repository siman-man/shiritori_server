module ShiritoriServer
  class Main
    attr_reader :current_object, :chain_count, :mode, :used_method_list, :server

    METHOD_PATTERN = /[\w|\?|\>|\<|\=|\!|\[|\[|\]|\*|\/|\+|\-|\^|\~|\@|\%|\&|]+/.freeze

    # timelimit is 1 second
    TIME_LIMIT = 1

    def start(mode: :normal, port: 20000)
      begin
        init(mode: mode)
        @server = TCPServer.open(port)
        run
      rescue Exception => ex
        puts ex.message
      ensure
        server.close
      end
    end

    def update(action: nil, object: nil)
      if action
        @all_method.delete(action)
        @used_method_list << action
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
      begin
        message['current_class'] = @current_class
        message['current_chain'] = @current_chain.join
        message['chain_count'] = @chain_count
        socket.write(message.to_json)
      ensure
        socket.close
      end
    end

    def receive_message(socket)
      message = JSON.parse(socket.gets)
      message['command'] = message['command'].sub(/^\./, '')

      message
    end

    def init(port: 20000, mode: 'normal', object: 'Hello Ruby!')
      @all_method = SearchMethod::get_all_methods
      @current_class = Object
      @current_chain = []
      @used_method_list = []
      @current_object = object
      @chain_count = 0
      @success = false
      @mode = mode

      require 'socket'
      require 'timeout'
      require 'json'
    end

    def run
      loop do
        socket = server.accept
        message = receive_message(socket)

        begin
          result = exec_method_chain(message, current_object)

          action = result[:action]
          object = result[:object]

          if @all_method.include?(action)
            @current_chain << message['command']
            update(action: action, object: object)
          else
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
      method_name = command.scan(METHOD_PATTERN).first.to_sym
      result = {action: method_name}

      begin
        Thread.new do
          raise NoMethodError unless object.respond_to?(method_name)

          timeout(TIME_LIMIT) do
            result[:object] = eval('object.' + command)
          end
        end.join

        result[:state] = :success
      rescue Exception => ex
        result[:error_message] = ex.message
        result[:state] = :failed
      end

      result
    end
  end
end
