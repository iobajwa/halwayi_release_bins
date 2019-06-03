
require 'yaml'
require 'fileutils'
require_relative 'halwayi'
require_relative 'helpers'

STDOUT.sync = true

usage_text = "
A simple utility to deploy bundles. 'bundles' are halwayi's way of looking at deployment packages.
  
  deploy <bundle name(s):optional> <flags: optional>

  options: 
    
    --path          : the path to deploy the images listed in the bundles.yaml
                      default: $build_root/deploy
                      aliases: -p

    --build-scripts : generates the build scripts required to build the bundle(s)
                      aliases: -b, -s, --build_scripts

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

def gen_batch_file_prefix(task) return task.gsub(' ', '-'); end
def parse_array_from_string(str) return str.split(' ').map(&:chomp.with(',')); end
def sanitize_sting_meta(meta, default_value=nil) return meta == nil ? default_value : meta; end
def sanitize_array_meta meta
	return parse_array_from_string meta if meta.class == String
	return meta
end
def create_shell_script task, bundle_name, bundle_meta, temp_script_root, batch_file_prefix=nil
	batch_file_contents = []
	batch_file_contents.push "
	@echo off
	rem preserve context
	set target_copy=%target%
	"
	bundle_meta.each_pair { |tname, bins|
		bins.each { |bin_meta|
			bin_name = bin_meta[:source]
			command  = "call #{task} #{bin_name} target #{tname}"
			batch_file_contents.push command , "if errorlevel 1 goto out", ""
		}
	}

	batch_file_contents.push "
	rem restore context
	:out
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
	when "b", "s", "build_scripts"
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
# sanity check
temp_script_root = build_magic_root
deploy_file      = File.join magic_root, "bundles.yaml"
unless deploy_path
	puts "no deploy path provided, using default" if verbose
	deploy_path = File.join art_root, "bundles"
	# create the root bundles directory unless it exists
	FileUtils.mkdir_p deploy_path unless Dir.exists? deploy_path
end
# ensure the paths exist
error "path doesn't exist: '#{deploy_path}'"                    unless Dir.exist?  deploy_path
error "bundles.yaml not found in MagicRoot ('#{magic_root}')."  unless File.exist? deploy_file
# sanitize
deploy_path = deploy_path.gsub('\\', '/')


if verbose
	puts "deploy path    : #{deploy_path}"
	puts "project root   : #{project_root}"
	puts "bin root       : #{bin_root}"
	puts "artifacts root : #{art_root}"
	puts "magic root     : #{magic_root}"
	puts "deploy path    : #{deploy_path}"
end



## parse, sanity check and sanitize bundles.yaml ##
begin
	user_meta = YAML.load_file deploy_file
rescue Exception => e
	error_log "error reading yaml file:"
	error e.message
end
user_meta = { "default-bundle" => user_meta } if user_meta.class != Hash   # the bundle file may simply be just a list of feature names
global_version = sanitize_sting_meta user_meta["version"], Halwayi.get_fwver
global_version = forced_version if forced_version
global_formats = sanitize_array_meta user_meta["formats"]
global_targets = sanitize_array_meta user_meta["targets"]
global_targets = Halwayi.target_names unless global_targets
global_formats = [".hex"] if global_formats == nil or global_formats.length == 0
deploy_bundles = {}
project_target_names = Halwayi.target_names
known_meta = ["targets", "formats", "version"]

