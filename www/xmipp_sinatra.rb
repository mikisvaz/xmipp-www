require 'rubygems'
require 'sinatra'
require 'haml'
require 'simplews'
require 'base64'
require 'yaml'
require 'soap/wsdlDriver'

 

RESULTS_DIR = File.join(File.dirname(File.expand_path(__FILE__)), 'public', 'results')

FileUtils.mkdir_p RESULTS_DIR unless File.exists? RESULTS_DIR

WSDL_FILE = File.join(File.dirname(File.dirname(File.expand_path(__FILE__))), 'webservice', 'wsdl', 'xmippWS.wsdl')
EXAMPLE_FILE = File.join(File.dirname(File.dirname(File.expand_path(__FILE__))), 'test', 'data', 'PolAB_msk4.spi')
$driver = SOAP::WSDLDriverFactory.new(WSDL_FILE).create_rpc_driver

OPTIONS = YAML.load($driver.vol2pseudo_params)

get '/favicon.ico' do
  ""
end

get '/wsdl' do
  send_file(WSDL_FILE, :filename => 'xmippWS.wsdl')
end

get '/example' do
  send_file(EXAMPLE_FILE, :filename => 'PolAB_msk4.spi', :type => 'application/xmipp')
end


get '/documentation' do
  haml :documentation
end

get '/' do
  @title ="Home"
  haml :index
end

post '/' do
  name  = params[:name]
  options = Hash[*params.select{|key, value| OPTIONS.keys.include? key}.flatten]

  unless params[:file] &&
    (tmpfile = params[:file][:tempfile]) &&
    (filename = params[:file][:filename])

    @error = "No file selected"
    @title = "XMIPP [Error]"
    return haml(:error)
  end

  if name.nil? || name.empty?
    name = File.basename(filename).sub(/\.[^\.]*$/,'')
  end

  # Change this information to match you actual web serice
  job = $driver.vol2pseudo(Base64.encode64(tmpfile.read), options.to_yaml, name)

  redirect "/" + job
end

get '/:job' do
  @job   = params[:job]
  @title = @job

  case 
  when $driver.error(@job)
    @error = $driver.messages(@job).last
    @title += " [Error]"
    haml :error

  when ! $driver.done(@job)
    @status   = $driver.status(@job)
    @messages = $driver.messages(@job)
    @title += " [#{@status}]"
    haml :wait

  else
    # Change this part and the results view to present
    # your results.
    @results = $driver.results(@job).collect do |result_id|
      Base64.decode64 $driver.result(result_id)
    end

    @files = %w(pdb approx.hist approx.vol rawDiff.vol relativeDiff.vol).zip(@results).collect do |p|
      name = @job + "." + p[0]
      File.open(File.join(RESULTS_DIR, name), 'w') {|f| f.write p[1] }
      name
    end

    @info = $driver.info(@job)
    @title += " [Done]"
    haml :results
  end

end

get '/Jmol/:file' do
  file   = params[:file]
  @title = "Jmol: #{ file }"

  @file  = File.join('..', 'results', file)
  haml :Jmol
end

__END__

@@ layout
!!!
%html
  %head
    %title== XMMIP: #{@title}
    %script{:src => '/Jmol/Jmol.js', :type => 'text/javascript'}

  %body
    %style
      :sass
        header ul
          :list-style none
    %header
      %ul
        %li
          %a(href='/') [Main]
          %a(href='/documentation') [Web Service Documentation]
    %content
      = yield

@@documentation
%style
  :sass
    table
      th, td
        :border 1px solid
      tr#WS_method_vol2pseudo td.WS_operation, tr#WS_method_vol2pseudo_params td.WS_operation 
        :font-weight bold

%a{ :href =>'/wsdl'} WSDL file
= $driver.documentation

@@ index
%form(action='/'  method='post' enctype='multipart/form-data')
  %h3 
    Volume file
    %a(href='/example') (example)
  %input{:type=>"file",:name=>"file"}
  %h3 Expert parameters
  - OPTIONS.sort_by{|p| p.first}.collect do |p|
    - name, value = p
    %h4= name
    - case
      - when Fixnum === value || Float === value || String === value
        %input{:name => name, :value => value}
      - when FalseClass === value || TrueClass === value
        %input{:name => name, :value => value ? 1 : 0}
      - else

  %h3 Name your job (optional)
  %input(name='name')
  %p
    %input(type='submit')

@@ error
%h1
  == Job #{@job} finished with error status
%p= @error

@@ wait
%head
  %meta{ 'http-equiv' => 'refresh', :content => "5" }
%h1== Status: #{@status}
%ul
  - @messages.each do |msg|
    %li= msg

@@ results
%h1== Results for #{@job}

%ul
  - @files.zip(@results).each do |p|
    - file   = p[0]
    - result = p[1]
    %li
      %a{:href => File.join('results',file)}= file
      - if file =~ /.pdb$/
        %a{:href => File.join('Jmol',file)} (view in Jmol)


@@ Jmol
%h1== Jmol: #{@file}
:javascript
  jmolInitialize("/Jmol");
  jmolApplet(400, 'load #{@file}');
   
    
    

