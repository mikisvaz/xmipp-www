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

  STRING_OPTIONS = { "intensityColumn" => %w(occupancy Bfactor) }

  def self.process_options(options)
    options.delete_if{|key, value| ! DEFAULT_OPTIONS.keys.include?(key.to_s)}
    options = Hash[*options.collect{|key, value| 
      key = key.to_s
      case
      when Integer === DEFAULT_OPTIONS[key] || Float === DEFAULT_OPTIONS[key]
        value = value.to_f
      when FalseClass === DEFAULT_OPTIONS[key] || TrueClass === DEFAULT_OPTIONS[key]
        value = value == true
      else 
        value = STRING_OPTIONS[key].include?(value) ? value : DEFAULT_OPTIONS[key] 
      end
      [key, value]
    }.flatten]
    options = DEFAULT_OPTIONS.merge(options)
    options.delete_if{|key, value| ! value}
    options
  end

  def self.volume_to_pseudoatom(infile, outfile, options = {})
    options = process_options(options)

    params  = options.collect {|param, value| "-#{param} #{value}" } * " "
    cmd = "#{File.join(BIN_DIR, 'xmipp_convert_vol2pseudo')} #{params} -i #{infile} -o #{outfile} -thr 2"
    system(cmd)
  end
end

if __FILE__ == $0
  XMIPP.volume_to_pseudoatom('test/data/PolAB_msk4.spi', 'tmp/PolAB_msk4', {})
end