user_meta.each_pair { |bundle_name, bundle_meta|
	next if known_meta.include? bundle_name

	# parse the deploy bundle
	local_version          = nil
	bins                   = []
	assets                 = { dirs: [], files: [] }
	images_for_all_targets = {}


	if bundle_meta.class == Array

		# we simply have a list of features
		# parse each entry, create a bin list
		# and assume we'll bundle these binaries for each global_target
		bundle_meta.each { |b|
			source, destination = parse_source_destination b
			bins.push( { source: source, destination: destination, formats: global_formats } )
		}
		global_targets.each { |t|  images_for_all_targets[t] = { bins: bins } }

	elsif bundle_meta.class == Hash

		# we have a more detailed description
		local_formats = sanitize_array_meta bundle_meta["formats"]
		local_targets = sanitize_array_meta bundle_meta["targets"]
		bundle_bins   = bundle_meta["bins"]
		bundle_assets = bundle_meta["assets"]
		error "'#{bundle_name}' bundle: no bins and assets listed" if bundle_bins == nil and bundle_assets == nil


		# parse bundle assets
		bundle_assets.each { |a|

			source, destination = parse_source_destination a
			full_path     = File.join project_root, source
			category      = File.directory?(full_path) ? :dirs : :files
			relative_path = File.dirname destination
			assets[category].push( { source: source, destination: destination, relative_path: relative_path, full_path: full_path } )

		} if bundle_assets


		# parse bundle bins
		bundle_bins.each { |b|

			applicable_targets = local_targets
			applicable_targets = global_targets unless applicable_targets
			applicable_formats = local_formats
			applicable_formats = global_formats if local_formats == nil || local_formats.length == 0

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
						applicable_targets = sanitize_array_meta v
						destination        = source
					end
				elsif v.class == Hash
					i_targets    = sanitize_array_meta v["targets"]
					i_formats    = sanitize_array_meta v["formats"]
					source_t     = v["source"]
					destination  = v["destination"]
					source_t     = source_t.lrchomp('/').lrchomp('\\') if source_t
					destination  = destination.lrchomp('/').lrchomp('\\') if destination
					source       = source_t  if     source_t
					destination  = source    unless destination
					applicable_formats = i_formats  if i_formats and i_formats.length > 0
					applicable_targets = i_targets  if i_targets
				elsif v.class == Array
					puts "#{v.class}"
					error "'#{bundle_name}.#{source}' invalid meta '#{v}'"
				end
			else
				source, destination = parse_source_destination b
			end

			# ensure all formats begin with '.'
			t = []
			applicable_formats.each { |f| f = "." + f unless f[0] == '.'; t.push f }
			applicable_formats = t
			applicable_formats = global_formats if applicable_formats == nil || applicable_formats.length == 0

			# ensure we have a valid applicable_target_list
			applicable_targets.each { |t| error "#{bundle_name}.#{source}: unknown target (#{t})" unless project_target_names.include?(t) }

			# we now have a bin meta
			bin_meta = { source: source, destination: destination, formats: applicable_formats }

			# append this to all applicable_targets
			applicable_targets.each { |t|  
				bin_array = images_for_all_targets[t]
				bin_array = [] unless bin_array
				bin_array.push bin_meta.clone
				images_for_all_targets[t] = bin_array
			}

		} if bundle_bins

	end

	# figure out the applicable_version
	applicable_version = local_version
	applicable_version = global_version if applicable_version == nil || forced_version
	applicable_version = applicable_version.to_s

	deploy_bundles[bundle_name] = { version: applicable_version, images: images_for_all_targets, assets: assets }
}




# filter bundles and ensure user provided meaningful filter
applied_filter = false
unless bundles_filtered.length == 0
	bundles_filtered.each { |b| error_log "'#{b}' ?" unless deploy_bundles.keys.include? b }
	exit_if_error
	deploy_bundles = deploy_bundles.select { |k, v| bundles_filtered.include? k }
	applied_filter = true
end


# ensure that the features names make sense
deploy_bundles.each_pair { |bname, bmeta|
	bmeta[:images].each_pair { |tname, bins| 
		target_features = Halwayi.features tname
		bins.each { |bin_meta|
			feature_name = bin_meta[:source]
			error "#{bname}.#{tname}: '#{feature_name}' feature doesn't exist for the target" unless target_features.include?(feature_name)
		}
	}
}


error "nothing to do." if deploy_bundles.length == 0    # sanity check

# figure out paths for each target binary
deploy_bundles.each_pair { |bundle_name, bundle_meta|
	bundle_meta[:images].each_pair { |tname, bins|
		bins.each { |bin_meta|

			b_path      = File.join bin_root, "features"
			bin_name    = bin_meta[:source]
			destination = bin_meta[:destination]
			destination = bin_name unless destination

			r_path             = "#{bin_name}/release/#{tname}"
			r_destination_path = "#{destination}/release/#{tname}"
			full_path          = File.join b_path, r_path

			bin_meta[:full_path]                 = full_path
			bin_meta[:relative_path]             = r_path
			bin_meta[:base_path]                 = b_path
			bin_meta[:relative_destination_path] = r_destination_path
		}
	}
	bundle_meta[:deploy_path] = File.join deploy_path, bundle_name
}


## always clean, exit if requested ##
if applied_filter
	deploy_bundles.each_pair { |name, meta| 
		bundle_deploy_path = meta[:deploy_path]
		FileUtils.rm_rf bundle_deploy_path if Dir.exists? bundle_deploy_path
		f = delete_shell_script "build", name, temp_script_root
		puts "deleted '#{f}" if f and verbose
		f = delete_shell_script "build clean", name, temp_script_root
		puts "deleted '#{f}"     if f and verbose
		puts "cleaned '#{name}'" if verbose
	}
