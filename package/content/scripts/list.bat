@echo off

rem Copyright Bhavnit Singh Bajwa   iobajwa@gmail.com
rem Please refer to Halwayi's license agreement for more details

set field=

call load_environment

:qp_parse_parameter_flags
		IF [%1]==[] (
			GOTO qp_end_parse
		) else IF [%1]==[var] (
			set var="%~2"
			SHIFT
		) else IF [%1]==[platform] (
			set platform="%~2"
			SHIFT
		) else IF [%1]==[?] (
			echo.
			echo  Know project properties directly from the command line
			echo.
			echo     project_name
			echo     context        : active target 'variant+platform' configuration
			echo     target_context
			echo.
			echo     variants
			echo     variant_count
			echo     first_variant
			echo     release_cpu
			echo     test_cpu
			echo     target_count
			echo.
			echo     targets
			echo     target_names
			echo     target_count
			echo.
			echo     features
			echo     feature_count
			echo.
			echo     platforms      : platforms shared by all variants if var is unspecified,
			echo                      platforms specific to the specified var otherwise.
			echo     platform_count : specific to specified var
			echo.
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
if %ERRORLEVEL% GTR 0 exit /b %ERRORLEVEL%

:l_exit