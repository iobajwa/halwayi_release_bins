
require 'yaml'
require 'fileutils'

STDOUT.sync = true

usage_text = "
A simple utility to deploy bundles. 'bundles' are halwayi's way of looking at deployment packages.
  
  deploy <bundle name(s):optional> <flags: optional>

  options: 
    
  	--deploy-template : 

    --path          : the path to deploy the images listed in the deploy.yaml
                      default: $build_root/deploy
                      aliases: -p

    --build-scripts : generates the build scripts required to build the bundle(s)
                      aliases: -b, --build_scripts

    --clean         : cleans the deployment
                      aliases: -c

    --list          : lists the images that will be deployed for the specified (or all) bundle(s)
                      aliases: -l, --ld

    --list-deep     : lists the full details of the images (variant, platform and file formats)
                      that will be deployed for the specified (or all) bundle(s)
                      aliases: -d, --list_deep

    --version       : overrides all deployed bundle version to the value specified
                      aliases: -v

    --verbose       : prints a lot of extra information while doing the job
                      aliases: -e

    --help          : -_-
                      aliases: -h, ?, -?, --?
"

class Symbol def with(*args, &block) ->(caller, *rest) { caller.send(self, *rest, *args, &block) } end end
class ::Hash def deep_merge(second) merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }; self.merge(second, &merger); end end
class String 
	def rchomp(sep=$/) self.start_with?(sep) ? self[sep.size..-1] : self end
	def lrchomp(sep)   rchomp(sep).chomp(sep) end
end
def error_log(msg) STDERR.puts(msg); $encountered_error=true end
def exit_if_error() exit(-1) if $encountered_error; end
def error(msg,error_code=-1) error_log(msg); exit(error_code); end
def gen_batch_file_prefix(task) return task.gsub(' ', '-'); end
def parse_array_from_string(str) return str.split(' ').map(&:chomp.with(',')); end
def parse_variant_platform(str) return str.split('+').map(&:strip); end
def create_file(name, contents) f = File.new(name, "w"); f.puts(contents);f.close(); end
def sanitize_sting_meta(meta, default_value=nil) return meta == nil ? default_value : meta; end
def sanitize_array_meta meta
	return parse_array_from_string meta if meta.class == String
	return meta
end
def get_dirs path
	dirs = []
	Dir.entries(path).each{ |e|
		next if e == "." || e == ".."
		e = File.join path, e
		next unless File.directory? e
		dirs.push e
	}
	dirs.push path
end
def create_shell_script task, bundle_name, bundle_meta, temp_script_root, batch_file_prefix=nil
	batch_file_contents = []
	batch_file_contents.push "
	@echo off
	rem preserve context
	set target_copy=%target%
	set var_copy=%var%
	set platform_copy=%platform%
	"
	bundle_meta[:bins].each { |bin_name, bin_meta|
		targets = bin_meta[:targets]
		if targets and targets.length == 0
			command  = "call #{task} #{bin_name}"
			batch_file_contents.push "set var=", "set platform=", command , "if %ERRORLEVEL% GTR 0 goto out", ""	
		else
			targets.each{ |tname, tmeta|
				command  = "call #{task} #{bin_name} #{tname}"
				batch_file_contents.push command , "if %ERRORLEVEL% GTR 0 goto out", ""
			}
		end
	} 

	batch_file_contents.push "
	rem restore context
	:out
	set var=%var_copy%
	set platform=%platform_copy%
	set target=%target_copy%
	"
	batch_file_contents.flatten!

	batch_file_prefix = gen_batch_file_prefix task unless batch_file_prefix
	file_name = File.join temp_script_root, "#{batch_file_prefix}-#{bundle_name}.bat"
	create_file file_name, batch_file_contents
	return file_name
end
def delete_shell_script task, bundle_name, temp_script_root, batch_file_prefix=nil
	batch_file_prefix = gen_batch_file_prefix task unless batch_file_prefix
	f = File.join temp_script_root, "#{batch_file_prefix}-#{bundle_name}.bat"
	if File.exist? f
		File.delete f
		return f
	end
	return nil
