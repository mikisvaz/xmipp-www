module XMIPP

  BIN_DIR = File.join(ENV['HOME'], 'software', 'opt', 'xmipp', 'bin')

  def self.volume_to_pseudoatom(infile, outfile, options = {})
    options = {"-thr" => 2}.merge(options)
    params  = options.collect {|param, value| "#{param} #{value}" } * " "
    system("#{File.join(BIN_DIR, 'xmipp_convert_vol2pseudo')} #{params} -i #{infile} -o #{outfile}")
  end
end

if __FILE__ == $0
  XMIPP.volume_to_pseudoatom('test/PolAB_msk4.spi', 'tmp/PolAB_msk4')
end
