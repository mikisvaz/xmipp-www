require 'rbbt/util/tmpfile'
require 'lib/xmipp'
require 'base64'

task :vol2pseudo, %w(vol), { :vol => :binary }, 
  [
    'result/{JOB}.pdb',
    'result/{JOB}_approximation.hist',
    'result/{JOB}_approximation.vol',
    'result/{JOB}_rawDiff.vol',
    'result/{JOB}_relativeDiff.vol',
  ] do |vol|
  FileUtils.mkdir_p File.join(workdir, 'result') unless File.exists? File.join(workdir, 'result')
  step :processing, "Processing volume file"
  TmpFile.with_file(Base64.decode64(vol)) do |file|
    XMIPP.volume_to_pseudoatom(file, File.join(workdir, 'result', job_name))
  end
end

