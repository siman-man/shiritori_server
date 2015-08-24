require 'socket'
require 'json'

server = TCPServer.open(20001)

loop do
  socket = server.accept
  socket.close
end

server.close
