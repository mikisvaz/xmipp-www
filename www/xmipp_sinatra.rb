require 'rubygems'
require 'sinatra'
require 'haml'
require 'sass'
require 'simplews'
require 'base64'
require 'yaml'
require 'soap/wsdlDriver'
require 'uri'

 

RESULTS_DIR = File.join(File.dirname(File.expand_path(__FILE__)), 'public', 'results')

FileUtils.mkdir_p RESULTS_DIR unless File.exists? RESULTS_DIR

WSDL_FILE = File.join(File.dirname(File.dirname(File.expand_path(__FILE__))), 'webservice', 'wsdl', 'xmippWS.wsdl')
EXAMPLE_FILE = File.join(File.dirname(File.dirname(File.expand_path(__FILE__))), 'test', 'data', 'PolAB_msk4.spi')
$driver = SOAP::WSDLDriverFactory.new(WSDL_FILE).create_rpc_driver

OPTIONS = YAML.load($driver.vol2pseudo_params)

get '/favicon.ico' do
  ""
end

get '/aplication.css' do
  headers 'Content-Type' => 'text/css'
  sass :styles
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
  @options1 = OPTIONS.keys[0..(OPTIONS.length/2)-1]
  @options2 = OPTIONS.keys[(OPTIONS.length/2)..OPTIONS.length]
  haml :index
end

post '/' do
  name  = params[:name]
  options = Hash[*params.select{|key, value| OPTIONS.keys.include? key}.flatten]
  options[:name] = options[:name].gsub(/\s+/,"_") unless options[:name].nil?

  unless params[:file] &&
    (tmpfile = params[:file][:tempfile]) &&
    (filename = params[:file][:filename])

    @error = "No file selected"
    @title = "XMIPP [Error]"
    return haml(:error)
  end

  if name.nil? || name.empty?
    name = File.basename(filename).sub(/\.[^\.]*$/,'')
  else
    name = name.gsub(/\s+/,"_")
  end

  puts options.to_yaml

  # Change this information to match you actual web serice
  job = $driver.vol2pseudo(Base64.encode64(tmpfile.read), options.to_yaml, name)

  redirect "/" + job
end

get '/help' do
  haml :help
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


