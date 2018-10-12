require "timeout"
require "socket"
require "date"
require 'fileutils'

STDOUT.sync = true

usage_text = "
A simple utility to build features for one (or more) targets.

  build-all <target name(s):optional> <flags: optional>

Builds all targets if none are specified.

  options: 
    
    --timeout       : for each build (in seconds)
                      default: 40
                      aliases: -t

    --path          : the path to keep build logs
                      default: $build_root/etc
                      aliases: -p

    --list          : lists the features that will be built for the specified (or all) targets(s)
                      aliases: -l, --ld

    --help          : -_-
                      aliases: -h, ?, -?, --?
"

def string_to_lines(raw) raw.gsub("\r\n","\n").split("\n").map(&:strip) end
def error_log(msg) STDERR.puts(msg); $encountered_error=true end
def exit_if_error() exit(-1) if $encountered_error; end
def error(msg,error_code=-1) error_log(msg); exit(error_code); end
	class ToolException < Exception
end
def create_file(name, contents) f = File.new(name, "w"); f.puts(contents);f.close(); end
class Tree
	attr_accessor :name, :delimiter, :nodes
	def initialize name='tree', delimiter='/'
		@name      = name
		@delimiter = delimiter
		@nodes     = []
	end
	def get_node name
		nodes.each { |n| return n if n.name == name }
		return nil
	end
	def create_node name
		n = Node.new name
		nodes.push n
		return n
	end
	def get_leaf complete_name
		elements = complete_name.split delimiter
		leaf  = nil
		first = elements.shift
		raise ToolException.new "node not found '#{first}'" unless first
		leaf = get_node first
		elements.each { |e|
			leaf = leaf.get_child e
			raise ToolException.new "leaf not found '#{e}'" unless leaf
		}
		return leaf
	end
	def Tree.populate name, dataset, delimiter='/'
		tree = Tree.new name, delimiter
		dataset.each { |d|
			elements = d.split delimiter
			root = elements.shift
			node = tree.get_node root
			node = tree.create_node root unless node
			elements.each { |e|
				child = node.get_child e
				child = node.create_child e unless child
				node = child
			}
		}
		return tree
	end
	def Tree.get_all_unique_namespace_combinations dataset, delimiter='/'
		combinations = []
		dataset.each { |d|
			elements = d.split delimiter
			root = elements.shift
			combinations.push root unless combinations.include?(root)
			elements.each { |e|
				root = root + "/" + e
				combinations.push root unless combinations.include?(root)
			}
		}
		return combinations
	end
	def Tree.get_root_namespaces dataset, delimiter='/'
		namespaces = []
		dataset.each { |d|
			elements = d.split delimiter
			root     = elements.shift
			namespaces.push root unless namespaces.include?(root)
		}
		return namespaces
	end
	def to_s
		result = "#{@name}\n"
		nodes.each { |n| result += "\t+ #{n.to_s}\n" }
		return result.chomp('\n')
	end
end
class Node
	attr_accessor :name, :meta, :children
	def initialize name='', meta={}, children=[]
		@name     = name
		@meta     = meta
		@children = children
	end
	def is_leaf?
		return children == nil || children.length == 0
	end
	def has_child? name
		return get_child(name) ? true : false
	end
	def get_child name
		children.each { |c| return c if c.name == name }
		return nil
	end
	def create_child name
		n = Node.new name
		children.push n
		return n
	end
	def get_aggregated_meta
		meta_array = []
		meta_array.push meta unless meta == {}
		children.each { |c|
			child_meta = c.get_aggregated_meta
			meta_array.push(child_meta) unless child_meta == []
		}
		return meta_array.flatten
	end
	def to_s tab_space=2
		result = "#{name}\n"
		tabbing = "\t" * tab_space
		children.each { |c| result += "#{tabbing}- #{c.to_s(tab_space + 1)}\n" }
		return result.chomp
	end
end


# 
# start
# 

# parse, sanity check and sanitize the command line args
requested_actions = {}
targets_filtered  = []
output_path       = nil
report_file       = nil
build_timeout     = 40
spawn_time        = Time.now.strftime("%H:%M:%S")
spawn_date        = Date.today
skip = false
ARGV.each_with_index { |e, i|
	if skip
		skip = false
		next
	end
	case e.gsub(/^[-]*/, '').gsub('-', '_')
	# when "b", "build_scripts"
	# 	requested_actions[:gen_scripts] = true
	when "t", "timeout"
		build_timeout = ARGV[i + 1].to_i
		skip = true
	# when "l", "list"
	# 	requested_actions[:list] = true
	when "p", "path"
		output_path = ARGV[i + 1]
		skip = true
	when "r", "report_file"
		report_file = ARGV[i + 1]
		skip = true
	when "?", "h", "help"
		puts usage_text
		exit
	else
		targets_filtered.push e
	end
}

