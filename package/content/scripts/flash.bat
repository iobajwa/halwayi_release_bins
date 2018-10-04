@echo off

rem Copyright Bhavnit Singh Bajwa   iobajwa@gmail.com
rem Please refer to Halwayi's license agreement for more details

set program_with_power=false
set FeatureName=final
set image_type=release
set jlink_erase=false

	rem first things first
call load_environment


	rem Parse command line switches to determine the variant, feature
:f_parse_parameter_flags
		IF [%1]==[] (
			GOTO f_end_parse
		) else IF [%1]==[fp] (
			set program_with_power=true
		) else IF [%1]==[ghost] (	
			set ghost=ghost
			set native=
		) else IF [%1]==[native] (
			set native=native
			set ghost=
		) else IF [%1]==[var] (
			set var=%~2
			SHIFT
		) else IF [%1]==[platform] (
			set platform=%~2
			SHIFT
		) else IF [%1]==[jlink_erase] (
			set jlink_erase=true
		) else IF [%1]==[debug] (
			set image_type=debug
		) else IF [%1]==[?] (
			echo.
			echo  Flash images onto the hardware or run on ghost
			echo.
			echo     jlink_erase : ensures jlink erases the target
			echo     fp          : flash with power        
			echo     ghost       : run ghost image      
			echo     native      : flash native image  
			echo     var         : specific variant       
			echo     platform    : specific platform 
			echo     debug       : flash the debug image
			echo     [unrecoganized flags are assumed to be feature names]
			echo.
			goto f_exit
		) else (
			IF exist "%TargetsRoot%\%1.bat" (
				set target=%1
			) else (
				set FeatureName=%~1
			)
		)
	SHIFT
	GOTO f_parse_parameter_flags
:f_end_parse

if ["%target%"] NEQ [""] (
	echo '%target%' target..
	call "%TargetsRoot%\%target%.bat"
)


	rem some sanity checking
if [%ghost%]==[] if [%native%]==[] (	
	rem we do native release by default
	set native=native
)

if [%FeatureName%]==[] (
	set FeatureName=final
)

echo Flashing '%FeatureName%' feature..


	rem figure out the user supplied variant
set variant_count=0
FOR /F "tokens=*" %%F IN ('list variant_count') do SET variant_count=%%F
if %variant_count% GTR 1 if ["%var%"]==[""] (
	echo ERROR: Cannot flash multiple variants
	goto f_exit
)
if [%variant_count%]==[1] (
	rem get the default variant name in case there is only a single variant defined.
	FOR /F "tokens=*" %%F IN ('list variants') do SET var=%%F
	
)

	rem figure out the platform

set platform_to_flash=%platform%
setlocal enableextensions enabledelayedexpansion
set platform_count=0

if ["%platform%"] NEQ [""] (
	rem make sure user has provided a single platform
	echo "%platform%" | findstr /C:";">nul && (
		echo ERROR: Cannot flash multiple platforms
	)
	set platform_count=1
	set platform_to_flash=%platform%
) else (
	rem if user supplied none, get the platform available for the active variant,
	rem provided there is only a single platform
	FOR /F "tokens=*" %%F IN ('list first_platform var %var%') do SET platform_to_flash=%%F
	set first_line=1
	FOR /F "tokens=*" %%F IN ('list platform_count') do (
		if !first_line!==1 set platform_count=%%F
		set first_line=0
	)
)
	rem some sanity checks
if %platform_count%==0 (
	echo ERROR: No platform defined
)
if %platform_count% GTR 1 (
	echo ERROR: Cannot flash multiple platforms 
	echo        %platform_count% platforms available for '%var%' variant
	goto f_exit
)


	rem figure out the native flash script details 
	rem the project name..
set project_name=
FOR /F "tokens=*" %%F IN ('list project_name') do SET project_name=%%F
if ["%project_name%"]==[""] (
	goto f_exit
)

	rem figure out the release_cpu
for /F "tokens=*" %%F IN ('list var "%var%" release_cpu') do set CPU=%%F
IF ["%CPU%"]==[""] (
	for /F "tokens=*" %%F IN ('list var "%var%" release_cpu platform %platform_to_flash%') do set CPU=%%F
)
set variant_platform=%var%+%platform_to_flash%
set exec_path="%BinRoot%\features\%FeatureName%\%image_type%\%variant_platform%\%project_name%.exe"
set native_exec_path="%BinRoot%\features\%FeatureName%\%image_type%\%variant_platform%\%project_name%.hex"
set mdb_script="%ArtifactsRoot%\etc\%FeatureName%_%variant_platform%_%image_type%_pk3_mdb.txt"
set jlink_script="%ArtifactsRoot%\etc\%FeatureName%_%variant_platform%_%image_type%_jlink.txt"

