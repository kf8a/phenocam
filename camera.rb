require 'solareventcalculator'
require "bunny"

calc = SolarEventCalculator.new(Date.today, BigDecimal.new("42.41015"), BigDecimal.new("-85.368576"))

plot = ARGV[0]
at = Time.now

if calc.compute_official_sunrise('America/New_York') > DateTime.now  && DateTime.now < calc.compute_official_sunset('America/New_York')
  # Start a communication session with RabbitMQ
  conn = Bunny.new
  conn.start

  # open a channel
  ch = conn.create_channel

  # declare a queue
  q  = ch.queue("images")

  cmd = "raspistill -rot 270 -awb off -awbg 1.4,1.5 -o images/#{plot}-#{at}.jpg"
  `cmd`

  msg = {at: now, file: "images/#{plot}-#{at}"} 
  # publish a message to the default exchange which then gets routed to this queue
  q.publish(msg)

  conn.stop
end
