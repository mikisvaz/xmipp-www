require 'rbbt/util/tmpfile'
require 'lib/xmipp'
require 'base64'
require 'yaml'

desc "Transform a volume into a pseudo-pdb file"
param_desc :vol => "Contents of volume file encoded in Base64",
           :options => "Hash of options for xmipp_convert_vol2pseudo in YAML format. Binary options (eg. -dontAllowMovement) can be activated by assigning true."
task :vol2pseudo, %w(vol options), { :vol => :binary, :options => :string }, 
  [
    'result/{JOB}.pdb',
    'result/{JOB}_approximation.hist',
    'result/{JOB}_approximation.vol',
    'result/{JOB}_rawDiff.vol',
    'result/{JOB}_relativeDiff.vol',
  ] do |vol, options|
  FileUtils.mkdir_p File.join(workdir, 'result') unless File.exists? File.join(workdir, 'result')
  step :processing, "Processing volume file"
  TmpFile.with_file(Base64.decode64(vol)) do |file|
    XMIPP.volume_to_pseudoatom(file, File.join(workdir, 'result', job_name), YAML.load(options))
  end
end

desc "List options and default values for the vol2pseudo operation"
param_desc :return => "Hash of parameters and types in YAML format"
serve :vol2pseudo_params, [], :return => :string do
  XMIPP::DEFAULT_OPTIONS.to_yaml
end
