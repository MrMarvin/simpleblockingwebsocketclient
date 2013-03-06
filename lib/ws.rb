#
# = net/ws.rb
#
# Copyright (c) 2013-2013 Marvin Frick
#
# Written and maintained by Marvin Frick <marvinfrick@gmx.de>.
#
#
# This program is free software. You can re-distribute and/or
# modify this program under the same terms of ruby itself ---
# Ruby Distribution License or GNU General Public License.
#
# See Net::WS for an overview and examples.
#

require 'net/http'
require "digest/sha1"
require "base64"

class Net::WSError < Net::ProtocolError
  def initialize(msg, res=nil) #:nodoc:
    super msg
    @response = res
  end

  attr_reader :response
end

module Net #:nodoc:
  autoload :OpenSSL, 'openssl'

  class WS < Protocol
    class << self
      attr_accessor(:debug)
    end

    WSVersion = "13"
    WS_MAGIC_STRING = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
    NOISE_CHARS = ("\x21".."\x2f").to_a() + ("\x3a".."\x7e").to_a()
    OPCODE_CONTINUATION = 0x00
    OPCODE_TEXT = 0x01
    OPCODE_BINARY = 0x02
    OPCODE_CLOSE = 0x08
    OPCODE_PING = 0x09
    OPCODE_PONG = 0x0a

    def initialize(arg)
      uri = arg.is_a?(String) ? URI.parse(arg) : arg
      origin = "http://#{uri.host}"
      key = generate_key

      http = HTTP.new(uri.host, uri.port).start
      handshake = http.send_request("GET", uri.path.empty? ? "/" : uri.path, nil, initheader(key, origin))
      if handshake["sec-websocket-accept"] != security_digest(key)
        raise Net::WSError.new("Sec-Websocket-Accept missmatch", handshake)
      end
      @handshaked = true
      @socket = http.instance_variable_get(:@socket).io

      if block_given?
        @rth = Thread.new do
          while data = receive()
            yield data
          end
        end
      end

    end

    def gets(rs = $/)
      line = @socket.gets(rs)
      $stderr.printf("recv> %p\n", line) if Net::WS.debug
      return line
    end

    def read(num_bytes)
      str = @socket.read(num_bytes)
      $stderr.printf("recv> %p\n", str) if Net::WS.debug
      if str && str.bytesize == num_bytes
        return str
      else
        raise(EOFError)
      end
    end

    def receive
      if !@handshaked
        raise Net::WSError.new("call WebSocket\#handshake first")
      end

      begin
        bytes = read(2).unpack("C*")
        fin = (bytes[0] & 0x80) != 0
        opcode = bytes[0] & 0x0f
        mask = (bytes[1] & 0x80) != 0
        plength = bytes[1] & 0x7f
        if plength == 126
          bytes = read(2)
          plength = bytes.unpack("n")[0]
        elsif plength == 127
          bytes = read(8)
          (high, low) = bytes.unpack("NN")
          plength = high * (2 ** 32) + low
        end
        if @server && !mask
          # Masking is required.
          @socket.close()
          raise(WSError, "received unmasked data")
        end
        mask_key = mask ? read(4).unpack("C*") : nil
        payload = read(plength)
        payload = apply_mask(payload, mask_key) if mask
        case opcode
          when OPCODE_TEXT
            return payload
          when OPCODE_BINARY
            raise(WebSocket::Error, "received binary data, which is not supported")
          when OPCODE_CLOSE
            close(1005, "", :peer)
            return nil
          when OPCODE_PING
            raise(WebSocket::Error, "received ping, which is not supported")
          when OPCODE_PONG
          else
            raise(WebSocket::Error, "received unknown opcode: %d" % opcode)
        end
      rescue EOFError
        return nil
      end
    end

    def write(data)
      if WS.debug
        puts data
        data.scan(/\G(.*?(\n|\z))/n) do
          $stderr.printf("send> %p\n", $&) if !$&.empty?
        end
      end
      @socket.write(data)
    end

    def send(data)
      if !@handshaked
        raise Net::WSError.new("call WebSocket\#handshake first")
      else
        send_frame(OPCODE_TEXT, data, false)
      end
    end

    def send_frame(opcode, payload, mask)
      buffer = StringIO.new()
      buffer.set_encoding("UTF-8")
      write_byte(buffer, 0x80 | opcode)
      masked_byte = mask ? 0x80 : 0x00
      if payload.bytesize <= 125
        write_byte(buffer, masked_byte | payload.bytesize)
      elsif payload.bytesize < 2 ** 16
        write_byte(buffer, masked_byte | 126)
        buffer.write([payload.bytesize].pack("n"))
      else
        write_byte(buffer, masked_byte | 127)
        buffer.write([payload.bytesize / (2 ** 32), payload.bytesize % (2 ** 32)].pack("NN"))
      end
      if mask
        mask_key = Array.new(4) { rand(256) }
        buffer.write(mask_key.pack("C*"))
        payload = apply_mask(payload, mask_key)
      end
      buffer.write(payload)
      write(buffer.string)
    end

    def write_byte(buffer, byte)
      buffer.write([byte].pack("C"))
    end

    def initheader(key, origin)
      {
          "Upgrade" => "websocket",
          "Connection" => "Upgrade",
          "Sec-WebSocket-Key" => "#{key}",
          "Sec-WebSocket-Version" => WSVersion,
          "Origin" => "#{origin}"
      }
    end

    def generate_key
      spaces = 1 + rand(12)
      max = 0xffffffff / spaces
      number = rand(max + 1)
      key = (number * spaces).to_s()
      (1 + rand(12)).times() do
        char = NOISE_CHARS[rand(NOISE_CHARS.size)]
        pos = rand(key.size + 1)
        key[pos...pos] = char
      end
      spaces.times() do
        pos = 1 + rand(key.size - 1)
        key[pos...pos] = " "
      end
      Base64.encode64(key).chop
    end

    def security_digest(key)
      Base64.encode64(Digest::SHA1.digest(key + WS_MAGIC_STRING)).gsub(/\n/, "")
    end

  end

end
