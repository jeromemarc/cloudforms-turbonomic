#
# Description: Get Turbonomic Group by Name
#

require 'rest-client'
require 'json'
require 'base64'
require 'uri'
require 'nokogiri'

def log(level, message)
  method = '----- Get Turbonomic Group by Name -----'
  $evm.log(level, "#{method} - #{message}")
end

turbonomic_server   = $evm.object['turbonomic_server']
turbonomic_user     = $evm.object['turbonomic_user']
turbonomic_password = $evm.object.decrypt('turbonomic_password')
groupname           = $evm.object['groupname']
uri                 = "https://#{turbonomic_server}/vmturbo/api/groups/#{groupname}"

headers = {
  :content_type  => 'application/json',
  :accept        => 'application/json',
  :authorization => "Basic #{Base64.strict_encode64("#{turbonomic_user}:#{turbonomic_password}")}"
}

encored_uri = URI.encode(uri)
log(:info, "uri => #{encored_uri}")

request = RestClient::Request.new(
  :method     => :get,
  :url        => encored_uri,
  :headers    => headers,
  :verify_ssl => false
)
response = request.execute
log(:debug, "Return code: <#{response.code}>")
log(:debug, "Response: #{response.body}")

doc = Nokogiri::XML(response.body)
root = doc.root
group = root.xpath("/TopologyElements/TopologyElement/@name")
$evm.log("info", "Group --> #{group}")
