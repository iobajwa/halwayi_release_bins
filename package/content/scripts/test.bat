@echo off

rem Copyright Bhavnit Singh Bajwa   iobajwa@gmail.com
rem Please refer to Halwayi's license agreement for more details

call load_environment.bat

set user_interface=gui
set ghost=
set native=
set glob=
set test_job=build
set selected_target=
set platform_chosen=
set no_xml_report=
set run_tests_post_build=true
set exit_code_flag=

pushd "%CD%"
	rem Parse command line switches to figure out what to do
:parse_parameter_flags
		IF [%1]==[] (
			GOTO end_parse
		) else IF [%1]==[native] (
			set native=native
		) else IF [%1]==[ghost] (
			set ghost=ghost
		) else IF [%1]==[console] (
			set user_interface=console
		) else if [%1]==[gui] (
			set user_interface=gui
		) else IF [%1]==[clean] (
			set test_job=clean
		) else if [%1]==[target] (
			set target=%~2
			SHIFT
		) else IF [%1]==[no-xml-report] (
			set no_xml_report=no_xml_report
		) else IF [%1]==[no_xml_report] (
			set no_xml_report=no_xml_report
		) else IF [%1]==[no-run] (
			set run_tests_post_build=false
		) else IF [%1]==[no_run] (
			set run_tests_post_build=false
		) else IF [%1]==[hide-exit-code] (
			set exit_code_flag=suppress_exit_code
		) else IF [%1]==[hide_exit_code] (
			set exit_code_flag=suppress_exit_code
		) else if [%1]==[?] (
			echo.
			echo  Builds and automatically runs unit-tests
			echo.
			echo     target    : Builds and runs tests for specificied target/s
			echo     'glob'    : Builds and runs tests matching specificied glob
			echo     clean     : perform clean
			echo.
			echo     ghost     : build ghost images
		    echo     native    : build native images
		    echo.
		    echo     gui       : run tests on gui runner
		    echo     console   : run tests on console-based runner
		    echo     no_xml_report  : suppress the xml report {alias: no-xml-report}
		    echo     no_run         : tests are only compiled and not run
	    	echo     hide_exit_code : suppresses the exit code from runner
		    echo.
		    echo    NOTE: 
			echo        1. ghost images are run by default when no preference is specified.
			echo        2. any unrecoganized switch is assumed to be a glob. In case multiple
			echo           unrecoganized switches are passed, the last one takes effect.
			echo        3. multiple filters {target, 'glob'} can be clubbed together to
			echo           fine-tune the filter process
			echo.
			popd
			goto exit_script
		) else (
			set glob=%~1
		)
		SHIFT
	GOTO parse_parameter_flags
:end_parse

if ["%target%"] NEQ [""] (
	echo '%target%' target..
	set selected_target=target "%target%"
)

call halwayiWrapper.bat %native% %ghost% %selected_target% %test_job% "%glob%"

if errorlevel 1 (
	popd
	exit /b 1
)

popd

if [%test_job%]==[clean] goto exit_script
if [%run_tests_post_build%]==[false] goto exit_script
call run "%glob%" %native% %ghost% %user_interface% %selected_target% %exit_code_flag% %no_xml_report%

:exit_script
