require 'em-websocket'
require 'json'
require "serialport"

port_str = "/dev/tty.usbmodem1411"
baud_rate = 9600
data_bits = 8
stop_bits = 1
parity = SerialPort::NONE

sp = SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)

def to_json(string)
  array = string.split(": ")

  # if player update
  if array.length == 3
    {array[1] => {array[0] => array[2]}}.to_json
  # else, action
  else
    {"action" => string}
  end
end

EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8080) do |ws|
  ws.onopen    { ws.send "Hello Client!"}
  ws.onclose   { puts "WebSocket closed" }
  pass = true
  ws.onmessage do
    if pass
      ws.send "pass"
      pass = false
    else
      ws.send to_json(sp.gets)
      pass = true
    end
  end
end
