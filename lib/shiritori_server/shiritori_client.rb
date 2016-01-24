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
  puts JSON.parse(result).class
  puts result
ensure
  socket&.close
end

