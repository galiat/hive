require 'sinatra'
require 'securerandom'
require 'net/telnet'
require 'byebug'

configure do
  @@host_name =  "pacejo.net"
  @@bad_requests = ["Can't undo", "Parse error", "Illegal move", "Invalid move", "Can't set turn while playing"]
  @@games =  {}
end

before do
  session['token'] ||= SecureRandom.uuid
end

get '/board' do
  current_state
end

get 'move/:move' do # put?
  run_command(params['move'])
end

get '/:command' do # put?
  run_command(params['command'])
end

def current_state
  @@games[session["token"]] || {}
end

def current_state=(state)
  @@games[session["token"]] = state
end

def run_command(command)
  net_session = Net::Telnet::new("Host" => @@host_name)
  net_session.cmd("help")

  setup_board(net_session)

  response = net_session.cmd(command)

  unless @@bad_requests.include?(response)
    save_board(net_session)
    response
    #net_session.close
  else
    response #TODO 400 Bad Request
  end

  save_board(net_session)

  net_session.close
  response
end

def setup_board(net_session)
  unless current_state == {}
    # setup placements
    net_session.cmd "setup"
    current_state[:board].each do |placement|
      net_session.cmd placement
    end

    net_session.cmd "turn #{current_state[:turn]}"
    net_session.cmd "play"
  end
end

def save_board(net_session)
  result = net_session.cmd "board"
  parts = result.split "\n"

  turn = parts.last(3).first.split(" ").last
  placement = parts[0..(parts.length-4)]

  current_state={board: placement, turn:turn}
end