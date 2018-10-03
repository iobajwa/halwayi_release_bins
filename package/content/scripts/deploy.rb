
require 'yaml'
require 'fileutils'
class Symbol
  def with(*args, &block)
    ->(caller, *rest) { caller.send(self, *rest, *args, &block) }
  end
end
def error_log(msg) STDERR.puts(msg); end
def error(msg,error_code=-1) error_log(msg); exit(error_code); end
def gen_batch_file_prefix(task) return task.gsub(' ', '-'); end
def parse_array_from_string(str) return str.split(' ').map(&:chomp.with(',')); end
def parse_variant_platform(str) return str.split('+').map(&:strip); end
def create_file(name, contents) f = File.new(name, "w"); f.puts(contents);f.close(); end
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
	set var_copy=%var%
	set platform_copy=%platform%
	"
	bundle_meta[:bins].each { |bin_name, bin_meta|
		vp_configs = bin_meta[:vp_configs]
		if vp_configs.length == 0
			command  = "call #{task} #{bin_name}"
			batch_file_contents.push "set var=", "set platform=", command , "if %ERRORLEVEL% GTR 0 goto out", ""	
		else
			vp_configs.each{ |vp|
				variant, platform = parse_variant_platform vp
				command  = "call #{task} #{bin_name}"
				command += " var #{variant}"       if variant and variant != ""
				command += " platform #{platform}" if platform and platform != ""
				batch_file_contents.push command , "if %ERRORLEVEL% GTR 0 goto out", ""
			}
		end
	} 

	batch_file_contents.push "
	rem restore context
	:out
	set var=%var_copy%
	set platform=%platform_copy%
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


# begin
# 	first_variant = `list first_variant`.strip
# rescue Exception => e
# end

