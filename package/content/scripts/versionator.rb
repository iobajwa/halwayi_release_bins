# 
# 	a simple tool to generate the fwversion module automagically at build time.
#   set the fw_version environment variable to the intended version
#
#   if the env variable is not set, it generates a version string based as follows:
#       <branch-name>/<7 digits of commit number>/<dev_name>
#
#   dev_name can be injected by providing the DEV_NAME environment variable.
#   If this variable is not defined, it uses the git username
#
#   requires git, ofcourse. 
# 
require_relative "halwayi"
require_relative "helpers"

dev_name   = ENV['DEV_NAME']
fw_version = ENV["FW_VERSION"]

generate_sources = ARGV.include? "generate-sources"

unless fw_version
	# create a version string
	branch_name   = `git rev-parse --abbrev-ref HEAD`.strip.gsub(/\s+/, '-')
	commit_number = `git rev-parse --verify HEAD`.strip
	dev_name      = `git config user.name`.strip unless dev_name
	dev_name      = dev_name.gsub(/\s+/, '-').downcase
	fw_version    = "#{branch_name}/#{commit_number[0...7]}/#{dev_name}"
end

fw_version  = fw_version.to_s

# ensure that we only create a new file if the version has changed
version_lock_file = File.join etc_root, "fwversion.lock"
old_version = try_read_file(version_lock_file)
old_version = old_version[0] if old_version
old_version.strip!           if old_version
exit if fw_version == old_version
create_file version_lock_file, fw_version

if generate_sources
	header_file_contents = "/* AUTO GENERATED. DO NOT EDIT */

#ifndef __FW_VERSION_H__
#define __FW_VERSION_H__

#include <#{ctypesfile}>



#define FW_VERSION_STRING_LENGTH    #{fw_version.length}
#define FW_VERSION_BUFFER_LENGTH    (FW_VERSION_STRING_LENGTH + 1)


void  fwversion_get     ( u8 *buffer, u8 max_buffer_length );	// assumes buffer is large enough
Char* fwversion_get_ref ( void );



#endif // __FW_VERSION_H__
"

	source_file_contents = "/* AUTO GENERATED. DO NOT EDIT */

#include <fwversion.h>
#include <string.h>

static Char* fw_string = \"#{fw_version}\";


void fwversion_get( u8 *buffer, u8 max_buffer_length )
{
	memcpy( buffer, (void*)fw_string, FW_VERSION_STRING_LENGTH + 1 );
}

Char* fwversion_get_ref( void )
{
	return fw_string;
}
"

	source_root = auto_code_root
	error "could not determine the auto source_root" unless auto_code_root

	header_file = File.join source_root, "fwversion.h"
	source_file = File.join source_root, "fwversion.c"

	create_file header_file, header_file_contents
	create_file source_file, source_file_contents
else
	puts fw_version
end
