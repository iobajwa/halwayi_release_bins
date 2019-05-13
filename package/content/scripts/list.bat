@echo off

rem Copyright Bhavnit Singh Bajwa   iobajwa@gmail.com
rem Please refer to Halwayi's license agreement for more details

set field=

call load_environment

:qp_parse_parameter_flags
		IF [%1]==[] (
			GOTO qp_end_parse
		) else IF [%1]==[target] (
			set target=%~2
			SHIFT
		) else IF [%1]==[?] (
			echo.
			echo  Know project properties directly from the command line
			echo.
			echo     project.name
			echo     context        : active target 'variant+platform' configuration
			echo.
			echo     variants
			echo     variants.count
			echo     variants.first
			echo     variants.last
			echo.
			echo     targets
			echo     targets.names
			echo     targets.count
			echo     target.cpu.release
			echo     target.cpu.test
			echo.
			echo     features
			echo     features.count
			echo.
			echo     platforms
			echo     platforms.count
			echo     platforms.first
			echo     platforms.last
			echo.
			echo     tests
			echo     tests.count
			goto l_exit
		) else (
			set field=%~1
		)
	SHIFT
	GOTO qp_parse_parameter_flags
:qp_end_parse

	rem some sanity checks
if ["%field%"]==[""] (
	echo Error: No field passed to query.
	exit /b 1
)


IF NOT exist "%HalwayiToolsRoot%\project.query" (
	echo Could not locate project.query!
	exit /b 1
)


pushd "%CD%"
cd %ProjectRoot%
set project_file=%ProjectRoot%\project.properties

msbuild "%HalwayiToolsRoot%\project.query" /v:m /nologo /p:FieldToQuery=%field%;SelectedTarget="%target%";SelectedVariant="%var%";SelectedPlatform="%platform%";ProjectFile="%project_file%"

popd
if errorlevel 1 exit /b 1

:l_exit