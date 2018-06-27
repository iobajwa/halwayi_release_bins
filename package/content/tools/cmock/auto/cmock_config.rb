# ==========================================
#   CMock Project - Automatic Mock Generation for C
#   Copyright (c) 2007 Mike Karlesky, Mark VanderVoord, Greg Williams
#   [Released under MIT License. Please refer to license.txt for details]
# ==========================================

class CMockConfig

  CMockDefaultOptions =
  {
    :framework                   => :unity,
    :mock_path                   => 'mocks',
    :mock_prefix                 => 'Mock',
    :plugins                     => [],
    :strippables                 => ['(?:__attribute__\s*\(+.*?\)+)'],
    :attributes                  => ['__ramfunc', '__irq', '__fiq', 'register', 'extern'],
    :c_calling_conventions       => ['__stdcall', '__cdecl', '__fastcall'],
    :enforce_strict_ordering     => false,
    :unity_helper_path           => false,
    :treat_as                    => {},
    :treat_as_void               => ["INTERRUPT", "INTERRUPT_LOWER", "INTERRUPT_HIGHER"],
    :memcmp_if_unknown           => true,
    :when_no_prototypes          => :ignore,           #the options being :ignore, :warn, or :error
    :when_ptr                    => :compare_data,   #the options being :compare_ptr, :compare_data, or :smart
    :verbosity                   => 2,               #the options being 0 errors only, 1 warnings and errors, 2 normal info, 3 verbose
    :treat_externs               => :exclude,        #the options being :include or :exclude
    :callback_include_count      => true,
    :callback_after_arg_check    => false,
    :includes                    => nil,
    :includes_h_pre_orig_header  => nil,
    :includes_h_post_orig_header => nil,
    :includes_c_pre_header       => nil,
    :includes_c_post_header      => nil,
    :relative_path               => nil,
    :ignore                      => [],
    :inject                      => [],
    :only                        => [],
  }

  def initialize(options=nil)
    case(options)
      when NilClass then options = CMockDefaultOptions.clone
      when String   then options = CMockDefaultOptions.clone.merge(load_config_file_from_yaml(options))
      when Hash     then options = CMockDefaultOptions.clone.merge(options)
      else          raise "If you specify arguments, it should be a filename or a hash of options"
    end

    #do some quick type verification
    [:plugins, :attributes, :treat_as_void].each do |opt|
      unless (options[opt].class == Array)
        options[opt] = []
        puts "WARNING: :#{opt.to_s} should be an array." unless (options[:verbosity] < 1)
      end
    end
    [:includes, :includes_h_pre_orig_header, :includes_h_post_orig_header, :includes_c_pre_header, :includes_c_post_header].each do |opt|
      unless (options[opt].nil? or (options[opt].class == Array))
        options[opt] = []
        puts "WARNING: :#{opt.to_s} should be an array." unless (options[:verbosity] < 1)
      end
    end
    options[:unity_helper_path] ||= options[:unity_helper]
    options[:plugins].compact!
    options[:plugins].map! {|p| p.to_sym}

    # resolve aliases
    resolve_alias(options, :ignore_arg, [:ignore_arg, :ignore_args, :ignore_argument, :ignore_arguments] )
    resolve_alias(options, :array, [:array, :arrays] )
    resolve_alias(options, :callback, [:callback, :with_callback, :callbacks, :with_callbacks] )
    resolve_alias(options, :return_thru_ptr, [ :return_thru_ptr, 
                                               :return_through_ptr, 
                                               :return_through_pointer, 
                                               :return_thru_ptrs, 
                                               :return_through_ptrs, 
                                               :return_through_pointers,
                                               :return_via_ptr,
                                               :return_via_ptrs,
                                               :return_via_pointer,
                                               :return_via_pointers,
                                               :return_using_ptr,
                                               :return_using_ptrs,
                                               :return_using_pointer,
                                               :return_using_pointers,
                                             ])
    found_match = contains_alias(options, :enforce_strict_ordering, [ :check_order,
                                                                      :check_call_order, 
                                                                      :strict_order, 
                                                                      :strict_call_order, 
                                                                      :enforce_order,
                                                                      :enforce_call_order, 
                                                                      :enforce_strict_call_order, 
                                                                      :enforce_strict_call_ordering,
                                                                    ])
    if found_match || options[:enforce_strict_ordering] == nil || options[:enforce_strict_ordering] == ""
      options.delete found_match
      options[:enforce_strict_ordering] = true
    end
    
    @options = options

    treat_as_map = standard_treat_as_map()#.clone
    treat_as_map.merge!(@options[:treat_as])
    @options[:treat_as] = treat_as_map

    # transform back the function syntax (which was destructured because ',' '(' ')' '*' cannot be passed as command line arguments)
    inject_functions = []
    @options[:inject].each do |func|
      func = func + "; "
      func = func.gsub('...', ')')
      func = func.gsub('..', ',')
      func = func.gsub('.', '(')
      func = func.gsub(':', "*")
      inject_functions << func
    end

    @options[:inject] = inject_functions;

    @options.each_key { |key| eval("def #{key.to_s}() return @options[:#{key.to_s}] end") }
  end

  def load_config_file_from_yaml yaml_filename
    self.class.load_config_file_from_yaml yaml_filename
  end

  def self.load_config_file_from_yaml yaml_filename
    require 'yaml'
    require 'fileutils'
    YAML.load_file(yaml_filename)[:cmock]
  end

  def set_path(path)
    @src_path = path
  end

  def load_unity_helper
    return File.new(@options[:unity_helper_path]).read if (@options[:unity_helper_path])
    return nil
  end

  def standard_treat_as_map
    {
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
      'i8'              => 'INT8',
      'i16'             => 'INT16',
      'i32'             => 'INT32',
      'h8'              => 'HEX8',
      'h16'             => 'HEX16',
      'h32'             => 'HEX32',
      'f32'             => 'FLOAT',
      'f64'             => 'FLOAT',
    }
  end

  private

  def contains_alias(options, key, aliases=[])
    aliases.each {  |a|
      if options.include?(a)
        return a
      end
    }
    return nil
  end
  
  def resolve_alias(options, key, aliases=[], add_to_root=false)
    found_match = contains_alias options, key, aliases
    if found_match
      options.delete found_match
      if add_to_root
        key = { key => nil } if key.class != Hash
        options.merge key
      else
        plugs = options[:plugins]
        plugs = [] if plugs == nil
        plugs.push key
        options[:plugins] = plugs
      end
    end
    return options
  end

  public
  # explicitly declare scope back to public. This is because in ruby 2.3.1
  # when we dynamically generate and append methods to the class, the last
  # active scope is automatically assumed.
end
