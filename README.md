# HTML5 WebSocket client implementation in Ruby.

__For server and non-blocking client, em-websocket ( https://github.com/igrigorik/em-websocket ) may be a better choice, especially if you want to use EventMachine.__

## Usage

  Connects to Web Socket server at host example.com port 10081.
  `client = Net::WS.new("ws://example.com:10081/") { |msg| puts message}`
  The block specifies what should be done with received messages. In this case they are simply printed to stdout.

  For sending data, use send():
  `client.send("Hello")`
  
  See the samples/ directory for actual example code.

## Supported WebSocket protocol versions

WebSocket client speaks version 13 (RFC 6455).

## License

New BSD License.
