require 'em-websocket'
require 'json'
require "serialport"

port_str = "/dev/tty.usbmodem1411"
baud_rate = 9600
data_bits = 8
stop_bits = 1
parity = SerialPort::NONE

sp = SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)

def message(sp)
  string = sp.gets
  string.chop!

  if string.include?("game_start")
    return { "event" => "game_start" }
  end

  if string.include?("round_start")
    return {
      "event" => "round_start",
      "round" => string.split(" - ").last
    }
  end

  if string.include?("winning_team")
    return {
      "event" => "game_end",
      "winning_team" => string.split(" - ").last
    }
  end

  if string.include?("round_over")
    round = string.split(" - ").last

    # run through and get the 6 players scores (they're in order)
    player1_score = sp.gets.chop.split(" - ").last
    player2_score = sp.gets.chop.split(" - ").last
    player3_score = sp.gets.chop.split(" - ").last
    player4_score = sp.gets.chop.split(" - ").last
    player5_score = sp.gets.chop.split(" - ").last
    player6_score = sp.gets.chop.split(" - ").last

    return {
      "event" => "round_results",
      "round" => round,
      "individual_scores" => [
        { "score" => player1_score },
        { "score" => player2_score },
        { "score" => player3_score },
        { "score" => player4_score },
        { "score" => player5_score },
        { "score" => player6_score }
      ]
    }
  end

  return {"unknown_response" => string}
end

EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8080) do |ws|
  ws.onopen    { ws.send "Hello!"}
  ws.onclose   { puts "WebSocket closed" }
  pass = true
  ws.onmessage do
    if pass
      ws.send "pass"
      pass = false
    else
      ws.send message(sp).to_json
      pass = true
    end
  end
end


###### Expected JSON ######
# {
#     "event": "game_start"
# }
#
# {
#     "event": "round_start",
#     "round": 1
# }
#
# {
#     "event": "round_results",
#     "round": 1,
#     "individual_scores": [
#         // ordered by player number
#         {
#             // "reaction_time": 1.45,
#             // "penalties": 2,
#             "score": 1.85
#         },
#
#         ...
#     ]
# }
#
# {
#     "event": "game_end",
#     "winning_team": 3,
# }
