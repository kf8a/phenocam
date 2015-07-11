require 'amqp'
require 'yaml'

EventMachine.run do 
  camera = '24.13.12.151'
  connection = AMQP.connect(host: camera, user: 'pi', password: 'phenology')

  channel  = AMQP::Channel.new(connection)
  queue    = channel.queue("images", :durable => true)

  queue.subscribe(:ack => true) do |metadata, payload|
    data = YAML.load(payload)
    at, location, file  = data.keys
    year = at.year
    cmd = "rsync --remove-source #{camera}:#{files} /var/www/phenology/phencoam/#{year}/#{file}"
    metadata.ack if system(cmd) 
    File.unlink("/var/www/phenology/phenocam/#{location}-current.jpg")
    File.symlink("/var/www/phenology/phenocam/#{year}/#{file}", "/var/www/phenology/phenocam/#{location}-current.jpg")
  end

#  EventMachine.add_timer(30*58) { EventMachine.stop }

  Signal.trap "TERM", Proc.new { connection.close { EventMachine.stop } }

end
