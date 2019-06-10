
class Halwayi
	def Halwayi.error msg
		STDERR.puts msg
		exit 1
	end

	@project_root     = ENV['ProjectRoot']
	@etc_root         = ENV["EtcRoot"]
	@magic_root       = ENV['MagicRoot']
	@bin_root         = ENV["BinRoot"]
	@art_root         = ENV["ArtifactsRoot"]
	@build_magic_root = ENV['BuildMagicRoot']
	@ctypesfile       = ENV['CTypesFile']

	Halwayi.error "Project root (ProjectRoot) not defined"          if @project_root     == nil
	Halwayi.error "temp build folder (EtcRoot) not defined"         if @etc_root         == nil
	Halwayi.error "scripts folder (MagicRoot) not defined"          if @magic_root       == nil
	Halwayi.error "bin folder (BinRoot) not defined"                if @bin_root         == nil
	Halwayi.error "Artifacts folder (ArtifactsRoot) not defined"    if @art_root         == nil
	Halwayi.error "Build Magic folder (BuildMagicRoot) not defined" if @build_magic_root == nil

	@project_root     = @project_root.gsub('\\', '/')
	@bin_root         = @bin_root.gsub('\\', '/')
	@build_magic_root = @build_magic_root.gsub('\\', '/')
	@art_root         = @art_root.gsub('\\', '/')
	@magic_root       = @magic_root.gsub('\\', '/')
	@target           = ENV['target']
	@targets          = nil
	@project_name     = nil

	def Halwayi.project_root
		return @project_root
	end
	def Halwayi.etc_root
		return @etc_root
	end
	def Halwayi.magic_root
		return @magic_root
	end
	def Halwayi.bin_root
		return @bin_root
	end
	def Halwayi.art_root
		return @art_root
	end
	def Halwayi.build_magic_root
		return @build_magic_root
	end
	def Halwayi.ctypesfile
		return @ctypesfile
	end
	def Halwayi.auto_code_root target_name=nil
		target_name = @target if target_name == nil or target_name == ''
		return File.join @art_root, "auto", target_name, "code", "source" if target_name
		return nil
	end
	def Halwayi.project_name
		@project_name = `list project.name`.strip unless @project_name
		return @project_name
	end
	def Halwayi.target
		return @target
	end
	def Halwayi.targets
		unless @targets
			@targets = {}
			output   = `list targets`.gsub("\r\n","\n").split("\n").map(&:strip)
			output.each { |raw|
				target_name = raw[0...raw.index('(')].strip
				vp_config   = raw[raw.index('(')+1...raw.index(')')].strip
				variant, platform = vp_config.split('+')
				variant.strip!
				platform.strip!
				@targets[target_name] = { vp_config: vp_config, variant: variant, platform: platform }
			}
		end
		return @targets
	end
	def Halwayi.features target_name=nil
		command = "list features"
		error "target '#{target_name}' not found" if target_name && !Halwayi.targets.include?(target_name)
		command += " target #{target_name}"
		raw_output    = `#{command}`
		features_list = []
		lines         = string_to_lines raw_output
		found_marker  = false
		lines.each { |line|
			unless line =~ /final/i
				unless found_marker
					found_marker = true if line =~ /by naming/i
					next
				end
				next if line =~ /convention/i
			end
			l = line.strip
			next if l == ""
			name = File.basename l
			next if name.start_with? '_' or name.end_with? '_'
			features_list.push l
		}
		return features_list
	end
	def Halwayi.target_names
		return Halwayi.targets.keys
	end
	def Halwayi.get_target_info target_name
		return nil unless @targets
		return @targets[target_name]
	end
	def Halwayi.get_image_path feature_name, target_name, image_extension=".hex", build_type="release", image_name=nil
		targets = Halwayi.targets
		return nil unless targets.include?(target_name)
		
		image_name      = Halwayi.project_name  unless image_name
		image_extension = "." + image_extension unless image_extension.start_with?(".")
		
		return File.join @bin_root, "features", feature_name, build_type, target_name, "#{image_name}#{image_extension}"
	end
	def Halwayi.parse_variant_platform(str) return str.split('+').map(&:strip); end
	def Halwayi.get_fwver(without_target_name=false)
		raw_output = string_to_lines `fwver`
		output = raw_output[1]
		if output
			output.strip!
			output = output[output.index('/')+1..-1] if without_target_name and output.include?('/')
		end
		return output
	end
end
def project_root
	return Halwayi.project_root
end
def etc_root
	return Halwayi.etc_root
end
def magic_root
	return Halwayi.magic_root
end
def bin_root
	return Halwayi.bin_root
end
def art_root
	return Halwayi.art_root
end
def build_magic_root
	return Halwayi.build_magic_root
end
def variant
	return Halwayi.variant
end
def platform
	return Halwayi.platform
end
def target
	return Halwayi.target
end
def targets
	return Halwayi.targets
end
def target_names
	return Halwayi.target_names
end
def project_name
	return Halwayi.project_name
end
def auto_code_root target_name=nil
	return Halwayi.auto_code_root target_name
end
def ctypesfile
	return Halwayi.ctypesfile
end
