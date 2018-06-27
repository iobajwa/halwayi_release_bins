# ==========================================
#   CMock Project - Automatic Mock Generation for C
#   Copyright (c) 2007 Mike Karlesky, Mark VanderVoord, Greg Williams
#   [Released under MIT License. Please refer to license.txt for details]
# ==========================================

class CMockHeaderParser

  attr_accessor :funcs, :c_attributes, :treat_as_void, :treat_externs, :ignored_functions, :inject_functions, :mock_only_functions, :externd_variables

  def initialize(cfg)
    @funcs = []
    @c_strippables = cfg.strippables
    @c_attributes = (['const'] + cfg.attributes).uniq
    @c_calling_conventions = cfg.c_calling_conventions.uniq
    @treat_as_void = (['void'] + cfg.treat_as_void).uniq
    @declaration_parse_matcher = /([\d\w\s\*\(\),\[\]]+??)\(([\d\w\s\*\(\),\.\[\]+-]*)\)$/m
    @standards = (['int','short','char','long','unsigned','signed'] + cfg.treat_as.keys).uniq
    @when_no_prototypes = cfg.when_no_prototypes
    @local_as_void = @treat_as_void
    @verbosity = cfg.verbosity
    @treat_externs = cfg.treat_externs
    @c_strippables += ['extern'] if (@treat_externs == :include) #we'll need to remove the attribute if we're allowing externs
    @ignored_functions = cfg.ignore
    @inject_functions = cfg.inject
    @mock_only_functions = cfg.only
  end

  def parse(name, source)
    inject_functions.each {|func| source << func + "\n" }
    @module_name = name.gsub(/\W/,'')
    @typedefs = []
    @funcs = []
    function_names = ignored_functions

    source = import_source(source);
    parse_functions( source ).map do |decl|
      func = parse_declaration(decl)
      unless (function_names.include? func[:name])
        @funcs << func
        function_names << func[:name]
      end
    end

    unfiltered_functions = @funcs
    unless (@mock_only_functions.empty?) then
      @mock_only_functions.each { |func| func.downcase! }
      filtered_functions = []
      @funcs.each {|func| filtered_functions.push func if (@mock_only_functions.include?(func[:name].downcase)) }
      @funcs = filtered_functions
    end

    { :includes  => nil,
      :functions => @funcs,
      :typedefs  => @typedefs,
      :unfiltered_functions => unfiltered_functions,
      :externd_variables => @externd_variables,
    }
  end

  private if $ThisIsOnlyATest.nil? ################

  def import_source(source)

    # let's clean up the encoding in case they've done anything weird with the characters we might find
    source = source.force_encoding("ISO-8859-1").encode("utf-8", :replace => nil) if ($QUICK_RUBY_VERSION > 10900)

    # void must be void for cmock _ExpectAndReturn calls to process properly, not some weird typedef which equates to void
    # to a certain extent, this action assumes we're chewing on pre-processed header files, otherwise we'll most likely just get stuff from @treat_as_void
    @local_as_void = @treat_as_void
    void_types = source.scan(/typedef\s+(?:\(\s*)?void(?:\s*\))?\s+([\w\d]+)\s*;/)
    if void_types
      @local_as_void += void_types.flatten.uniq.compact
    end

    # smush multiline macros into single line (checking for continuation character at end of line '\')
    source.gsub!(/\s*\\\s*/m, ' ')

    #remove comments (block and line, in three steps to ensure correct precedence)
    source.gsub!(/\/\/(?:.+\/\*|\*(?:$|[^\/])).*$/, '')  # remove line comments that comment out the start of blocks
    source.gsub!(/\/\*.*?\*\//m, '')                     # remove block comments
    source.gsub!(/\/\/.*$/, '')                          # remove line comments (all that remain)

    # remove assembler pragma sections
    source.gsub!(/^\s*#\s*pragma\s+asm\s+.*?#\s*pragma\s+endasm/m, '')

    # remove gcc's __attribute__ tags
    source.gsub!(/__attribute(?:__)?\s*\(\(+.*\)\)+/, '')

    # remove preprocessor statements and extern "C"
    source.gsub!(/^\s*#.*/, '')
    source.gsub!(/extern\s+\"C\"\s+\{/, '')

    # enums, unions, structs, and typedefs can all contain things (e.g. function pointers) that parse like function prototypes, so yank them
    # forward declared structs are removed before struct definitions so they don't mess up real thing later. we leave structs keywords in function prototypes
    source.gsub!(/^[\w\s]*struct[^;\{\}\(\)]+;/m, '')                                      # remove forward declared structs
    source.gsub!(/^[\w\s]*(enum|union|struct|typepdef)[\w\s]*\{[^\}]+\}[\w\s\*\,]*;/m, '') # remove struct, union, and enum definitions and typedefs with braces
    source.gsub!(/(\W)(?:register|auto|static|restrict)(\W)/, '\1\2')                      # remove problem keywords
    source.gsub!(/\s*=\s*['"a-zA-Z0-9_\.]+\s*/, '')                                        # remove default value statements from argument lists
    source.gsub!(/^(?:[\w\s]*\W)?typedef\W[^;]*/m, '')                                     # remove typedef statements
    source.gsub!(/\)(\w)/, ') \1')                                                         # add space between parenthese and alphanumeric
    @externd_variables = parse_externd_variables(source)
    source.gsub!(/(^|\W+)(?:#{@c_strippables.join('|')})(?=$|\W+)/,'\1') unless @c_strippables.empty? # remove known attributes slated to be stripped

    #scan for functions which return function pointers, because they are a pain
    source.gsub!(/([\w\s\*]+)\(*\(\s*\*([\w\s\*]+)\s*\(([\w\s\*,]*)\)\)\s*\(([\w\s\*,]*)\)\)*/) do |m|
      functype = "cmock_#{@module_name}_func_ptr#{@typedefs.size + 1}"
      @typedefs << "typedef #{$1.strip}(*#{functype})(#{$4});"
      "#{functype} #{$2.strip}(#{$3});"
    end

    #drop extra white space to make the rest go faster
    source.gsub!(/^\s+/, '')          # remove extra white space from beginning of line
    source.gsub!(/\s+$/, '')          # remove extra white space from end of line
    source.gsub!(/\s*\(\s*/, '(')     # remove extra white space from before left parens
    source.gsub!(/\s*\)\s*/, ')')     # remove extra white space from before right parens
    source.gsub!(/\s+/, ' ')          # remove remaining extra white space

    #split lines on semicolons and remove things that are obviously not what we are looking for
    src_lines = source.split(/\s*;\s*/)
    src_lines.delete_if {|line| line.strip.length == 0}                            # remove blank lines
    src_lines.delete_if {|line| !(line =~ /[\w\s\*]+\(+\s*\*[\*\s]*[\w\s]+(?:\[[\w\s]*\]\s*)+\)+\s*\((?:[\w\s\*]*,?)*\s*\)/).nil?}     #remove function pointer arrays
    if (@treat_externs == :include)
      src_lines.delete_if {|line| !(line =~ /(?:^|\s+)(?:inline)\s+/).nil?}        # remove inline functions
    else
      src_lines.delete_if {|line| !(line =~ /(?:^|\s+)(?:extern|inline)\s+/).nil?} # remove inline and extern functions
    end
    src_lines.delete_if {|line| !(line =~ /\{/).nil? }  # remove lines with opening braces { because this isn't a declaration, it's a definition!
    src_lines.map!{|line| line.gsub(/.*\}/,'')} #remove braces left at the beginning of lines
    src_lines.delete_if {|line| line.empty? } #drop empty lines
  end

  def parse_externd_variables(source)
    source = source.split(/\s*;\s*/)
    vars   = []
    source.each {  |line|
      line = line.strip
      if line.start_with?("extern") && !line.include?('(')
        
        declaration = line[6..line.length].strip 
        next if declaration.include?('[]')
        
        var               = {}
        var[:declaration] = declaration + ";"
        words             = declaration.split(/\W+/)
        next if words.include? "const"
        # var[:is_const]    = words.include? "const"
        # words.delete_if {  |w| w == "const" }
        # words.delete_if {  |w| w == "volatile" }
        var[:is_array]    = declaration.include?('[')
        words.pop if var[:is_array]
        var[:name]          = words.pop
        var[:type_elements] = words
        
        combined_type = ""
        words.each {  |w| combined_type += w + " " }
        
        var[:type]        = combined_type.strip!
        var[:simple_type] = is_known_simple_type(combined_type) || declaration.include?('*')
        var[:is_ptr]      = declaration.include?('*')
        vars.push var
      end
    }
    return vars
  end

  def is_known_simple_type(type)
    types = {
      'int'             => 'INT',
      'char'            => 'INT8',
      'short'           => 'INT16',
      'long'            => 'INT',
      'int8'            => 'INT8',
      'int16'           => 'INT16',
      'int32'           => 'INT',
      'int8_t'          => 'INT8',
      'int16_t'         => 'INT16',
      'int32_t'         => 'INT',
      'INT8_T'          => 'INT8',
      'INT16_T'         => 'INT16',
      'INT32_T'         => 'INT',
      'bool'            => 'INT',
      'bool_t'          => 'INT',
      'BOOL'            => 'INT',
      'BOOL_T'          => 'INT',
      'unsigned int'    => 'HEX32',
      'unsigned long'   => 'HEX32',
      'uint32'          => 'HEX32',
      'uint32_t'        => 'HEX32',
      'UINT32'          => 'HEX32',
      'UINT32_T'        => 'HEX32',
      'void*'           => 'PTR',
      'unsigned short'  => 'HEX16',
      'uint16'          => 'HEX16',
      'uint16_t'        => 'HEX16',
      'UINT16'          => 'HEX16',
      'UINT16_T'        => 'HEX16',
      'unsigned char'   => 'HEX8',
      'uint8'           => 'HEX8',
      'uint8_t'         => 'HEX8',
      'UINT8'           => 'HEX8',
      'UINT8_T'         => 'HEX8',
      'char*'           => 'STRING',
      'pCHAR'           => 'STRING',
      'cstring'         => 'STRING',
      'CSTRING'         => 'STRING',
      'float'           => 'FLOAT',
      'double'          => 'FLOAT',
      'uInt8'           => 'HEX8',
      'uInt16'          => 'HEX16',
      'uInt32'          => 'HEX32',
      'Int8'            => 'INT8',
      'Int16'           => 'INT16',
      'Int32'           => 'INT32',
      'Char'            => 'INT8',
      'uInteger'        => 'HEX32',         # we cannot be sure what is really the implementation of 
      'Integer'         => 'INT',           # uInteger and Integer is
      'Bool'            => 'HEX8',
      'Float32'         => 'FLOAT',
      'Float64'         => 'FLOAT',
      'Fraction'        => 'FLOAT',
      'Byte'            => 'HEX8',
      'u8'              => 'HEX8',
      'u16'             => 'HEX16',
      'u32'             => 'HEX32',
      'h8'              => 'HEX8',
      'h16'             => 'HEX16',
      'h32'             => 'HEX32',
      'i8'              => 'INT8',
      'i16'             => 'INT16',
      'i32'             => 'INT32',
      's8'              => 'INT8',
      's16'             => 'INT16',
      's32'             => 'INT32',
      'f32'             => 'FLOAT',
      'f64'             => 'FLOAT',
      'U8'              => 'HEX8',
      'U16'             => 'HEX16',
      'U32'             => 'HEX32',
      'H8'              => 'HEX8',
      'H16'             => 'HEX16',
      'H32'             => 'HEX32',
      'I8'              => 'INT8',
      'I16'             => 'INT16',
      'I32'             => 'INT32',
      'S8'              => 'INT8',
      'S16'             => 'INT16',
      'S32'             => 'INT32',
      'F32'             => 'FLOAT',
      'F64'             => 'FLOAT',
    }
    return types.include?(type.downcase)
  end

  def parse_functions(source)
    funcs = []
    source.each {|line| funcs << line.strip.gsub(/\s+/, ' ') if (line =~ @declaration_parse_matcher)}
    if funcs.empty?
      case @when_no_prototypes
        when :error
          raise "ERROR: No function prototypes found!"
        when :warn
          puts "WARNING: No function prototypes found!" unless (@verbosity < 1)
      end
    end
    return funcs
  end

  def parse_args(arg_list)
    args = []
    arg_list.split(',').each do |arg|
      arg.strip!
      return args if (arg =~ /^\s*((\.\.\.)|(void))\s*$/)   # we're done if we reach void by itself or ...
      arg_array = arg.split
      arg_elements = arg_array - @c_attributes              # split up words and remove known attributes
      args << { :type   => (arg_type =arg_elements[0..-2].join(' ')),
                :name   => arg_elements[-1],
                :ptr?   => divine_ptr(arg_type),
                :const? => arg_array.include?('const')
              }
    end
    return args
  end

  def divine_ptr(arg_type)
    return false unless arg_type.include? '*'
    return false if arg_type.gsub(/(const|char|\*|\s)+/,'').empty?
    return true
  end

  def clean_args(arg_list)
    if ((@local_as_void.include?(arg_list.strip)) or (arg_list.empty?))
      return 'void'
    else
      c=0
      arg_list.gsub!(/(\w+)(?:\s*\[[\s\d\w+-]*\])+/,'*\1')  # magically turn brackets into asterisks
      arg_list.gsub!(/\s+\*/,'*')                           # remove space to place asterisks with type (where they belong)
      arg_list.gsub!(/\*(\w)/,'* \1')                       # pull asterisks away from arg to place asterisks with type (where they belong)

      #scan argument list for function pointers and replace them with custom types
      arg_list.gsub!(/([\w\s\*]+)\(+\s*\*[\*\s]*([\w\s]*)\s*\)+\s*\(((?:[\w\s\*]*,?)*)\s*\)*/) do |m|

        functype = "cmock_#{@module_name}_func_ptr#{@typedefs.size + 1}"
        funcret  = $1.strip
        funcname = $2.strip
        funcargs = $3.strip
        funconst = ''
        if (funcname.include? 'const')
          funcname.gsub!('const','').strip!
          funconst = 'const '
        end
        @typedefs << "typedef #{funcret}(*#{functype})(#{funcargs});"
        funcname = "cmock_arg#{c+=1}" if (funcname.empty?)
        "#{functype} #{funconst}#{funcname}"
      end

      #automatically name unnamed arguments (those that only had a type)
      arg_list.split(/\s*,\s*/).map { |arg|
        parts = (arg.split - ['struct', 'union', 'enum', 'const', 'const*'])
        if ((parts.size < 2) or (parts[-1][-1].chr == '*') or (@standards.include?(parts[-1])))
          "#{arg} cmock_arg#{c+=1}"
        else
          arg
        end
      }.join(', ')
    end
  end

  def parse_declaration(declaration)
    decl = {}

    regex_match = @declaration_parse_matcher.match(declaration)
    raise "Failed parsing function declaration: '#{declaration}'" if regex_match.nil?

    #grab argument list
    args = regex_match[2].strip

    #process function attributes, return type, and name
    descriptors = regex_match[1]
    descriptors.gsub!(/\s+\*/,'*')     #remove space to place asterisks with return type (where they belong)
    descriptors.gsub!(/\*(\w)/,'* \1') #pull asterisks away from function name to place asterisks with return type (where they belong)
    descriptors = descriptors.split    #array of all descriptor strings

    #grab name
    decl[:name] = descriptors[-1]      #snag name as last array item

    #build attribute and return type strings
    decl[:modifier] = []
    rettype = []
    descriptors[0..-2].each do |word|
      if @c_attributes.include?(word)
        decl[:modifier] << word
      elsif @c_calling_conventions.include?(word)
        decl[:c_calling_convention] = word
      else
        rettype << word
      end
    end
    decl[:modifier] = decl[:modifier].join(' ')
    rettype = rettype.join(' ')
    rettype = 'void' if (@local_as_void.include?(rettype.strip))
    decl[:return] = { :type   => rettype,
                      :name   => 'cmock_to_return',
                      :ptr?   => divine_ptr(rettype),
                      :const? => decl[:modifier].split(/\s/).include?('const'),
                      :str    => "#{rettype} cmock_to_return",
                      :void?  => (rettype == 'void')
                    }

    #remove default argument statements from mock definitions
    args.gsub!(/=\s*[a-zA-Z0-9_\.]+\s*/, ' ')

    #check for var args
    if (args =~ /\.\.\./)
      decl[:var_arg] = args.match( /[\w\s]*\.\.\./ ).to_s.strip
      if (args =~ /\,[\w\s]*\.\.\./)
        args = args.gsub!(/\,[\w\s]*\.\.\./,'')
      else
        args = 'void'
      end
    else
      decl[:var_arg] = nil
    end
    args = clean_args(args)
    decl[:args_string] = args
    decl[:args] = parse_args(args)
    decl[:args_call] = decl[:args].map{|a| a[:name]}.join(', ')
    decl[:contains_ptr?] = decl[:args].inject(false) {|ptr, arg| arg[:ptr?] ? true : ptr }

    if (decl[:return][:type].nil?   or decl[:name].nil?   or decl[:args].nil? or
        decl[:return][:type].empty? or decl[:name].empty?)
      raise "Failed Parsing Declaration Prototype!\n" +
        "  declaration: '#{declaration}'\n" +
        "  modifier: '#{decl[:modifier]}'\n" +
        "  return: #{prototype_inspect_hash(decl[:return])}\n" +
        "  function: '#{decl[:name]}'\n" +
        "  args: #{prototype_inspect_array_of_hashes(decl[:args])}\n"
    end

    return decl
  end

  def prototype_inspect_hash(hash)
    pairs = []
    hash.each_pair { |name, value| pairs << ":#{name} => #{"'" if (value.class == String)}#{value}#{"'" if (value.class == String)}" }
    return "{#{pairs.join(', ')}}"
  end

  def prototype_inspect_array_of_hashes(array)
    hashes = []
    array.each { |hash| hashes << prototype_inspect_hash(hash) }
    case (array.size)
    when 0
      return "[]"
    when 1
      return "[#{hashes[0]}]"
    else
      return "[\n    #{hashes.join("\n    ")}\n  ]\n"
    end
  end

end