end
def parse_target_meta
	meta = {}
	targets_raw = `list targets`.split("\n")
	targets_raw.each { |line|
		if line.strip =~ /\s*\b(.*)\b\s*\((.*)\)\s*/
			target_name = $~[1]
			variant_platform_config = $~[2]
			meta[target_name] = variant_platform_config
			# if variant_platform_config
			# 	variant, platform = variant_platform_config.split '+'
			# 	platform = platform[0] if platform.class == Array
			# end
		end
	}

	return meta
end
def parse_source_destination raw
	if raw =~ /\s*(.*?)\s*>\s*(.*)\s*/
		source = $~[1].strip
		destination = $~[2]
		destination = destination ? destination.strip : source
		source      = source.lrchomp('/').lrchomp('\\')
		destination = destination.lrchomp('/').lrchomp('\\')
		return source, destination
	end
	raw = raw.rchomp('/').chomp('/').rchomp('\\').chomp('\\')
	return raw, raw
end


# parse, sanity check and sanitize the command line args
bundles_filtered  = []
deploy_path       = nil
verbose           = false
requested_actions = { }
forced_version    = nil
skip = false
ARGV.each_with_index { |e, i|
	if skip
		skip = false
		next
	end
	case e.gsub(/^[-]*/, '').gsub('-', '_')
	when "v", "version"
		forced_version = ARGV[i + 1]
		skip = true
	when "e", "verbose"
		verbose = true
	when "b", "build_scripts"
		requested_actions[:gen_scripts] = true
	when "c", "clean"
		requested_actions[:clean] = true
	when "l", "list"
		requested_actions[:list] = true
	when "d", "list_deep", "ld"
		requested_actions[:list_deep] = true
	when "p", "path"
		deploy_path = ARGV[i + 1]
		skip = true
	when "?", "h", "help"
		puts usage_text
		exit
	else
		bundles_filtered.push e
	end
}

## discover the environment ##
project_root     = ENV['ProjectRoot']
bin_root         = ENV['BinRoot']
temp_script_root = ENV['BuildMagicRoot']
artifacts_root   = ENV['ArtifactsRoot']
magic_root       = ENV['MagicRoot']
# sanity check
error "ProjectRoot not defined."    unless project_root
error "BinRoot not defined."        unless bin_root
error "BuildMagicRoot not defined." unless temp_script_root
error "ArtifactsRoot not defined."  unless artifacts_root
deploy_file = File.join magic_root, "deploy.yaml"
unless deploy_path
	puts "no deploy path provided, using default" if verbose
	deploy_path = File.join artifacts_root, "deploy"
	# create the root deploy directory unless it exists
	FileUtils.mkdir_p deploy_path unless Dir.exists? deploy_path
end
# ensure the paths exist
error "path doesn't exist: '#{deploy_path}'"                    unless Dir.exist? deploy_path
error "temp script folder doesn't exist: '#{temp_script_root}'" unless Dir.exist? temp_script_root
error "deploy.yaml not found in MagicRoot ('#{magic_root}')."   unless File.exist? deploy_file
# sanitize
project_root     = project_root.gsub('\\', '/')
bin_root         = bin_root.gsub('\\', '/')
temp_script_root = temp_script_root.gsub('\\', '/')
artifacts_root   = artifacts_root.gsub('\\', '/')
magic_root       = magic_root.gsub('\\', '/')
deploy_path      = deploy_path.gsub('\\', '/')


if verbose
	puts "deploy path    : #{deploy_path}"
	puts "project root   : #{project_root}"
	puts "bin root       : #{bin_root}"
	puts "artifacts root : #{artifacts_root}"
	puts "magic root     : #{magic_root}"
	puts "deploy path    : #{deploy_path}"
end



## parse, sanity check and sanitize deploy.yaml ##
known_meta = ["variants", "platforms", "vp_configs", "formats", "targets", "version"]
begin
	user_meta = YAML.load_file deploy_file
rescue Exception => e
	error_log "error reading yaml file:"
	error e.message