else
	# simply delete the root and we're good to go
	FileUtils.rm_rf deploy_path if Dir.exists? deploy_path
	puts "cleaned everything"   if verbose
end
exit if requested_actions.include?(:clean)


## generate scripts (always) ##
deploy_bundles.each_pair { |k, v| 
	f = create_shell_script "build", k, v[:images], temp_script_root
	puts "created '#{f}'" if f and verbose
	f = create_shell_script "build clean", k, v[:images], temp_script_root
	puts "created '#{f}'" if f and verbose
}



## generate scripts and exit, if requested ##
exit if requested_actions.include?(:gen_scripts)


## list, if requested ##
if requested_actions.include?(:list)
	deploy_bundles.each_pair { |bundle_name, bmeta|
		puts "#{bundle_name}"
	}
	exit
end



# ensure all the requested bins and assets exist
bundles_with_missing_bins   = {}
bundles_with_missing_assets = {}
deploy_bundles.each_pair { |bundle_name, bmeta|

	assets = bmeta[:assets]

	assets[:dirs].each { |meta|
		dir_name = meta[:full_path]
		unless Dir.exist?(dir_name)
			bundles_with_missing_assets[bundle_name] = [] if bundles_with_missing_assets[bundle_name] == nil
			bundles_with_missing_assets[bundle_name].push dir_name
		end
	}

	assets[:files].each { |meta|
		file_name = meta[:full_path]
		unless File.exist?(file_name)
			bundles_with_missing_assets[bundle_name] = [] if bundles_with_missing_assets[bundle_name] == nil
			bundles_with_missing_assets[bundle_name].push file_name
		end
	}

	bmeta[:images].each_pair { |tname, bins| 

		bins_exist, assets_exit = true, true

		bins.each { |bin_meta|

			feature_name = bin_meta[:full_path]
			unless Dir.exist? feature_name
				bins_exist = false
				break
			end
		}

		bundles_with_missing_bins[bundle_name] = bmeta unless bins_exist
	}
}



if bundles_with_missing_bins.length > 0
	script_name = ""
	bundles_with_missing_bins.keys.each { |b| script_name += "build-#{b} / " }
	script_name.chomp!(' / ')
	error_log "Could not locate all binaries needed for deployment."
	error_log "Use '#{script_name}' to build the needed binaries."
end
if bundles_with_missing_assets.length > 0
	bundle_names = ""
	bundles_with_missing_assets.each_pair { |b,a| 
		error_log "Could not locate following assets for '#{b}':"
		a.each { |a| error_log "  #{a}" }
	}
end
exit_if_error



