require "timeout"
require "socket"
require "date"
require 'fileutils'
require_relative 'halwayi'
require_relative 'helpers'

STDOUT.sync = true

usage_text = "
A simple utility to build features for one (or more) targets.

  build-all <target name(s):optional> <flags: optional>

Builds all targets if none are specified.

  options: 
    
    --targets       : builds only the specified targets
                      aliases: --target, -t
                      default: <all-targets>

    --ignore_targets : ignores the specified target(s)
                      aliases: --ignore_target, -T
                      default: <none>

    --features      : builds only the specified features
                      aliases: --feature, -f
                      default: <all-features>

    --ignore_features : ignores the specified feature(s)
                      aliases: --ignore_feature, -i
                      default: <none>

    --timeout       : for each build (in seconds)
                      default: 40
                      aliases: -m

    --path          : the path to write build logs
                      default: $build_root/etc
                      aliases: -o

    --report_file   : filename to write the nunit compatible xml report file
                      default: build-all-results.xml
                      aliases: -r

    --verbose       : aliases: -v

    --help          : -_-
                      aliases: -h, ?, -?, --?
"

# --list          : lists the features that will be built for the specified
#                   target/feature flags
#                   aliases: -l, --ld


class ToolException < Exception
end
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
class Array
	def glob_include? input, array_has_globs=false
		if array_has_globs
			self.each { |glob| return true if File.fnmatch(glob, input) }
		else
			glob = input
			self.each { |i| return true if File.fnmatch(glob, i) }
		end
		return false
	end
	def include? glob
		self.each { |i| return true if File.fnmatch(glob, i) }
		return false
	end
	def match_glob glob
		results = []
		self.each { |i| results.push i if File.fnmatch(glob, i) }
		return results
	end
end


# 
# start
# 

puts ""
# parse, sanity check and sanitize the command line args
def parse_arg_list args, index
	args_parsed = []
	args[index..args.length].each { |v|
		v = v.dup.strip
		break if v.start_with? '-' or v == "?"
		next if v == ";"
		v.split(';').map(&:strip).each { |glob| args_parsed.push glob.gsub('\\', '/') }
	}
	return args_parsed
end
# requested_actions = {}
targets_accept_filter  = []
targets_ignore_filter  = []
features_accept_filter = []
features_ignore_filter = []
output_path       = nil
report_file       = nil
verbose           = false
build_timeout     = 40
spawn_time        = Time.now.strftime("%H:%M:%S")
spawn_date        = Date.today
skip = 0
ARGV.each_with_index { |e, i|
	if skip > 0
		skip -= 1
		next
	end
	case e.gsub(/^[-]*/, '').gsub('-', '_')
	when "m", "timeout"
		build_timeout = ARGV[i + 1].to_i
		skip = 1
	# when "l", "list"
	# 	requested_actions[:list] = true
	when "o", "path"
		output_path = ARGV[i + 1]
		skip = 1
	when "r", "report_file"
		report_file = ARGV[i + 1]
		skip = 1
	when "features", "f", "feature"
		features_parsed = parse_arg_list ARGV, i + 1
		skip += features_parsed.length
		features_accept_filter.push features_parsed
	when "ignore_features", "i", "ignore_feature"
		features_parsed = parse_arg_list ARGV, i + 1
		skip += features_parsed.length
		features_ignore_filter.push features_parsed
	when "targets", "t", "target"
		targets_parsed = parse_arg_list ARGV, i + 1
		skip += targets_parsed.length
		targets_accept_filter.push targets_parsed
	when "ignore_targets", "T", "ignore_target"
		targets_parsed = parse_arg_list ARGV, i + 1
		skip += targets_parsed.length
		targets_ignore_filter.push targets_parsed
	when "verbose", "v"
		verbose = true
	when "?", "h", "help"
		puts usage_text
		exit
	else
		error "'#{e}' ?"
	end
}
features_accept_filter.flatten!
features_ignore_filter.flatten!
targets_accept_filter.flatten!
targets_ignore_filter.flatten!


# sanity check
report_file = File.join art_root, "build-all-results.xml" unless report_file
error "Invalid value specified for timeout ('#{build_timeout}')."  unless build_timeout.class == Fixnum and build_timeout > 0
unless output_path
	puts "no output path provided, using default" if verbose
	output_path = etc_root
	FileUtils.mkdir_p output_path unless Dir.exists? output_path
end
# ensure the paths exist
error "path doesn't exist: '#{output_path}'" unless Dir.exist? output_path
File.delete report_file if File.exist? report_file
# sanitize
output_path = output_path.gsub('\\', '/')
# print the environment
puts "project root       : #{project_root}"
puts "artifacts root     : #{art_root}"
puts "output path        : #{output_path}"
puts "output report path : #{report_file}"



