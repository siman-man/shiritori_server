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
        setup()
        @server = TCPServer.open(port)
        run
      rescue Exception => ex
        puts ex.message
      ensure
        server&.close
      end
    end

    def init
      @all_method_origin ||= SearchMethod::get_all_methods

      # if before includ, #get_all_methods search these library Class methods.
      require 'socket'
      require 'timeout'
      require 'json'
      require 'logger'

      $logger = Logger.new(STDOUT)
      $logger.info("init =>")
    end

    def setup(object: 'Hello Ruby!', players: nil)
      $logger.info("setup game =>")

      @all_method = @all_method_origin.dup
      @players = players || ['Guest']
      @players = @players.cycle
      @current_player = @players.next

      {
        current_class: @current_class = Object,
        chain_history: @chain_history = [object.instance_of?(String)? object.inspect : object],
        used_method_list: @used_method_list = {},
        object: @current_object = object,
        chain_count: @chain_count = 0,
        current_player: @current_player,
        success: @success = false
      }
    end

    def update(action: nil, object: nil)
      $logger.info("update => action: #{action}, object: #{object}")

      if action
        @all_method.delete(action)
        @used_method_list[action] = true
        @current_object = object
        @current_player = @players.next
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
        message[:current_class] = @current_class
        message[:chain_history] = @chain_history.join('.')
        message[:chain_count] = @chain_count
        message[:current_player] = @current_player

        socket.puts(message.to_json)
        $logger.info("send message => #{message.inspect}")
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

    def run
      loop do
        $logger.info("Waiting message...")
        socket = server.accept
        message = receive_message(socket)
        $logger.info("chain: message #{message}")

        if message["mode"] == 'start'
          result = setup(players: message["players"])
        else
          begin
            begin
              object = Marshal.load(Marshal.dump(current_object))
            rescue Exception => ex
              object = current_object
            end

            result = try_method_chain(message, object)

            raise ShiritoriServer::ShiritoriChainError if result[:state] == :failed

            action = result[:action]

            if @all_method.include?(action)
              object = result[:object]
              @chain_history << message['command']
              update(action: action, object: object)
            elsif used_method_list[action]
              result[:object] = current_object
              raise ShiritoriServer::UseSameMethodError
            end
          rescue ShiritoriServer::UseSameMethodError => ex
            $logger.error(ex)
            result[:object] = current_object
            result[:error_message] = ex.message
            result[:state] = :failed
          rescue Exception => ex
            $logger.error(ex)
            result[:object] = current_object
            result[:state] = :failed
          end
        end

        send_message(socket, result)
      end
    end

    def try_method_chain(message, object)
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
        $logger.error(ex)
        result[:object] = current_object
        result[:error_message] = ex.message
        result[:state] = :failed
      end

      result
    end
  end
end
