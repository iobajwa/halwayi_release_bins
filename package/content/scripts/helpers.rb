def error_msg msg
	$encountered_error = true
	STDERR.puts msg
end
def error_log msg
	error_msg msg
end
def exit_if_error() exit(-1) if $encountered_error; end
def error msg, error_code=-1
	error_msg msg
	$error_callback.call if $error_callback
	exit error_code
end
class Symbol def with(*args, &block) ->(caller, *rest) { caller.send(self, *rest, *args, &block) } end end
class ::Hash def deep_merge(second) merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }; self.merge(second, &merger); end end
class String 
	def rchomp(sep=$/) self.start_with?(sep) ? self[sep.size..-1] : self end
	def lrchomp(sep)   rchomp(sep).chomp(sep) end
end
def create_file(name, contents) 
	dirname = File.dirname(name)
	unless File.directory?(dirname)
  		FileUtils.mkdir_p(dirname)
	end
	f = File.new(name, "w"); f.puts(contents);f.close(); 
end
def try_read_file(name) 
	return nil unless File.exists?(name)
	return File.readlines name
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
def string_to_lines(raw) raw.gsub("\r\n","\n").split("\n").map(&:strip) end
