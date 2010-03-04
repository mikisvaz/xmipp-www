require 'rubygems'
require 'sinatra'
require 'haml'
require 'simplews'
require 'base64'

WS_url  = "http://localhost:1984" # Change
WS_name = "XMIPPWS"                # Change

RESULTS_DIR = File.join(File.dirname(File.expand_path(__FILE__)), 'public', 'results')

FileUtils.mkdir_p RESULTS_DIR unless File.exists? RESULTS_DIR

$driver = SimpleWS.get_driver(WS_url, WS_name)

get '/' do
  @title ="Home"
  haml :index
end

post '/' do

  name  = params[:name] || ''

  unless params[:file] &&
    (tmpfile = params[:file][:tempfile]) &&
    (filename = params[:file][:filename])

    @error = "No file selected"
    @title = "XMIPP [Error]"
    return haml(:error)
  end

  # Change this information to match you actual web serice
  job = $driver.vol2pseudo(Base64.encode64(tmpfile.read), name)

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

__END__

@@ layout
%html
%head
%title== XMMIP: #{@title}
%body
  = yield

@@ index
%form(action='/'  method='post' enctype='multipart/form-data')
  %h3 Volume file
  %input{:type=>"file",:name=>"file"}
  %h3 Name your job (optional)
  %input(name='name')
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
%head
  %title= @job

%h1== Results for #{@job}

%ul
  - @files.zip(@results).each do |p|
    - file   = p[0]
    - result = p[1]
    %li
      %a{:href => "#{File.join('results',file)}"}= file
