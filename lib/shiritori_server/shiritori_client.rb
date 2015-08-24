require 'socket'
require 'json'

socket = TCPSocket.open('localhost', 20000)

data = {
  username: 'siman', 
  command: "first"
}

socket.puts(data.to_json)
puts socket.gets

socket.close
