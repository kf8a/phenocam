require 'amqp'
require 'yaml'

EventMachine.run do 
  camera = '24.13.12.151'
  connection = AMQP.connect(host: camera, user: 'pi', password: 'phenology')

  channel  = AMQP::Channel.new(connection)
  queue    = channel.queue("images", :durable => true)

  queue.subscribe(:ack => true) do |metadata, payload|
    data = YAML.load(payload)
    p data
    at, location, files  = data.keys
    cmd = "rsync --remove-source #{camera}:#{files} #{files}"
    metadata.ack
  end

#  EventMachine.add_timer(30*58) { EventMachine.stop }

  Signal.trap "TERM", Proc.new { connection.close { EventMachine.stop } }

end
