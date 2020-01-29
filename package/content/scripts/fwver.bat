@echo off
call load_environment
ruby %~dp0versionator.rb %*