# parse, sanity check and sanitize the command line args
bundles_filtered = []
verbose                    = false
only_gen_scripts_requested = false
clean_action_requested     = false
ARGV.each { |e|
	case e.gsub /^[-]*/, ''
	when "v", "verbose"
		verbose = true
	when "s", "scripts"
		only_gen_scripts_requested = true
	when "c", "clean"
		clean_action_requested = true
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
deploy_path = File.join artifacts_root, "deploy"
error "deploy.yaml not found in MagicRoot ('#{magic_root}')." unless File.exist? deploy_file
# sanitize
project_root     = project_root.gsub('\\', '/')
bin_root         = bin_root.gsub('\\', '/')
temp_script_root = temp_script_root.gsub('\\', '/')
artifacts_root   = artifacts_root.gsub('\\', '/')
magic_root       = magic_root.gsub('\\', '/')

## parse, sanity check and sanitize deploy.yaml ##
user_meta = YAML.load_file deploy_file
user_meta = { "default" => user_meta } if user_meta.class != Hash
global_variants   = sanitize_array_meta user_meta["variants"]
global_platforms  = sanitize_array_meta user_meta["platforms"]
global_vp_configs = sanitize_array_meta user_meta["vp_configs"]
global_formats    = sanitize_array_meta user_meta["formats"]
global_vp_configs = [] unless global_vp_configs
global_variants.each{ |v| global_platforms.each{ |pl| global_vp_configs.push "#{v}+#{pl}" } if global_platforms } if global_variants
global_formats = [".hex"] if global_formats == nil or global_formats.length == 0

deploy_bundles = {}
user_meta.each_pair { |bundle_name, bundle_meta|
	next if bundle_name == "variants" or bundle_name == "platforms" or bundle_name == "vp_configs" or bundle_name == "formats"
	# parse the deploy bundle

	bins = {}
	if bundle_meta.class == Array
		bundle_meta.each { |b| bins[b] = { :vp_configs => global_vp_configs, :formats => global_formats } }
	elsif bundle_meta.class == Hash
		local_variants   = sanitize_array_meta bundle_meta["variants"]
		local_platforms  = sanitize_array_meta bundle_meta["platforms"]
		local_vp_configs = sanitize_array_meta bundle_meta["vp_configs"]
		local_formats    = sanitize_array_meta bundle_meta["formats"]
		error "no bins listed for '#{bundle_name}' bundle" unless bundle_meta.include? "bins"
		bundle_meta["bins"].each { |b|
			applicable_variants  = local_variants
			applicable_variants  = global_variants unless applicable_variants
			applicable_platforms = local_platforms
			applicable_platforms = global_platforms unless applicable_platforms
			applicable_formats   = local_formats
			applicable_formats   = global_formats if local_formats == nil || local_formats.length == 0
			applicable_configs   = local_vp_configs unless global_vp_configs.length > 0
			applicable_configs   = [] unless applicable_configs
			vp_configs           = []

			if b.class == Hash
				bin_name = b.keys[0]
				# figure out the variant+platform configuration
				v = b[bin_name]
				t = []
				if v.class == String
					vp_configs = parse_array_from_string v
				elsif v.class == Hash
					i_vp_configs = sanitize_array_meta v["vp_configs"]
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
					iformats = parse_array_from_string e
					applicable_formats = iformats if iformats and iformats.length > 0
				end
				applicable_variants  = t[0] if t[0]
				applicable_platforms = t[1] if t[1]
			else
				bin_name = b
			end

			# create a list of variant+platform configs
			applicable_variants.each{ |v| applicable_platforms.each{ |pl| vp_configs.push "#{v}+#{pl}" } } if vp_configs.length == 0 && applicable_variants && applicable_platforms
			vp_configs = applicable_configs if vp_configs.length == 0

			# ensure all formats begin with '.'
			t = []
			applicable_formats.each { |f| f = "." + f unless f[0] == '.'; t.push f }
			applicable_formats = t
			applicable_formats = global_formats if applicable_formats == nil || applicable_formats.length == 0

			# we now have a bin meta
			bins[bin_name] = { :vp_configs => vp_configs, :formats => applicable_formats }
		}
	end

	deploy_bundles[bundle_name] = { :bins => bins }
}

# filter bundles and ensure user provided meaningful filter
applied_filter = false
unless bundles_filtered.length == 0
	bundles_filtered.each { |b| error "bundle '#{b}' not found." unless deploy_bundles.keys.include? b }
	deploy_bundles    = deploy_bundles.select { |k, v| bundles_filtered.include? k }
	applied_filter = true
end

error "nothing to do." if deploy_bundles.length == 0    # sanity check

# figure out paths for each variant+platform binary
deploy_bundles.each_pair { |bundle_name, bundle_meta|
	bundle_meta[:bins].each_pair { |bin_name, bin_meta|
		images     = {}
		b_path     = File.join bin_root, "features"
		vp_configs = bin_meta[:vp_configs]
		vp_late_discovery = false
		if vp_configs.length == 0
			r_path      = "#{bin_name}/release/"
			full_path   = File.join b_path, r_path
    		images["*"] = { :full_path => full_path, :relative_path => r_path, :base_path => b_path }
    		vp_late_discovery = true
		else
			vp_configs.each { |vc|
				r_path     = "#{bin_name}/release/#{vc}"
				full_path  = File.join b_path, r_path
	    		images[vc] = { :full_path => full_path, :relative_path => r_path, :base_path => b_path }
			}
		end
		bin_meta[:vp_late_discovery] = vp_late_discovery
		bin_meta[:images] = images
	}
	bundle_meta[:deploy_path] = File.join deploy_path, bundle_name
}

## clean, if requested ##
if clean_action_requested

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



exit if only_gen_scripts_requested
## deploy, otherwise ##


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



# create a list of files for each bundle.image to deploy

def find_files path, formats, base_path
	files_found = {} 
	get_dirs( path ).each { |path|
		formats.each { |format|
			search_path = File.join path, "*#{format}"
			files       = Dir[search_path]
			files.each { |f|
				fname         = File.basename f
				relative_path = File.dirname  f
				relative_path.gsub! base_path, ''
				deploy_rpath = relative_path.gsub /(\/|\\)release/i, ''
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
			files_found   = find_files imeta_copy[:full_path], bin_meta[:formats], imeta_copy[:base_path]

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
				files_found = find_files imeta[:full_path], bin_meta[:formats], imeta[:base_path]
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

# create the root deploy directory unless it exists
FileUtils.mkdir_p deploy_path unless Dir.exists? deploy_path
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
	
	bins_dmeta = {}
	bundle_meta[:bins].each_pair { |bin_name, bin_meta|
		image_dmeta = {}
		bin_meta[:images].each { |iname, imeta|
			files_dmeta = {}
			imeta[:files].each { |fname, fmeta|
				files_dmeta[fname] = fmeta[:deploy_rpath]
			}
			image_dmeta[iname] = files_dmeta
		}
		bins_dmeta[bin_name] = image_dmeta
	}

	deployed_bundle_meta = { "name" => bundle_name, "bins" => bins_dmeta }
	
	file_name = File.join bundle_meta[:deploy_path], "bundle.yaml"
	create_file file_name, deployed_bundle_meta.to_yaml
}


summary = "deployed #{deploy_bundles.length} bundles."
summary = "\n" + summary + ". involving #{counter} files." if verbose

puts summary