## discover the environment ##
project_root       = ENV['ProjectRoot']
artifacts_root     = ENV['ArtifactsRoot']
# sanity check
error "ProjectRoot not defined."                                  unless project_root
error "ArtifactsRoot not defined."                                unless artifacts_root
error "Invalid value specified for timeout ('#{build_timeout}')." unless build_timeout.class == Fixnum and build_timeout > 0
unless output_path
	puts "no deploy path provided, using default"
	output_path = File.join artifacts_root, "etc"
	# create the root deploy directory unless it exists
	FileUtils.mkdir_p output_path unless Dir.exists? output_path
end
# ensure the paths exist
error "path doesn't exist: '#{output_path}'" unless Dir.exist? output_path
# sanitize
project_root   = project_root.gsub('\\', '/')
artifacts_root = artifacts_root.gsub('\\', '/')
output_path    = output_path.gsub('\\', '/')
# print the environment
report_file = File.join artifacts_root, "build-all-results.xml" unless report_file
puts "project root       : #{project_root}"
puts "artifacts root     : #{artifacts_root}"
puts "output path        : #{output_path}"
puts "output report path : #{report_file}"



# get a list of all targets
target_list  = string_to_lines `list target_names`
project_name = string_to_lines(`list project_name`)[0]

puts "complete target list is #{target_list}"

# get a list of features specific to each target
targets_features_list = {}
target_list.each { |tname|
	next if targets_filtered.length > 0 && !targets_filtered.include?(tname)
	raw_output        = `set target=#{tname} && list features`
	features_to_build = []
	lines             = string_to_lines raw_output
	lines             = lines[1..lines.length-1]
	found_marker = false
	lines.each { |line|
		unless found_marker
			puts "skipping : #{line}"
			found_marker = true if line =~ /by naming/i
			next
		end
		next if line =~ /convention/i
		l = line.strip
		next if l == ""
		name = File.basename(l)
		next if name.start_with? '_' or name.end_with? '_'
		features_to_build.push "#{l}"
	}
	targets_features_list[tname] = features_to_build
}

# create a mental model of everything- target trees, unique namespace lists, etc.
targets = {}
targets_features_list.each_pair { |tname, feature_list|
	tree              = Tree.populate tname, feature_list
	unique_namespaces = Tree.get_all_unique_namespace_combinations feature_list
	root_namespaces   = Tree.get_root_namespaces feature_list
	targets[tname] = { :tname => tname, :tree => tree, :features => feature_list, :root_namespaces => root_namespaces, :unique_namespaces => unique_namespaces }
}

puts "filtered target list is '#{targets_features_list.keys}'"


# build all targets and gather reports
total_build_count    = 0
total_passed_count   = 0
total_failed_count   = 0
total_timedout_count = 0
total_time           = 0
targets.each_pair { |tname, tmeta|

	puts "building all features for '#{tname}' target.."
	tree         = tmeta[:tree]
	feature_list = tmeta[:features]

	target_total_build_count    = 0
	target_total_passed_count   = 0
	target_total_failed_count   = 0
	target_total_timedout_count = 0
	target_total_build_time     = 0

	feature_list.each { |feature_name|

		feature_name_transformed = feature_name.gsub('/', '.') + ".build-output.txt"
		output_file = File.join output_path, feature_name_transformed
		puts "building '#{feature_name}' feature"
		puts "output: #{output_file}"

		exit_code = build_result = nil
		start_time = Time.now

		pid = Process.spawn "build #{tname} #{feature_name} > #{output_file} 2>&1"
		begin
			Timeout.timeout build_timeout do
				puts "building.."
				Process.wait pid
				exit_code    = $?.exitstatus
				build_result = exit_code == 0 ? :passed : :failed
				puts "build finished: (result: #{build_result}, exit_code: #{exit_code})"
			end
		rescue Timeout::Error
			puts "build timedout, killing it.."
			system "taskkill /f /t /pid #{pid}"
			exit_code    = -1
			build_result = :timedout
		end

		# build completed, capture report
		output     = File.exist?(output_file) ? File.readlines(output_file) : []
		build_time = Time.now - start_time

		feature_node = tree.get_leaf feature_name
		feature_node.meta = { :time => build_time, :result => build_result, :exit_code => exit_code, :output => output }
		if build_result == :passed
			target_total_passed_count += 1
		elsif build_result == :failed
			target_total_failed_count += 1
		else
			target_total_timedout_count += 1
		end
		target_total_build_count += 1
		target_total_build_time  += build_time
	}
	
	tmeta[:build] = { 
					  :time           => target_total_build_time,
					  :total_count    => target_total_build_count,
					  :passed_count   => target_total_passed_count, 
					  :failed_count   => target_total_failed_count,
					  :timedout_count => target_total_timedout_count,
					}
	total_passed_count   += target_total_passed_count
	total_failed_count   += target_total_failed_count
	total_timedout_count += target_total_timedout_count
	total_build_count    += target_total_build_count
	total_time           += target_total_build_time
}

# render the report to compatible test report
puts ""
puts "summary"
puts "   total: #{total_build_count}  succeeded: #{total_passed_count}  failed: #{total_failed_count}  timedout: #{total_timedout_count}"
puts "   took #{total_time} seconds"
puts ""
puts "creating report.."

