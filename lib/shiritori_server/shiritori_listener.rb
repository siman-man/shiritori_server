require 'socket'
require 'json'

server = TCPServer.open(20001)

loop do
  socket = server.accept

  conn = {
    host: 'localhost',
    port: 20000
  }
  system("/Users/siman/Programming/ruby/shiritori_server/bin/shiritori_server")

  socket.puts(conn.to_json)
  socket.close
end

server.close
