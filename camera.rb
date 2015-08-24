require 'solareventcalculator'
require "amqp"
require 'yaml'
#require 'bunny'

def take_picture
  calc = SolarEventCalculator.new(Date.today, BigDecimal.new("42.41015"), BigDecimal.new("-85.368576"))

  plot = 'g1' #ARGV[0]
  rotation = '270' #ARGV[1]
  at = Time.now.strftime("%Y-%m-%dT%H:%M:%S")
  file_path = "images/#{plot}-#{at}.jpg"

  if calc.compute_official_sunrise('America/New_York') < DateTime.now  && DateTime.now < calc.compute_official_sunset('America/New_York')
    cmd = system "raspistill -rot #{rotation} -awb off -awbg 1.4,1.5 -o #{file_path}"
    if cmd
      msg = {at: at, location: plot, file: file_path}
      send_message(msg)
    end
  end
end


def send_message(message)
  EventMachine.run do
    connection = AMQP.connect(:host => '127.0.0.1')
    channel    = AMQP::Channel.new(connection)
    queue    = channel.queue("images2", :durable => true)
    exchange = channel.direct("")

    exchange.publish(message.to_yaml, :routing_key => queue.name, :persistent => true) do
      connection.close { EventMachine.stop }
    end
  end
end

# def send_message_with_bunny(message)
#   conn = Bunny.new
#   channel = conn.create_channel
#   queue = channel.queue("images2", durable: true)
#   queue.publish(message.to_yaml)
#   conn.stop
# end

if __FILE__ == $0
  take_picture
end