end
user_meta = { "default" => user_meta } if user_meta.class != Hash
global_version    = sanitize_sting_meta user_meta["version"], "<unknown>"
global_version    = forced_version if forced_version
global_variants   = sanitize_array_meta user_meta["variants"]
global_platforms  = sanitize_array_meta user_meta["platforms"]
global_vp_configs = sanitize_array_meta user_meta["vp_configs"]
global_formats    = sanitize_array_meta user_meta["formats"]
global_targets    = sanitize_array_meta user_meta["targets"]
global_targets    = [] unless global_targets
global_vp_configs = [] unless global_vp_configs
global_formats = [".hex"] if global_formats == nil or global_formats.length == 0
deploy_bundles = {}
parsed_targets_repo = parse_target_meta
global_variants.each{ |v| global_platforms.each{ |pl| global_vp_configs.push "#{v}+#{pl}" } if global_platforms } if global_variants

user_meta.each_pair { |bundle_name, bundle_meta|
	next if known_meta.include? bundle_name

	# parse the deploy bundle
	local_version = nil
	bins = {}
	if bundle_meta.class == Array
		bundle_meta.each { |b| 
			source, destination = parse_source_destination b
			bins[source] = { :vp_configs => global_vp_configs, :targets => global_targets, :formats => global_formats, :destination => destination, :version => global_version.to_s }
		}
	elsif bundle_meta.class == Hash
		local_version    = sanitize_sting_meta bundle_meta["version"]
		local_variants   = sanitize_array_meta bundle_meta["variants"]
		local_platforms  = sanitize_array_meta bundle_meta["platforms"]
		local_vp_configs = sanitize_array_meta bundle_meta["vp_configs"]
		local_formats    = sanitize_array_meta bundle_meta["formats"]
		local_targets    = sanitize_array_meta bundle_meta["targets"]
		error "'#{bundle_name}' bundle: no bins listed" unless bundle_meta.include? "bins"
		bundle_meta["bins"].each { |b|
			applicable_targets    = local_targets
			applicable_targets    = global_targets   unless applicable_targets
			applicable_variants   = local_variants
			applicable_variants   = global_variants  unless applicable_variants
			applicable_platforms  = local_platforms
			applicable_platforms  = global_platforms unless applicable_platforms
			applicable_formats    = local_formats
			applicable_formats    = global_formats   if local_formats == nil || local_formats.length == 0
			applicable_configs    = local_vp_configs unless global_vp_configs.length > 0
			applicable_configs    = [] unless applicable_configs
			applicable_vp_configs = []

			if b.class == Hash
				source = b.keys[0]
				# figure out the variant+platform configuration
				v = b[source]
				t = []
				if v.class == String
					v.strip!
					if v.start_with? ">"
						destination = v.gsub('>', '').strip
					else
						applicable_vp_configs = sanitize_array_meta v
						destination           = source
					end
				elsif v.class == Hash
					i_version    = sanitize_sting_meta v["version"]
					i_targets    = sanitize_array_meta v["targets"]
					i_vp_configs = sanitize_array_meta v["vp_configs"]
					source_t     = v["source"]
					destination  = v["destination"]
					source_t     = source_t.lrchomp('/').lrchomp('\\') if source_t
					destination  = destination.lrchomp('/').lrchomp('\\') if destination
					source       = source_t if source_t
					destination  = source   unless destination
					if i_vp_configs == nil
						t[0] = sanitize_array_meta v["variants"]
						t[1] = sanitize_array_meta v["platforms"]
					else
						variants = []
						platforms = []
						i_vp_configs.each { |vp|
							variant, platform = parse_variant_platform vp
							variants.push variant
							platforms.push platform
						}
						t = [ variants, platforms ]
					end
					e = v["formats"]
					iformats = sanitize_array_meta e
					applicable_formats = iformats  if iformats and iformats.length > 0
					applicable_targets = i_targets if i_targets
					applicable_version = i_version if i_version
				else
					error "'#{bundle_name}.#{source}' invalid meta '#{v}'"
				end
				applicable_variants  = t[0] if t[0]
				applicable_platforms = t[1] if t[1]
			else
				source, destination = parse_source_destination b
			end

			# create a list of variant+platform configs
			applicable_variants.each{ |v| applicable_platforms.each{ |pl| applicable_vp_configs.push "#{v}+#{pl}" } } if applicable_vp_configs.length == 0 && applicable_variants && applicable_platforms
			applicable_vp_configs = applicable_configs if applicable_vp_configs.length == 0

			# ensure all formats begin with '.'
			t = []
			applicable_formats.each { |f| f = "." + f unless f[0] == '.'; t.push f }
			applicable_formats = t
			applicable_formats = global_formats if applicable_formats == nil || applicable_formats.length == 0

			# we now have a bin meta
			bins[source] = { :vp_configs => applicable_vp_configs, :targets => applicable_targets, :formats => applicable_formats, :destination => destination, :version => applicable_version }
		}
	end

	# figure out the applicable_version
	applicable_version = local_version
	applicable_version = global_version if applicable_version == nil || forced_version
	applicable_version = applicable_version.to_s

	# parse the target definitions
	bins.each_pair { |bname, bmeta|
		vp_configs = bmeta[:vp_configs]
		targets_parsed = {}
		bmeta[:targets].each { |t|
			begin
				target_vp_config = parsed_targets_repo[t]
				if target_vp_config 
					vp_configs.push target_vp_config unless vp_configs.include? target_vp_config
					targets_parsed[t] = target_vp_config
				end
			rescue Exception => e
				error "'#{bundle_name}': " + e.message
			end
		}
		bmeta[:targets]    = targets_parsed
		bmeta[:vp_configs] = vp_configs.flatten
	}

	deploy_bundles[bundle_name] = { :bins => bins, :version => applicable_version }
}

