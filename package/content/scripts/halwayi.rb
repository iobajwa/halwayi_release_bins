
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
	@variant          = ENV['var']
	@platform         = ENV['platform']
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
		if target_name
			targets = Halwayi.targets
			vp_config = targets[target_name][:vp_config]
			return File.join @art_root, "auto", vp_config, "code", "source" if vp_config
		end
		if @variant and @platform
			return File.join @art_root, "auto", "#{@variant}+#{@platform}", "code", "source"
		end
		return nil
	end
	def Halwayi.project_name
		@project_name = `list project-name`.strip unless @project_name
		return @project_name
	end
	def Halwayi.targets
		unless @targets
			@targets = {}
			output   = `list targets`.gsub("\r\n","\n").split("\n").map(&:strip)
			output.each { |raw|
				target_name = raw[0...raw.index('(')].strip
				vp_config = raw[raw.index('(')+1...raw.index(')')].strip
				variant, platform = vp_config.split('+')
				variant.strip!
				platform.strip!
				@targets[target_name] = { vp_config: vp_config, variant: variant, platform: platform }
			}
		end
		return @targets
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
		
		vp_config       = targets[target_name][:vp_config]
		image_name      = Halwayi.project_name  unless image_name
		image_extension = "." + image_extension unless image_extension.start_with?(".")
		
		return File.join @bin_root, "features", feature_name, build_type, vp_config, "#{image_name}#{image_extension}"
	end
	def Halwayi.parse_variant_platform(str) return str.split('+').map(&:strip); end
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
