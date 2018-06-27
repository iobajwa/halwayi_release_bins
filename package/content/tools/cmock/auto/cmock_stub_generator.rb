# ==========================================
#   CMock Project - Automatic Mock Generation for C
#   Copyright (c) 2007 Mike Karlesky, Mark VanderVoord, Greg Williams
#   [Released under MIT License. Please refer to license.txt for details]
# ==========================================

class CMockStubGenerator

  attr_accessor :config, :injected_functions, :mock_path

  def initialize(cfg)
    @config             = cfg
    @injected_functions = cfg.inject
    @mock_path          = cfg.mock_path
  end

  def create_stub(filename, source, parsed_stuff)
    return if injected_functions.length == 0

    define_name = "stub_" + filename
    define_name = define_name.gsub(/\.h/, "_h").upcase
    # source = source.force_encoding("ISO-8859-1").encode("utf-8", :replace => nil) if ($QUICK_RUBY_VERSION > 10900)

    full_file_name_temp = "#{@config.mock_path}/#{filename}"

    File.open(full_file_name_temp, 'w') do |file|
      file << "#ifndef _#{define_name}_H\n"
      file << "#define _#{define_name}_H\n\n"

      @config.treat_as_void.each {|i| 
        file << "#ifndef #{i}\n"
        declaration = sprintf("\t#define %-30s %s\n", i, "void")
        file << declaration
        file << "#endif\n"
      }
      file << "\n"

      file << source + "\n"
      parsed_stuff[:functions].each do  |function|                    # undef only the functions which were mocked so that
        name = function[:name]                                        # if they (read: injected functions) existed as macros
        file << "#undef #{name}\n"                                    # functions in original header, they are undefined
      end

      functions_to_declare = []
      injected_functions.each do  |func|
        words = func.split(' ')
        name = words[1].downcase       # take benifit of the fact that there will be a whitespace between return type and function name
        parsed_stuff[:functions].each {  |function| 
          next unless name == function[:name].downcase
          functions_to_declare.push func
        }
      end

      functions_to_declare.each {  |func| file << "\n" + func.strip }     # add the injected functions as forward declarations
      file << "\n\n" unless functions_to_declare.length == 0              # so that compiler doesn't generates warnings
      file << "#endif"
    end
  end
end
