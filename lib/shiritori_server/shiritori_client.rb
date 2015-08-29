require 'socket'
require 'json'

while msg = gets
  socket = TCPSocket.open('localhost', 20000)

  data = {
    username: 'siman', 
    command: msg.chomp
  }

  socket.puts(data.to_json)
  puts socket.gets
  socket.close
end