## list-deep, if requested ##
if requested_actions.include?(:list_deep)
	deploy_bundles.each_pair { |bundle_name, bmeta|
	
		puts "", "#{bundle_name}:"
		assets = bmeta[:assets]
		if assets[:files] != {}
			assets[:files].each { |asset_meta|
				puts "", "  assets.files:"
				puts     "    - #{asset_meta[:source]}"
			}
		end
		if assets[:dirs] != {}
			assets[:dirs].each { |asset_meta|
				puts "", "  assets.dirs:"
				puts     "    - #{asset_meta[:source]}"
			}
		end

		bmeta[:images].each_pair { |tname, bins|

			puts "", "  binaries:"
			bins.each { |bin_meta| 
				bin_name    = bin_meta[:source]
				bin_formats = bin_meta[:formats]
				message =  "    - #{bin_name}"
				message += " : #{bin_formats}" if bin_formats.length > 0
				puts message
			}
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

deploy_bundles.each_pair { |bundle_name, bmeta|

	bmeta[:images].each_pair { |tname, bins|

		bins.each { |bin_meta| 

			files_found = find_files bin_meta[:full_path], bin_meta[:formats], bin_meta[:base_path], bin_meta[:source], bin_meta[:destination]
			bin_meta[:files] = files_found
			
			if verbose
				file_count = files_found.length
				status     = "'#{bundle_name}/#{tname}/#{bin_meta[:source]}': found #{file_count} file" + (file_count > 1 || file_count == 0 ? "s" : "")
				puts status
			end
		}
	}
}



# copy each image to it's unique folder
file_counter  = 0
asset_counter = 0
deploy_bundles.each_pair { |bundle_name, bundle_meta|

	bundle_deploy_path = bundle_meta[:deploy_path]
	# clean existing deployment if it exists 
	FileUtils.rm_rf   bundle_deploy_path if Dir.exists? bundle_deploy_path
	FileUtils.mkdir_p bundle_deploy_path

	bundle_meta[:images].each_pair { |tname, bins|

		bins.each { |meta| 
			name  = meta[:source]
			files = meta[:files]
			next if files.length == 0

			# copy all images
			
			files.each { |fname, fmeta|
				deploy_rpath = fmeta[:deploy_rpath]
				source_file  = fmeta[:file]
				dest_path    = File.join bundle_deploy_path, "bins", deploy_rpath
				dest_file    = File.join dest_path, fname
				
				FileUtils.mkdir_p dest_path
				FileUtils.cp source_file, dest_file
				
				puts "deployed '#{source_file}' to '#{dest_file}'" if verbose
				file_counter += 1
			}
		}
	}

	if bundle_meta[:assets].length > 0
		bundle_meta[:assets][:dirs].each { |meta| 
			source         = meta[:full_path]
			destination    = meta[:destination]
			relative_path  = meta[:relative_path]
			dest_path_root = File.join bundle_deploy_path, "assets"
			dest_path      = File.join dest_path_root, relative_path

			FileUtils.mkdir_p dest_path_root
			FileUtils.mkdir_p dest_path
			FileUtils.cp_r    source, dest_path
			
			puts "deployed '#{source}' to '#{dest_path}'" if verbose
			asset_counter += 1
		}
		bundle_meta[:assets][:files].each { |meta| 
			source          = meta[:full_path]
			destination     = meta[:destination]
			relative_path   = meta[:relative_path]
			dest_path_root  = File.join bundle_deploy_path, "assets"
			dest_path       = File.join dest_path_root, relative_path

			FileUtils.mkdir_p dest_path_root
			FileUtils.mkdir_p dest_path
			FileUtils.cp      source, dest_path

			puts "deployed '#{source}' to '#{dest_path}'" if verbose
			asset_counter += 1
		}
	end
}

# generate meta files that describe the bundles
deploy_bundles.each_pair { |bundle_name, bundle_meta|

	deployed_bundle_meta = {}
	
	deployed_bundle_meta["name"]    = bundle_name
	deployed_bundle_meta["version"] = bundle_meta[:version]

	assets = []
	bundle_meta[:assets][:files].each { |meta| assets.push meta[:destination] }
	bundle_meta[:assets][:dirs].each  { |meta| assets.push meta[:destination] }

	targets = {}
	bundle_meta[:images].each_pair { |tname, bins|
		images = {}
		bins.each { |bmeta|
			name      = bmeta[:destination]
			image_map = {} 
			bmeta[:files].each_pair { |fname, fmeta|
				image_map[fname] = File.join "bins", fmeta[:deploy_rpath]
			}
			tmeta = targets[tname]
			tmeta = {} unless tmeta
			targets[tname] = tmeta.deep_merge( {name => image_map} )
		}
	}

	assets_deployed_list = []
	assets.each { |a| assets_deployed_list.push File.join("assets", a) }
	deployed_bundle_meta["assets"]  = assets_deployed_list
	deployed_bundle_meta["targets"] = targets

	file_name = File.join bundle_meta[:deploy_path], "bundle.yaml"
	create_file file_name, deployed_bundle_meta.to_yaml
}

summary = "deployed #{deploy_bundles.length} bundle#{deploy_bundles.length > 1 ? '' : 's'}."
summary = "\n" + summary + ". involving #{file_counter} file#{file_counter > 1 ? '' : 's'}." if verbose

puts summary
exit


deploy_bundles.each_pair { |bundle_name, bundle_meta|
	
	# map all the images to targets
	deployed_assets   = []
	targets_image_map = {}
	parsed_targets_repo.each_pair { |t, v|
	targets_image_map[t] = {} }
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
	if bundle_meta[:assets].length > 0
		bundle_meta[:assets][:dirs].each_pair  { |source, meta| deployed_assets.push meta[:destination] }
		bundle_meta[:assets][:files].each_pair { |source, meta| deployed_assets.push meta[:destination] }
	end

	final_targets_image_map = {}
	targets_image_map.each_pair { |t,m|
		next if m == {}
		final_targets_image_map[t] = m
	}

	deployed_bundle_meta = { "name" => bundle_name, "version" => bundle_meta[:version], "assets" => deployed_assets, "targets" => final_targets_image_map }

	file_name = File.join bundle_meta[:deploy_path], "bundle.yaml"
	create_file file_name, deployed_bundle_meta.to_yaml
}

summary = "deployed #{deploy_bundles.length} bundle#{deploy_bundles.length > 1 ? '' : 's'}."
summary = "\n" + summary + ". involving #{file_counter} file#{file_counter > 1 ? '' : 's'}." if verbose

puts summary
