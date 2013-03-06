
$LOAD_PATH << File.dirname(__FILE__) + "/../lib"
require "ws"

if ARGV.size != 1
  $stderr.puts("Usage: ruby samples/stdio_client.rb ws://HOST:PORT/")
  exit(1)
end

client = Net::WS.new(ARGV[0]) { |data| puts data }
puts("Connected")

$stdin.each_line() do |line|
  data = line.chomp()
  client.send(data)
  printf("Sent: %p\n", data)
end
puts "closing connection..."
client.close()
