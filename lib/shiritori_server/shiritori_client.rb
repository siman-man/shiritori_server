require 'socket'
require 'json'

begin
  msg = gets
  socket = TCPSocket.open('localhost', 46106)

  data = {
    username: 'siman', 
    command: msg.chomp
  }

  socket.puts(data.to_json)
  result = socket.gets
ensure
  socket&.close
end

