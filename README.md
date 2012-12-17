HTML5 Web Socket server/client implementation in Ruby.

For server and non-blocking client, em-websocket ( https://github.com/igrigorik/em-websocket ) may be a better choice, especially if you want to use EventMachine.


* How to run sample

- Run sample Web Socket client and type something:
  $ ruby samples/stdio_client.rb ws://localhost:10081
  Ready
  hoge
  Sent: "hoge"
  Received: "hoge"


* Usage example

Client:

  # Connects to Web Socket server at host example.com port 10081.
  client = WebSocket.new("ws://example.com:10081/")
  # Sends a message to the server.
  client.send("Hello")
  # Receives a message from the server.
  data = client.receive()
  puts(data)


* Supported WebSocket protocol versions

WebSocket class (client) speaks version hixie-76.

* License

New BSD License.