# filter bundles and ensure user provided meaningful filter
applied_filter = false
unless bundles_filtered.length == 0
	bundles_filtered.each { |b| error_log "'#{b}' ?" unless deploy_bundles.keys.include? b }
	exit_if_error
	deploy_bundles = deploy_bundles.select { |k, v| bundles_filtered.include? k }
	applied_filter = true
end


error "nothing to do." if deploy_bundles.length == 0    # sanity check

# figure out paths for each variant+platform binary
deploy_bundles.each_pair { |bundle_name, bundle_meta|
	bundle_meta[:bins].each_pair { |bin_name, bin_meta|
		images      = {}
		b_path      = File.join bin_root, "features"
		vp_configs  = bin_meta[:vp_configs]
		targets     = bin_meta[:targets]
		destination = bin_meta[:destination]
		destination = bin_name unless destination
		vp_late_discovery = false
		# target gets preference over vp_configs
		if targets.length > 0
			targets.each_pair { |tname, tconfig|
				r_path             = "#{bin_name}/release/#{tconfig}"
				r_destination_path = "#{destination}/release/#{tconfig}"
				full_path          = File.join b_path, r_path
				images[tconfig]    = { :full_path => full_path, :relative_path => r_path, :base_path => b_path, :relative_destination_path => r_destination_path }
			}
		elsif vp_configs.length > 0
			vp_configs.each { |vc|
				r_path             = "#{bin_name}/release/#{vc}"
				r_destination_path = "#{destination}/release/#{vc}"
				full_path          = File.join b_path, r_path
				images[vc]         = { :full_path => full_path, :relative_path => r_path, :base_path => b_path, :relative_destination_path => r_destination_path }
			}
		elsif vp_configs.length == 0
			r_path             = "#{bin_name}/release/"
			r_destination_path = "#{destination}/release/"
			full_path   = File.join b_path, r_path
			images["*"] = { :full_path => full_path, :relative_path => r_path, :base_path => b_path, :r_destination_path => r_destination_path }
			vp_late_discovery = true
		else
		end
		bin_meta[:vp_late_discovery] = vp_late_discovery
		bin_meta[:images] = images
	}
	bundle_meta[:deploy_path] = File.join deploy_path, bundle_name
}


