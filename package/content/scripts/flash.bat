@echo off

rem Copyright Bhavnit Singh Bajwa   iobajwa@gmail.com
rem Please refer to Halwayi's license agreement for more details

set program_with_power=false
set FeatureName=final
set image_type=release
set jlink_erase=false

	rem first things first
call load_environment


	rem Parse command line switches to determine the target, feature
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
		) else IF [%1]==[target] (
			set target=%~2
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
			echo     target      : specific target 
			echo     debug       : flash the debug image
			echo     [unrecoganized flags are assumed to be feature names]
			echo.
			goto f_exit
		) else (
			set FeatureName=%~1
		)
	SHIFT
	GOTO f_parse_parameter_flags
:f_end_parse



	rem some sanity checking
if [%ghost%]==[] if [%native%]==[] (	
	rem we do native release by default
	set native=native
)
if [%target%]==[] (
	echo which target?
	goto ferr_exit
)

if [%FeatureName%]==[] (
	set FeatureName=final
)


echo Flashing '%FeatureName%' feature..

	rem figure out the native flash script details 
	rem the project name..
set project_name=
FOR /F "tokens=*" %%F IN ('list project.name') do SET project_name=%%F
if ["%project_name%"]==[""] (
	echo ERROR: Project name could not be determined
	goto ferr_exit
)

	rem the release_cpu..
for /F "tokens=*" %%F IN ('list target.cpu.release') do set CPU=%%F
IF ["%CPU%"]==[""] (
	echo ERROR: no release cpu found for the current target
	goto ferr_exit
)
set exec_path="%BinRoot%\features\%FeatureName%\%image_type%\%target%\%project_name%.exe"
IF ["%NativeExecName%"]==[""] (
	set native_exec_path="%BinRoot%\features\%FeatureName%\%image_type%\%target%\%project_name%.hex"
) else (
	set native_exec_path="%BinRoot%\features\%FeatureName%\%image_type%\%target%\%NativeExecName%"
)
set mdb_script="%ArtifactsRoot%\etc\%FeatureName%_%target%_%image_type%_pk3_mdb.txt"
set jlink_script="%ArtifactsRoot%\etc\%FeatureName%_%target%_%image_type%_jlink.txt"

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

			if errorlevel 1 (
				echo ERROR: Failed to program platform
				goto ferr_exit
			)
		) else (
			echo Could not locate mdb.bat
			goto f_exit
		)
	) else IF "%FlashTool%"=="nsprog" (
		echo .
		echo flashing using nsprog - %native_exec_path%
		call nsprog.exe p %FlashToolExtraProgrammingArgs% -d %CPU% -i %native_exec_path% %FlashToolExtraArgs%
	) else IF "%FlashTool%"=="stlink" (
		IF exist "%stlinkPath%" (
			echo flashing using stlink - %FlashToolInterface% - %native_exec_path%
			call "%stlinkPath%" -c %FlashToolInterface% -p %native_exec_path% %FlashToolExtraProgrammingArgs% -v -Rst %FlashToolExtraArgs%

			if errorlevel 1 (
				echo ERROR: Failed to program platform
				goto ferr_exit
			)
		) else (
			echo ERROR: Could not locate ST-LINK_CLI.exe
			goto ferr_exit
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

			if errorlevel 1 (
				echo ERROR: Failed to program platform
				goto ferr_exit
			)
		) else (
			echo ERROR: Could not locate JLink.exe
			goto ferr_exit
		)
	) else IF exist "%FlashTool%" (
		call "%FlashTool%" %native_exec_path%
	) else (
		echo .
		echo ERROR: FlashTool not defined.
		goto ferr_exit
	)
)

	rem flash ghost
if [%ghost%] NEQ [] (
	echo .
	echo Executing '%exec_path%'..
	%exec_path%			rem ghost exectuable is run.
)

goto f_exit

:ferr_exit
endlocal
exit /b 1

:f_exit
endlocal
