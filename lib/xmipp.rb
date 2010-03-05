module XMIPP

  BIN_DIR = File.join(ENV['HOME'], 'software', 'opt', 'xmipp', 'bin')

  DEFAULT_OPTIONS = {
    "sigma" =>1.5,
    "initialSeeds" =>300,
    "growSeeds" =>30,
    "stop" =>0.001,
    "targetError" =>0.02,
    "dontAllowMovement" => false,
    "dontAllowIntensity" => false,
    "intensityColumn" => "occupancy",
    "minDistance" =>0.001,
    "penalty" =>10,
    "sampling_rate" =>1,
  }

  def self.volume_to_pseudoatom(infile, outfile, options = {})
    options = Hash[*options.collect{|key, value| [key.to_s, value]}.flatten]
    options = DEFAULT_OPTIONS.merge(options)
    options.delete_if{|key, value| ! DEFAULT_OPTIONS.keys.include?(key) || value == false}

    params  = options.collect {|param, value| "-#{param} #{value}" } * " "
    cmd = "#{File.join(BIN_DIR, 'xmipp_convert_vol2pseudo')} #{params} -i #{infile} -o #{outfile} -thr 2"
    system(cmd)
  end
end

if __FILE__ == $0
  XMIPP.volume_to_pseudoatom('test/data/PolAB_msk4.spi', 'tmp/PolAB_msk4')
end
