require 'webrick'

server_config = {
  DocumentRoot: './public',
  Port: 8000,
}

server = WEBrick::HTTPServer.new(server_config)
trap("INT"){ server.shutdown }
server.start
