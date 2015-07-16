require 'bunny'
require 'yaml'
require 'json'
require 'open-uri'

def collect_data(camera)
  begin
  connection = Bunny.new(host: camera, user: 'pi', password: 'phenology')
  connection.start
  rescue Bunny::TCPConnectionFailed => e
    p "Connection failure #{camera}"
    connection.close
    return
  end

  channel  = connection.create_channel
  queue    = channel.queue("images2", :durable => true)

  queue.subscribe(ack: true) do |delivery_info, metadata, payload|
    begin
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
    rescue e
        channel.ack
        p e
    end
  end

end



cameras = ['35.13.15.44', '35.13.12.151', '35.13.14.52','35.13.14.47','35.13.12.204','35.13.13.228','35.13.13.164']
cameras.each do |camera|
  ip =  camera
  collect_data(ip)
end

sleep(30*60)
