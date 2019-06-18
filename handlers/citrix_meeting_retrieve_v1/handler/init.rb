require File.expand_path(File.join(File.dirname(__FILE__), 'dependencies'))

class CitrixMeetingRetrieveV1
  def initialize(input)
    # Set the input document attribute
    @input_document = REXML::Document.new(input)
    
    # Store the info values in a Hash of info names to values.
    @info_values = {}
    REXML::XPath.each(@input_document,"/handler/infos/info") { |item|
      @info_values[item.attributes['name']] = item.text  
    }
    
    # Retrieve all of the handler parameters and store them in a hash attribute
    # named @parameters.
    @parameters = {}
    REXML::XPath.match(@input_document, 'handler/parameters/parameter').each do |node|
      @parameters[node.attribute('name').value] = node.text.to_s
    end
  end
  
  def execute()
    token = direct_login
    
    meeting_id = @parameters['meeting_id']
    
    url = "https://api.citrixonline.com/G2M/rest/meetings/#{meeting_id}"
    
    response = JSON.parse(RestClient.get(url,:content_type=>'application/json',:accept=>'application/json','Authorization'=>token))
    
    # Grab fields of existing user
    keys = response[0].keys
    result_xml = ""
    keys.each do | key |
      value = response[0][key]
      result_xml << "<result name=\"#{key}\">#{value}</result>"
      
      puts "<result name=\"#{key}\"/>"
    end
    <<-RESULTS
    <results>
    #{result_xml}
    </results>
    RESULTS
  end
  
  def direct_login
    client_id = @info_values['client_id']
    email = @info_values['email']
    password = @info_values['password']
    
    url = "https://api.citrixonline.com/oauth/access_token?grant_type=password&user_id=#{email}&password=#{password}&client_id=#{client_id}"
    
    result_json = JSON.parse(RestClient.get(url,:accept=>'application/json',:content_type=>'application/json'))
    
    return result_json['access_token']
  end
  
  # This is a template method that is used to escape results values (returned in
  # execute) that would cause the XML to be invalid.  This method is not
  # necessary if values do not contain character that have special meaning in
  # XML (&, ", <, and >), however it is a good practice to use it for all return
  # variable results in case the value could include one of those characters in
  # the future.  This method can be copied and reused between handlers.
  def escape(string)
    # Globally replace characters based on the ESCAPE_CHARACTERS constant
    string.to_s.gsub(/[&"><]/) { |special| ESCAPE_CHARACTERS[special] } if string
  end
  # This is a ruby constant that is used by the escape method
  ESCAPE_CHARACTERS = {'&'=>'&amp;', '>'=>'&gt;', '<'=>'&lt;', '"' => '&quot;'}
end
