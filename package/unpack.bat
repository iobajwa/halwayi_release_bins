@echo off
	rem The package folder can be downloaded anywhere (inside a temp folder)
	rem usually it's the build\packages\halwayi folder.
	rem Once the package has been downloaded, this file should be run. This
	rem file (unpack.bat) automatically installs the package.

set base_path=%~dp0
echo path provided '%base_path%'

echo copying "%base_path%/content" to "%base_path%"
xcopy /s "%base_path%/content" "%base_path%"

echo deleting "%base_path%\scripts\environment.bat"
del "%base_path%\scripts\environment.bat"

echo removing directory "%base_path%\content"
rmdir /s /q "%base_path%\content"

set env_load_script="%base_path%\paths.txt"
echo creating environment script '%env_load_script%'
echo %base_path%/scripts > %env_load_script%

echo done.