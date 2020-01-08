@echo off

rem Copyright Bhavnit Singh Bajwa   iobajwa@gmail.com
rem Please refer to Halwayi's license agreement for more details

set ghost=
set native=
set halwayi_target=releaseAll
set debug=
set native_script_path=
set exec_path=
set feature_file=
set FeatureName=final
set program=false
set program_with_power=false
set target_chosen=
set ProjectName=
set CPU=
set build_ide=false

	rem first things first
call load_environment



	rem Parse command line switches to determine the target, feature
:rv_parse_parameter_flags
		IF [%1]==[] (
			GOTO rv_end_parse
		) else IF [%1] == [?] (
		    echo.
			echo  Builds an image of the project using the active working context
			echo.
			echo     build            : builds the 'final' native image feature
			echo.
			echo     build debug      : builds the 'final' native image feature with debug
			echo                          configuration
			echo.
			echo     build f          : builds and flashes the 'final' native image feature
			echo                          by using the specified %FlashTool%
			echo     build fp         : builds and flashes the 'final' native image feature
			echo                          by enabling the power of %FlashTool%
			echo.
			echo     build view ghost : builds the 'view' ghost image feature
			echo     build adc native f : builds and flashes the 'adc' feature native image
			echo     build adc ide    : builds the ide project for 'adc' feature
			echo.
			echo     NOTES: 
			echo           1. 'native' is the default image-type when none is specified
			echo           2. ghost-images are run when specified with 'f' or 'fe' args
			GOTO abort_script
		) else IF [%1]==[ghost] (	
			set ghost=ghost
		) else IF [%1]==[native] (
			set native=native
		) else IF [%1]==[f] (
			set program=true
		) else IF [%1]==[fp] (
			set program=true
			set program_with_power=true
		) else IF [%1]==[debug] (
			set debug=ForDebug
		) else IF [%1]==[clean] (
			set halwayi_target=cleanReleaseAll
			set clean=true
		) else IF [%1]==[ide] (
			set build_ide=true
		) else IF [%1]==[target] (
			set target=%~2
			SHIFT
		) else IF [%1]==[platform] (
			set platform=%~2
			SHIFT
		) else (
			rem treat this as a feature 
			set feature_file=feature %1
			set FeatureName=%~1
		)
	SHIFT
	GOTO rv_parse_parameter_flags
:rv_end_parse

	rem display the context
if ["%target%"] NEQ [""] (
	echo '%target%' target..
	set target_chosen=target "%target%"
) else (
	echo which target?
	goto abort_script
)
if ["%feature_file%"] NEQ [""] (
	echo '%FeatureName%' feature..
)



	rem some sanity checking
if [%ghost%]==[] if [%native%]==[] (	
	rem we do native build by default
	set native=native
)


	
	rem build the thing
call halwayiWrapper.bat %native% %ghost% %halwayi_target%%debug% %feature_file% %target_chosen%

if errorlevel 1 (
	exit /b 1
)

	
	rem exit if cannot, or not asked to, flash
if [%clean%]==[true]	goto exit_script
if [%program%]==[false]	goto exit_script

echo Attempting to flash the target..
set params=
if [%program_with_power%]==[true] (
	set params=fp
)
if ["%debug%"] NEQ [""] (
	set debug=debug
)
call flash.bat %params% %native% %ghost% %debug% %target_chosen% %FeatureName%
if errorlevel 1 (
	exit /b 1
)

:exit_script
echo Done.

:abort_script