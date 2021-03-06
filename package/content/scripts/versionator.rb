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
target     = ENV['target']

unless target
	puts "for which target?"
	exit -1
end

generate_sources = ARGV.include? "generate"
clean_sources    = ARGV.include? "clean"

source_root = auto_code_root
error "could not determine the auto source_root" unless auto_code_root

header_file       = File.join source_root, "fwversion.h"
source_file       = File.join source_root, "fwversion.c"
version_lock_file = File.join etc_root,    "fwversion.lock"

if clean_sources
	File.delete header_file       if File.exist?(header_file)
	File.delete source_file       if File.exist?(source_file)
	File.delete version_lock_file if File.exist?(version_lock_file)
	exit
end

unless fw_version
	# create a version string
	branch_name   = `git rev-parse --abbrev-ref HEAD`.strip.gsub(/\s+/, '-')
	commit_number = `git rev-parse --verify HEAD`.strip
	changeset     = `git ls-files -m`.strip
	commit_number = commit_number[0...7]
	commit_number = "~#{commit_number}" if changeset and changeset != ""
	dev_name      = `git config user.name`.strip unless dev_name
	dev_name      = dev_name.gsub(/\s+/, '-').downcase
	fw_version    = "#{branch_name}/#{commit_number}/#{dev_name}"
else
	changeset  = `git ls-files -m`.strip
	fw_version = "#{fw_version}~" if changeset and changeset != ""
end

fw_version  = "#{target}/#{fw_version}"

# ensure that we only create a new file if the version has changed
old_version = try_read_file(version_lock_file)
old_version = old_version[0] if old_version
old_version.strip!           if old_version

unless generate_sources
	if fw_version == old_version
		puts "", fw_version
		exit
	end
	puts ""
	puts "last build : #{old_version}"
	puts "next build : #{fw_version}"
	exit
end

create_file version_lock_file, fw_version unless fw_version == old_version

header_file_contents = "/* AUTO GENERATED. DO NOT EDIT */

#ifndef __FW_VERSION_H__
#define __FW_VERSION_H__

#include <#{ctypesfile}>



#define FW_VERSION_STRING_LENGTH    #{fw_version.length}
#define FW_VERSION_BUFFER_LENGTH    (FW_VERSION_STRING_LENGTH + 1)


void        fwversion_get     ( u8 *buffer );	// assumes buffer is large enough
const Char* fwversion_get_ref ( void );



#endif // __FW_VERSION_H__
"

source_file_contents = "/* AUTO GENERATED. DO NOT EDIT */

#include <fwversion.h>
#include <string.h>

static const Char* fw_string = \"#{fw_version}\";


void fwversion_get( u8 *buffer )
{
	memcpy( buffer, (void*)fw_string, FW_VERSION_STRING_LENGTH + 1 );
}

const Char* fwversion_get_ref( void )
{
	return fw_string;
}
"

exit if File.exist?(header_file) and File.exist?(source_file) and fw_version == old_version

create_file header_file, header_file_contents
create_file source_file, source_file_contents