def compute_build_status_counts aggregated_meta
	passed_count, failed_count, timedout_count, total_time = 0, 0, 0, 0
	aggregated_meta.each { |m|
		passed_count   += 1 if m[:result] == :passed
		failed_count   += 1 if m[:result] == :failed
		timedout_count += 1 if m[:result] == :timedout
		total_time     += m[:time]
	}
	return passed_count, failed_count, timedout_count, total_time
end
def success_status_to_s passed_count, failed_count, timedout_count
	return "False" if failed_count > 0 or timedout_count > 0
	return "True"
end
def build_result_status_to_s passed_count, failed_count, timedout_count
	return "Failure" if failed_count > 0 or timedout_count > 0
	return "Success"
end
def node_generate_report node, namespace, starting_tab, tab_space
	results = []
	meta = node.get_aggregated_meta
	name = node.name
	node_passed_count, node_failed_count, node_timedout_count, node_time = compute_build_status_counts meta
	node_status       = success_status_to_s node_passed_count, node_failed_count, node_timedout_count
	node_build_result = build_result_status_to_s node_passed_count, node_failed_count, node_timedout_count
	node_namespace    = namespace + "." + node.name
	if node.is_leaf?
		results.push( starting_tab + tab_space + "<test-case time=\"#{node_time}\" name=\"#{node_namespace}\" asserts=\"1\" success=\"#{node_status}\" result=\"#{node_build_result}\" executed=\"True\" />" )
	else
		results.push( starting_tab + tab_space + "<test-suite time=\"#{node_time}\" name=\"#{name}\" asserts=\"0\" success=\"#{node_status}\" result=\"#{node_build_result}\" executed=\"True\" type=\"Namespace\">" )
		results.push( starting_tab + tab_space + tab_space + "<results>")
		new_tab = starting_tab + tab_space + tab_space
		node.children.each { |c| results.push node_generate_report c, node_namespace, new_tab, tab_space }
		results.push( starting_tab + tab_space + tab_space +"</results>")
		results.push( starting_tab + tab_space + "</test-suite>" )
	end
	return results.flatten
end

project_status       = success_status_to_s total_passed_count, total_failed_count, total_timedout_count
project_build_result = build_result_status_to_s total_passed_count, total_failed_count, total_timedout_count
machine_name         = Socket.gethostname
test_results_header  = "<test-results time=\"#{spawn_time}\" date=\"#{spawn_date}\" invalid=\"0\" skipped=\"0\" ignored=\"0\" inconclusive=\"#{total_timedout_count}\" not-run=\"0\" failures=\"#{total_failed_count}\" errors=\"0\" total=\"#{total_build_count}\" name=\"#{project_name}\">"
env_header           = "  <environment nunit-version=\"2.6.2.12296\" clr-version=\"2.0.50727.4927\" os-version=\"Microsoft Windows NT 6.2.9200.0\" platform=\"Win32NT\" cwd=\"#{Dir.pwd}\" machine-name=\"#{machine_name}\" user=\"#{ENV['USERNAME']}\" user-domain=\"#{machine_name}\"/>"
report_contents = [
	'<?xml version="1.0" encoding="UTF-8"?>',
	"<!--This file contains the results of running a build-all command.-->",
	test_results_header, 
	env_header,
	"  <culture-info current-culture=\"en-US\" current-uiculture=\"en-US\"/>",
	"  <test-suite time=\"#{total_time}\" name=\"#{project_name}\" asserts=\"0\" success=\"#{project_status}\" result=\"#{project_build_result}\" executed=\"True\" type=\"Assembly\">",
	"    <results>",
]
project_namespace = project_name
targets.each { |tname, tmeta|

	target_time     = tmeta[:build][:time]
	target_total    = tmeta[:build][:total_count]
	target_passed   = tmeta[:build][:passed_count]
	target_failed   = tmeta[:build][:failed_count]
	target_timedout = tmeta[:build][:timedout_count]
	target_status       = success_status_to_s target_passed, target_failed, target_timedout
	target_build_result = build_result_status_to_s target_passed, target_failed, target_timedout
	report_contents.push "      <test-suite time=\"#{target_time}\" name=\"#{tname}\" asserts=\"0\" success=\"#{target_status}\" result=\"#{target_build_result}\" executed=\"True\" type=\"Namespace\">"
	report_contents.push "        <results>"
	tree            = tmeta[:tree]
	root_namespaces = tmeta[:root_namespaces]
	namespaces      = tmeta[:unique_namespaces]

	root_namespaces.each { |n| 
		node = tree.get_node n
		report_contents.push node_generate_report node, "#{project_namespace}.#{tname}", "        ",  "  "
	}

	report_contents.push "        </results>"
	report_contents.push "      </test-suite>"
}
report_contents.push [
	"    </results>",	
	"  </test-suite>",
	"</test-results>"]

create_file report_file, report_contents.flatten
puts "done."
# now build each feature for each target and capture the data
# 	build-time
#   build-result: passed, failed, timedout

# puts targets_features


# finally render all the information to xml