# get a list of all targets
puts ""
puts "complete target list is #{target_names} (#{target_names.length})"
puts "target acceptance filter list is #{targets_accept_filter} (#{targets_accept_filter.length})"    if targets_accept_filter.length  > 0
puts "target ignore filter list is #{targets_ignore_filter} (#{targets_ignore_filter.length})"        if targets_ignore_filter.length  > 0
puts "feature acceptance filter list is #{features_accept_filter} (#{features_accept_filter.length})" if features_accept_filter.length > 0
puts "feature ignore filter list is #{features_ignore_filter} (#{features_ignore_filter.length})"     if features_ignore_filter.length > 0
# get a list of features specific to each target
total_feature_count   = 0
targets_features_list = {}
target_names.each { |tname|
	next if (targets_accept_filter.length > 0 && !targets_accept_filter.glob_include?(tname, true)) || (targets_ignore_filter.glob_include?(tname, true))
	features_to_build = []
	all_features = Halwayi.features tname
	all_features.each { |f| 
		next if (features_accept_filter.length > 0 && !features_accept_filter.glob_include?(f, true)) || (features_ignore_filter.glob_include?(f, true))
		features_to_build.push f
	}
	error "#{tname}: no feature to build"                                if features_to_build.length == 0
	puts  "#{tname}: #{features_to_build} (#{features_to_build.length})" if verbose
	targets_features_list[tname] = features_to_build
	total_feature_count += features_to_build.length
}

# create a mental model of everything- target trees, unique namespace lists, etc.
targets = {}
targets_features_list.each_pair { |tname, feature_list|
	tree              = Tree.populate tname, feature_list
	unique_namespaces = Tree.get_all_unique_namespace_combinations feature_list
	root_namespaces   = Tree.get_root_namespaces feature_list
	targets[tname] = { :tname => tname, :tree => tree, :features => feature_list, :root_namespaces => root_namespaces, :unique_namespaces => unique_namespaces, features_failed: [], features_timedout: [] }
}

puts ""
puts "filtered target list is #{targets_features_list.keys} (#{targets_features_list.keys.length})"
puts ""

def calculate_etd_seconds time_consumed_so_far, total_feature_count, feature_count_built_so_far
	return "unknown" if feature_count_built_so_far == 0
	average_time            = time_consumed_so_far / feature_count_built_so_far
	feature_count_remaining = total_feature_count - feature_count_built_so_far 
	etd                     = average_time * feature_count_remaining
	return etd
end

