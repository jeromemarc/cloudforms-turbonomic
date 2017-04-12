#
# Description: Tag Turbonomic Candidates
#

require 'rest-client'
require 'json'
require 'base64'
require 'uri'
require 'nokogiri'

def log(level, message)
  method = '----- Tag Turbonomic Candidates -----'
  $evm.log(level, "#{method} - #{message}")
end

turbonomic_server       = $evm.object['turbonomic_server']
turbonomic_user         = $evm.object['turbonomic_user']
turbonomic_password     = $evm.object.decrypt('turbonomic_password')
groupname               = $evm.object['groupname']
tag_category            = $evm.object['tag_category'] || 'Turbonomic'
tag_name                = $evm.object['tag_name'] || 'Candidate'
uri                     = "https://#{turbonomic_server}/vmturbo/api/groups/#{groupname}/entities"

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

# Validate that turbonomic_tag_category exists in CloudForms
if $evm.execute('category_exists?', tag_category.downcase)
  $evm.log("info", "#{@method} - Category #{tag_category.downcase} exists")
else
  $evm.log("info", "#{@method} - Category #{tag_category.downcase} doesn't exist, creating category")
  $evm.execute('category_create', :name => tag_category.downcase, :single_value => false, :description => tag_category)
end

# Validate that Turbonomic tag exists in CloudForms
if $evm.execute('tag_exists?', tag_category.downcase, tag_name.downcase)
  $evm.log("info", "#{@method} - Tag #{tag_name.downcase} exists in category #{tag_category.downcase}")
else
  $evm.log("info", "#{@method} - Tag #{tag_name.downcase} doesn't exist in category #{tag_category.downcase}, creating tag")
  $evm.execute('tag_create', tag_category.downcase, :name => tag_name.downcase, :description => tag_name)
end

doc = Nokogiri::XML(response.body)
root = doc.root
root.xpath("/TopologyElements/TopologyElement/@displayName").each do |name|
  $evm.log("info", "Turbonomic Candidate --> #{name}")
  
  # Lookup for VM by name
  vm = $evm.vmdb('vm').find_by_name(String.try_convert(name))
  $evm.log("info","#{@method} - VM: #{vm}")
  
  # Tag VM as Turbonomic candidate
  if vm.tagged_with?(tag_category.downcase, tag_name.downcase) 
    $evm.log("info", "#{@method} - VM #{vm} already tagged with Tag #{tag_category.downcase}/#{tag_name.downcase}")
  else
    $evm.log("info", "#{@method} - VM #{vm} not tagged with Tag #{tag_category.downcase}/#{tag_name.downcase}, tag VM")
    vm.tag_assign("#{tag_category.downcase}/#{tag_name.downcase}")
  end
end

exit MIQ_OK
