class String
  def gets
    if rand > 0.98
      self
    else
      nil
    end
  end
end

require 'em-websocket'

require "serialport"

port_str = "/dev/tty.usbmodem1421"
baud_rate = 9600
data_bits = 8
stop_bits = 1
parity = SerialPort::NONE

sp = SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)

EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8080) do |ws|
  ws.onopen    { ws.send "Hello Client!"}
  ws.onclose   { puts "WebSocket closed" }
  pass = true
  ws.onmessage do
    if pass
      ws.send "pass"
      pass = false
    else
      ws.send sp.gets
      pass = true
    end
  end
end
