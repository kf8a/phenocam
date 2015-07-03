require 'amqp'
require 'yaml'

EventMachine.run do 
  connection = AMQP.connect(host: '35.13.12.151', user: 'pi', password: 'phenology')

  channel  = AMQP::Channel.new(connection)
  queue    = channel.queue("images", :durable => true)
  exchange = channel.direct("")

  queue.subscribe(:ack => true) do |metadata, payload|
    data = YAML.load(payload)
    p data
    key = data.keys[0]
  end

#  EventMachine.add_timer(30*58) { EventMachine.stop }

  Signal.trap "TERM", Proc.new { connection.close { EventMachine.stop } }

end
