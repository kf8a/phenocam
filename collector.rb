require 'amqp'
require 'yaml'

EventMachine.run do 
  cameras = ['35.13.12.151']
  camears.each do |camera|
    connection = AMQP.connect(host: camera, user: 'pi', password: 'phenology')

    channel  = AMQP::Channel.new(connection)
    queue    = channel.queue("images2", :durable => true)

    queue.subscribe(:ack => true) do |metadata, payload|
      data = YAML.load(payload)
      at = DateTime.parse(data[:at])
      location =data[:location]
      file = data[:file]
      local_file = file.gsub(/images\/,"")
      year = at.year
      cmd = "rsync --remove-source-files #{camera}:#{file} /var/www/phenology/phenocam/#{year}/#{file}"
      metadata.ack if system(cmd) 
      File.unlink("/var/www/phenology/phenocam/#{location}-current.jpg")
      File.symlink("/var/www/phenology/phenocam/#{year}/#{file}", "/var/www/phenology/phenocam/#{location}-current.jpg")
    end

    #  EventMachine.add_timer(30*58) { EventMachine.stop }

    Signal.trap "TERM", Proc.new { connection.close { EventMachine.stop } }
  end

end