if exist "%mdb_script%" (
	del "%mdb_script$"
)

if exist "%jlink_script%" (
	del "%jlink_script%"
)


	rem flash native

	rem flush out error code
ver > nul

if [%native%] NEQ [] (

	if "%FlashTool%"=="mdb" (
		rem create the mdb script
		echo .
		echo Creating script %mdb_script%
		echo device %CPU%	                        >> %mdb_script%
		echo set system.disableerrormsg true	    >> %mdb_script%
		if [%program_with_power%]==[true] (
			echo set poweroptions.powerenable true  >> %mdb_script%
		)
		echo hwtool %FlashTool% -p	                >> %mdb_script%
		echo program %native_exec_path%	            >> %mdb_script%
		echo quit	                                >> %mdb_script%

		IF exist "%mdbPath%" (
			call "%mdbPath%" "%mdb_script%"

			if %ERRORLEVEL% GTR 0 (
				echo ERROR: Failed to program platform
				goto f_exit
			)
		) else (
			echo Could not locate mdb.bat
			goto f_exit
		)
	) else IF "%FlashTool%"=="nsprog" (
		echo .
		echo flashing using nsprog - %native_exec_path%
		call nsprog.exe p -d %CPU% -i %native_exec_path%
	) else IF "%FlashTool%"=="stlink" (
		IF exist "%stlinkPath%" (
			echo flashing using stlink - %FlashToolInterface% - %native_exec_path%
			call "%stlinkPath%" -c %FlashToolInterface% -p %native_exec_path% -v -Rst

			if %ERRORLEVEL% GTR 0 (
				echo ERROR: Failed to program platform
				goto f_exit
			)
		) else (
			echo Could not locate ST-LINK_CLI.exe
			goto f_exit
		)
	) else IF "%FlashTool%"=="jlink" (
		echo .
		echo flashing using jlink - %FlashToolInterface% - %native_exec_path%
		echo Creating script %jlink_script%

		rem forced to not align the %CPU% rendering because the jlink_utility cannot handle trailing empty spaces -_-
		echo Device %CPU%>> %jlink_script%
		IF "%FlashToolInterface%"=="SWD" (
			echo // target interface is SWD
			echo si 1                                                                                    >> %jlink_script%
			echo speed auto                                                                              >> %jlink_script%
		) else (
			echo // target interface is JTAG                                                             >> %jlink_script%
			echo si JTAG                                                                                 >> %jlink_script%
			echo // JTAG speed set to auto                                                               >> %jlink_script%
			echo speed auto                                                                              >> %jlink_script%
			echo // Set number of IR/DR bits before ARM device                                           >> %jlink_script%
			echo // This probably has to do something with chaining of several devices on a single JTAG  >> %jlink_script%
			echo // Device position in JTAG chain- IRPre,DRPre default- -1,-1 - Auto-detect              >> %jlink_script%
			echo JTAGConf -1,-1                                                                          >> %jlink_script%
		)
		echo // reset target                                                                         >> %jlink_script%
		echo r                                                                                       >> %jlink_script%
		if ["%jlink_erase%"]==["true"] (
			echo // erase the device                                                                 >> %jlink_script%
			echo erase                                                                               >> %jlink_script%
		)
		echo // reset target                                                                         >> %jlink_script%
		echo r                                                                                       >> %jlink_script%
		echo // load                                                                                 >> %jlink_script%
		echo loadfile %native_exec_path%                                                             >> %jlink_script%
		echo r                                                                                       >> %jlink_script%
		echo g                                                                                       >> %jlink_script%
		echo exit                                                                                    >> %jlink_script%

		echo flashing using jlink - %jlink_script%
		IF exist "%jlinkPath%" (
			call "%jlinkPath%" "%jlink_script%"

			if %ERRORLEVEL% GTR 0 (
				echo ERROR: Failed to program platform
				goto f_exit
			)
		) else (
			echo Could not locate JLink.exe
			goto f_exit
		)
	) else (
		echo .
		echo ERROR: FlashTool not defined.
		goto f_exit
	)
)  

	rem flash ghost
if [%ghost%] NEQ [] (
	echo .
	echo Executing '%exec_path%'..
	%exec_path%			rem ghost exectuable is run.
)

:f_exit
endlocal
