@echo off

rem Copyright Bhavnit Singh Bajwa   iobajwa@gmail.com
rem Please refer to Halwayi's license agreement for more details

pushd "%CD%"

call load_environment.bat

set glob=
set selected_glob=
set selected_runner=
set runNative=
set runGhost=
set toolRoot=%HalwayiToolsRoot%\tools\runner
set filter_variant=
set filter_platform=
set xmlReport="--xml_report=%TestReportName%"

:parse_parameter_flags
	IF [%1]==[] (
		GOTO end_parse
	) else IF [%1]==[gui] (
		set selected_runner=gui
	) else IF [%1]==[no_xml_report] (
		set xmlReport=
	) else IF [%1]==[no-xml-report] (
		set xmlReport=
	) else IF [%1]==[console] (
		set selected_runner=console
	) else IF [%1]==[cui] (
		set selected_runner=console
	) else IF [%1]==[var] (
		set var=%~2
		SHIFT
	) else IF [%1]==[platform] (
		set platform=%~2
		SHIFT
	) else IF [%1]==[ghost] (
		set runGhost=true
	) else IF [%1]==[native] (
		set runNative=true
	) else IF [%1]==[?] (
		echo.
		echo  Runs unit-tests for ghost and/or native images
		echo.
		echo     gui           : use the gui runner
		echo     console       : use the console-based runner
	    echo     no_xml_report : suppress the xml report {alias: no-xml-report}
		echo.
		echo     ghost    : run ghost images
		echo     native   : run native images
		echo.
		echo     platform : run tests for specified platform/s only
		echo     var      : run tests for specified variant/s only
		echo     glob     : run tests matching passed glob
		echo.
		echo.
		echo    NOTE: 
		echo        1. ghost images are run by default when no preference is specified.
		echo        2. any unrecoganized switch is assumed to be a glob. In case multiple
		echo           unrecoganized switches are passed, the last one takes effect.
		echo        3. multiple filters {var, platform, 'glob'} can be clubbed together to
		echo           fine-tune the filter process
		echo.
		goto r_exit
	) else (
		set glob=%1
	)
	SHIFT
	GOTO parse_parameter_flags
:end_parse

cd %BinRoot%\tests
if ["%var%"] NEQ [""] (
	set filter_variant=--variant=%var%
)

if ["%platform%"] NEQ [""] (
	set filter_platform=--platform=%platform%
)

if ["%glob%"] NEQ [""] (
	set selected_glob=--glob=%glob%
	echo running tests '%glob%'..
	echo.
) else (
	echo running tests..
	echo.
)

if ["%selected_runner%"] NEQ [""] (
	if ["%selected_runner%"]==["gui"] (
		set guiRunner=true
		set consoleRunner=false
	) else (
		set consoleRunner=true
		set guiRunner=false
	)
)

if "[%guiRunner%"]==["false"] if ["%consoleRunner%"]==["false"] (
	set guiRunner=true
)

if ["%runNative%"]==[""] if ["%runGhost%"]==[""] (
	set runGhost=true
	set runNative=false
)

if ["%runGhost%"]==[""] set runGhost=false
if ["%runNative%"]==[""] set runNative=false

if ["%guiRunner%"]==["false"] (
	"%toolRoot%\runner-CUI.exe" "project.fixture_config" %selected_glob% %xmlReport% %deltaRun% --run_on_ghost=%runGhost% --run_on_simulator=%runNative% %showToolLog% %filter_variant% %filter_platform%
) else (
	"%toolRoot%\runner.exe" "project.fixture_config" --run_selected --run_on_ghost=%runGhost% --run_on_simulator=%runNative% %xmlReport% %deltaRun% --exit_on_esc %selected_glob% %filter_variant% %filter_platform%
) 

:r_exit
popd
