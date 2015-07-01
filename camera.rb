require 'solareventcalculator'
require "amqp"
require 'json'

def take_picture
  calc = SolarEventCalculator.new(Date.today, BigDecimal.new("42.41015"), BigDecimal.new("-85.368576"))

  plot = 'g2' #ARGV[0]
  rotation = '0' #ARGV[1]
  at = Time.now
  file_path = "images/#{plot}-#{at.strftime('%Y-%m-%dT%H-%M-%S')}.jpg"

  if calc.compute_official_sunrise('America/New_York') < DateTime.now  && DateTime.now < calc.compute_official_sunset('America/New_York')
    cmd = system "raspistill -rot #{rotation} -awb off -awbg 1.4,1.5 -o #{file_path}"
    if cmd
      msg = {at: at, location: plot, file: "images/#{plot}-#{at}"}
      send_message(msg)
    end
  end
end


def send_message(message)
  EventMachine.run do
    connection = AMQP.connect(:host => '127.0.0.1')
    channel    = AMQP::Channel.new(connection)
    queue    = channel.queue("images", :durable => true)
    exchange = channel.direct("")

    exchange.publish(message.to_yaml, :routing_key => queue.name, :persistent => true) do
      connection.close { EventMachine.stop }
    end
  end
end
if __FILE__ == $0
  take_picture
end
