require 'amqp'
require 'yaml'


def collect_data(camera)
  connection = AMQP.connect(host: camera, user: 'pi', password: 'phenology')

  channel  = AMQP::Channel.new(connection)
  queue    = channel.queue("images2", :durable => true)

  queue.subscribe(:ack => true) do |metadata, payload|
    data = YAML.load(payload)
    p data
    year = DateTime.parse(data[:at]).year
    file = data[:file]
    local_file = file.gsub(/images\//,"")
    location = data[:location]
    cmd = "rsync --remove-source-files bohms@#{camera}:#{file} /var/www/phenology/phenocam/#{year}/#{local_file}"
    if system(cmd)
      metadata.ack 
    end
    current_file_name = "/var/www/phenology/phenocam/#{location}-current.jpg"
    if File.exists?(current_file_name)
      File.unlink(current_file_name) 
    end
    File.exist?("/var/www/phenology/phenocam/#{year}/#{local_file}")
    File.exist?(current_file_name)
    File.symlink("/var/www/phenology/phenocam/#{year}/#{local_file}", current_file_name)
  end


  Signal.trap "TERM", Proc.new { connection.close { EventMachine.stop } }
end

EventMachine.run do 
  #  sleep 3 * 60
  cameras = ['35.13.12.151', '35.13.15.44']
  cameras.each do |camera|
    collect_data(camera)
  end

  EventMachine.add_timer(5*60) { EventMachine.stop }
end