## clean, if requested ##
if requested_actions.include?(:clean)

	if applied_filter
		deploy_bundles.each_pair { |name, meta| 
			bundle_deploy_path = meta[:deploy_path]
			FileUtils.rm_rf bundle_deploy_path if Dir.exists? bundle_deploy_path
			f = delete_shell_script "build", name, temp_script_root
			puts "deleted '#{f}" if f and verbose
			f = delete_shell_script "build clean", name, temp_script_root
			puts "deleted '#{f}" if f and verbose
			puts "cleaned '#{name}'" if verbose
		}
	else
		# simply delete the root and we're good to go
		FileUtils.rm_rf deploy_path if Dir.exists? deploy_path
		puts "cleaned everything" if verbose
	end
	exit
end


## generate scripts (always) ##
deploy_bundles.each_pair { |k, v| 
	f = create_shell_script "build", k, v, temp_script_root
	puts "created '#{f}'" if f and verbose
	f = create_shell_script "build clean", k, v, temp_script_root
	puts "created '#{f}'" if f and verbose
}



## generate scripts and exit, if requested ##
exit if requested_actions.include?(:gen_scripts)


## list, if requested ##
if requested_actions.include?(:list)
	deploy_bundles.each_pair { |name, meta|
		puts "", "#{name}:"
		meta[:bins].each_pair { |bin_name, _|  puts "  - #{bin_name}" }
	}
	exit
end



# ensure all the requested bins exist
non_existant_bundles = {}
deploy_bundles.each_pair { |bundle_name, bundle_meta|
	bundle_bins_exist = true
	bundle_meta[:bins].each_pair { |bin_name, bin_meta|
		bin_meta[:images].each_pair { |iname, imeta|
			unless Dir.exist? imeta[:full_path]
				bundle_bins_exist = false
				break
			end
		}
	}
	non_existant_bundles[bundle_name] = bundle_meta unless bundle_bins_exist
}
if non_existant_bundles.length > 0
	script_name = ""
	non_existant_bundles.keys.each { |b| script_name += "build-#{b} / " }
	script_name.chomp!(' / ')
	error_log "Could not find all binaries needed for deployment."
	error     "Use '#{script_name}' to build the needed binaries."
end



## list-deep, if requested ##
if requested_actions.include?(:list_deep)
	deploy_bundles.each_pair { |name, meta|
		puts "", "#{name}:"
		meta[:bins].each_pair { |bin_name, bin_meta| 
			idescription = []
			bin_meta[:images].each_pair { |iname, _| idescription.push "#{iname}: #{bin_meta[:formats]}" }
			if idescription.length ==  1
				puts "  - #{bin_name} : #{idescription[0]}"
			else
				puts "  - #{bin_name}"
				idescription.each { |l| puts "    - #{l}" }
			end

		}
	}
	exit
end


##
## deploy, otherwise ##
##



# create a list of files for each bundle.image to deploy

def find_files path, formats, base_path, source_path, destination_path
	files_found = {} 
	get_dirs( path ).each { |path|
		formats.each { |format|
			search_path = File.join path, "*#{format}"
			files       = Dir[search_path]
			files.each { |f|
				fname         = File.basename f
				relative_path = File.dirname  f
				relative_path.gsub! base_path + "/", ''
				deploy_rpath = relative_path.gsub /(\/|\\)release/i, ''
				deploy_rpath.gsub! source_path + "/", ''
				deploy_rpath = File.join destination_path, deploy_rpath
				files_found[fname] = { :file => f, :path => path, :relative_path => relative_path, :deploy_rpath => deploy_rpath }
			}
		}
	}
	return files_found
end

