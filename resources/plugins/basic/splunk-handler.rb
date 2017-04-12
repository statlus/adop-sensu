#!/opt/sensu/embedded/bin/ruby

require 'net/http'
require 'uri'
require 'rubygems'
require 'json'
require 'openssl'

# Read the JSON event data from STDIN.
event = JSON.parse(STDIN.read, :symbolize_names => true)

status = case event[:check][:status]
  when 0
    "ok"
  when 1
    "warning"
  when 2
    "critical"
  else
    "unknown"
end

client = "MISSING_TAGS"
environment = event[:client][:name]

if event[:client].key?("tags".to_sym)
  environment = event[:client][:tags].key?("environment".to_sym) ? event[:client][:tags][:environment] : environment
  client = event[:client][:tags].key?("client".to_sym) ? event[:client][:tags][:client] : "MISSING_CLIENT"
end

if event[:check].key?("tags".to_sym)
  environment = event[:check][:tags].key?("environment".to_sym) ? event[:check][:tags][:environment] : environment
  client = event[:check][:tags].key?("client".to_sym) ? event[:check][:tags][:client] : client
end

payload= {
  "event" => {
    "type" => "check",
    "check_name" => event[:check][:name] ,
    "client" => client ,
    "environment" => environment,
    "status" => status,
    "monitoring_service" => "sensu"
  },
  "time" => event[:timestamp]
}


splunk_uri =  uri =  URI.parse(ENV['SPLUNK_URL'])
header = {'Authorization' => 'Splunk '+ENV['SPLUNK_KEY']}

http = Net::HTTP.new(uri.host, uri.port)

#http.set_debug_output($stdout)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE
request = Net::HTTP::Post.new(uri.request_uri, header)
request.body = payload.to_json

http.request(request)