# build all targets and gather reports
total_build_count    = 0
total_passed_count   = 0
total_failed_count   = 0
total_timedout_count = 0
total_time           = 0
targets.each_pair { |tname, tmeta|

	tree         = tmeta[:tree]
	feature_list = tmeta[:features]

	puts "#{tname}: #{feature_list.length} feature#{feature_list.length > 1 ? 's' : ''}"
	target_total_build_count    = 0
	target_total_passed_count   = 0
	target_total_failed_count   = 0
	target_total_timedout_count = 0
	target_total_build_time     = 0

	feature_list.each { |feature_name|

		feature_name_transformed = tname + '.' + feature_name.gsub('/', '.') + ".build-output.txt"
		output_file = File.join output_path, feature_name_transformed
		puts "", "    building : #{feature_name}"
		puts "    output   : #{output_file}", ""

		exit_code  = build_result = nil
		start_time = Time.now

		pid = Process.spawn "build target #{tname} #{feature_name} > #{output_file} 2>&1"
		begin
			Timeout.timeout build_timeout do
				print "    building : "
				Process.wait pid
				exit_code    = $?.exitstatus
				build_result = exit_code == 0 ? :passed : :failed
			end
		rescue Timeout::Error
			puts "timedout, killing it.."
			system "taskkill /f /t /pid #{pid}"
			exit_code    = -1
			build_result = :timedout
		end

		output       = File.exist?(output_file) ? File.readlines(output_file) : []
		build_time   = Time.now - start_time
		feature_node = tree.get_leaf feature_name
		feature_node.meta = { :time => build_time, :result => build_result, :exit_code => exit_code, :output => output }
		
		target_total_passed_count   += 1 if build_result == :passed
		target_total_failed_count   += 1 if build_result == :failed
		target_total_timedout_count += 1 if build_result == :timedout
		target_total_build_count    += 1
		target_total_build_time     += build_time

		tmeta[:features_failed].push   feature_name if build_result == :failed
		tmeta[:features_timedout].push feature_name if build_result == :timedout

		# build completed, capture report
		print "#{build_result}" + (build_result == :passed ? "" : " (#{exit_code})") + (build_result != :timedout ? ", took #{"%.3f" % build_time} seconds" : "") unless build_result == :timedout
		etd_seconds = calculate_etd_seconds total_time + target_total_build_time + build_time, total_feature_count, total_build_count + target_total_build_count + 1
		puts "    #{target_total_failed_count} / #{target_total_build_count} / #{feature_list.length}  (failed / built / total)"
		puts "    ETD      : #{etd_seconds=='unknown' ? '' : '~'}#{etd_seconds.round}#{ etd_seconds=='unknown' ? '.' : ' seconds'}"
		puts "    "
	}
	
	puts "  #{target_total_build_count} built, #{target_total_passed_count} succeeded."
	puts "  took #{"%.3f" % target_total_build_time} seconds."
	puts ""
	
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

# print summary
puts ""
puts "summary:"
targets.each_pair { |tname, tmeta|
	if tmeta[:features_failed].length > 0 or tmeta[:features_timedout].length > 0
		puts "", "  #{tname} failures:"
		tmeta[:features_failed].each   { |f| puts "    - #{f}" }
		tmeta[:features_timedout].each { |f| puts "    - #{f} (TIMEDOUT)" }
		puts ""
	end
}
puts "  total: #{total_build_count}  succeeded: #{total_passed_count}  failed: #{total_failed_count}  timedout: #{total_timedout_count}"
puts "  took #{"%.3f" % total_time} seconds"
puts ""

# render the report to compatible test report
puts "generating report.."

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
	node_status       = success_status_to_s      node_passed_count, node_failed_count, node_timedout_count
	node_build_result = build_result_status_to_s node_passed_count, node_failed_count, node_timedout_count
	node_namespace    = namespace + "." + node.name
	if node.is_leaf?
		if node_build_result == "Success"
			results.push( starting_tab + tab_space + "<test-case time=\"#{node_time}\" name=\"#{node_namespace}\" asserts=\"1\" success=\"#{node_status}\" result=\"#{node_build_result}\" executed=\"True\" />" )
		else
			failure_message   = node_timedout_count > 0 ? "build timedout" : "build failed"
			node_build_output = "\n\r"
			node.meta[:output].each { |l| node_build_output += l }
			leaf_results = [
							 starting_tab + tab_space + "<test-case time=\"#{node_time}\" name=\"#{node_namespace}\" asserts=\"1\" success=\"#{node_status}\" result=\"#{node_build_result}\" executed=\"True\">",
							 starting_tab + tab_space + tab_space + "<failure>",
							 starting_tab + tab_space + tab_space + tab_space + "<message>",
							 starting_tab + tab_space + tab_space + tab_space + tab_space + "<![CDATA[#{failure_message}]]>",
							 starting_tab + tab_space + tab_space + tab_space + "</message>",
							 starting_tab + tab_space + tab_space + tab_space + "<stack-trace>",
							 starting_tab + tab_space + tab_space + tab_space + tab_space + "<![CDATA[#{node_build_output}]]>",
							 starting_tab + tab_space + tab_space + tab_space + "</stack-trace>",
							 starting_tab + tab_space + tab_space + "</failure>",
							 starting_tab + tab_space + "</test-case>",
						   ]
	   		results.push leaf_results
		end
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

project_status       = success_status_to_s      total_passed_count, total_failed_count, total_timedout_count
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
	"      <test-suite time=\"#{total_time}\" name=\"features\" asserts=\"0\" success=\"#{project_status}\" result=\"#{project_build_result}\" executed=\"True\" type=\"Assembly\">",
	"      <results>",
]
project_namespace = project_name
targets.each { |tname, tmeta|

	target_time     = tmeta[:build][:time]
	target_total    = tmeta[:build][:total_count]
	target_passed   = tmeta[:build][:passed_count]
	target_failed   = tmeta[:build][:failed_count]
	target_timedout = tmeta[:build][:timedout_count]
	target_status       = success_status_to_s      target_passed, target_failed, target_timedout
	target_build_result = build_result_status_to_s target_passed, target_failed, target_timedout
	report_contents.push "        <test-suite time=\"#{target_time}\" name=\"#{tname}\" asserts=\"0\" success=\"#{target_status}\" result=\"#{target_build_result}\" executed=\"True\" type=\"Namespace\">"
	report_contents.push "          <results>"
	tree            = tmeta[:tree]
	root_namespaces = tmeta[:root_namespaces]
	namespaces      = tmeta[:unique_namespaces]

	root_namespaces.each { |n| 
		node = tree.get_node n
		report_contents.push node_generate_report node, "#{project_namespace}.features.#{tname}", "            ",  "  "
	}

	report_contents.push "          </results>"
	report_contents.push "        </test-suite>"
}
report_contents.push [
	"        </results>",
	"      </test-suite>",
	"    </results>",	
	"  </test-suite>",
	"</test-results>"]


create_file report_file, report_contents.flatten

puts "done."

exit_code = total_build_count - total_passed_count
exit exit_code