deploy_bundles.each_pair { |name, bundle_meta|
	bundle_meta[:bins].each_pair { |bin_name, bin_meta|
		
		images = bin_meta[:images]
		
		if bin_meta[:vp_late_discovery]
			# we are yet to discover all the possible variant+platform configurations
			imeta_copy    = images[images.keys[0]]
			files_found   = find_files imeta_copy[:full_path], bin_meta[:formats], imeta_copy[:base_path], bin_name, bin_meta[:destination]

			# create new images (and enlist files) based on the unique variant+platform configuration
			new_images = {}
			files_found.each_pair { |fname, fmeta| 
				path = fmeta[:path]
				vp_config_combined = path.split('/').collect{ |i| i.include?("+") ? i : nil } - [nil]
				vp_config = vp_config_combined[0]
				if new_images.include? vp_config
					# we already have an image ready, in which case, simply append the new file entry
					fname = fname
					new_images[vp_config][:files][fname] = fmeta
				else
					# we need to create a new image
					full_path     = File.join imeta_copy[:full_path], vp_config
					relative_path = File.join imeta_copy[:relative_path], vp_config
					new_images[vp_config] = { :full_path => full_path, :relative_path => relative_path, :base_path => imeta_copy[:base_path] }
					new_images[vp_config][:files] = { fname => fmeta }
				end
			}
			bin_meta[:images] = new_images
		else
			images.each_pair { |iname, imeta| 
				files_found = find_files imeta[:full_path], bin_meta[:formats], imeta[:base_path], bin_name, bin_meta[:destination]
				imeta[:files] = files_found
			}
		end

		if verbose
			bin_meta[:images].each_pair { |iname, imeta|
				file_count = imeta[:files].length
				status = "'#{name}.#{bin_name}.#{iname}': found #{file_count} file" + (file_count > 1 || file_count == 0 ? "s" : "")
				puts status
			}
		end
	}
}

# copy the discovered files

# copy each image to it's unique folder
counter = 0
deploy_bundles.each_pair { |n, m|

	bundle_deploy_path = m[:deploy_path]
	# clean existing deployment if it exists 
	FileUtils.rm_rf   bundle_deploy_path if Dir.exists? bundle_deploy_path
	FileUtils.mkdir_p bundle_deploy_path

	m[:bins].each_pair { |name, meta| 
		images = meta[:images]
		next if images.length == 0

		# copy all images
		images.each_pair { |i, imeta|
			imeta[:files].each { |fname, fmeta|
				deploy_rpath = fmeta[:deploy_rpath]
				source_file  = fmeta[:file]
				dest_path    = File.join bundle_deploy_path, deploy_rpath
				dest_file    = File.join dest_path, fname
				
				FileUtils.mkdir_p dest_path
				FileUtils.cp source_file, dest_file
				
				puts "deployed '#{source_file}' to '#{dest_file}'" if verbose
				counter += 1
			}
		}
	}
}

# generate meta files the describe the bundles
deploy_bundles.each_pair { |bundle_name, bundle_meta|
	
	# map all the images to targets
	targets_image_map = {}
	parsed_targets_repo.each_pair { |t, v| targets_image_map[t] = {} }
	# targets_image_map = { "*" => {} } if targets_image_map.length == 0

	bundle_meta[:bins].each_pair { |bin_name, bin_meta|
		image_dmeta = {}
		targets     = bin_meta[:targets]
		destination = bin_meta[:destination]
		bin_meta[:images].each { |iname, imeta|
			files_dmeta = {}
			imeta[:files].each { |fname, fmeta|
				files_dmeta[fname] = fmeta[:deploy_rpath]
			}
			if targets.length > 0
				targets.each_pair { |t,m|
					next unless m == iname
					targets_image_map[t] = targets_image_map[t].deep_merge( { destination => { iname => files_dmeta } } ) 
				}
			else
				map = targets_image_map[iname]
				map = {} unless map
				map = map.deep_merge( { destination => { iname => files_dmeta } } )
				targets_image_map[iname] = map
			end
			image_dmeta[iname] = files_dmeta
		}
	}

	final_targets_image_map = {}
	targets_image_map.each_pair { |t,m|
		next if m == {}
		final_targets_image_map[t] = m
	}

	deployed_bundle_meta = { "name" => bundle_name, "version" => bundle_meta[:version], "targets" => final_targets_image_map }

	file_name = File.join bundle_meta[:deploy_path], "bundle.yaml"
	create_file file_name, deployed_bundle_meta.to_yaml
}

summary = "deployed #{deploy_bundles.length} bundles."
summary = "\n" + summary + ". involving #{counter} files." if verbose

puts summary
