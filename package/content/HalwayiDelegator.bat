@echo off

rem Copyright Bhavnit Singh Bajwa   iobajwa@gmail.com
rem Please refer to Halwayi's license agreement for more details

set clean=false
set build=false
set testFile=
set onlyFileName=
set msbuild_target=
set xmlReport=
set buildNative=false
set buildGhost=false
set deltaRun=
set selectedTarget=
set showToolLog=
set releaseOrDebugBuild=false
set projectToLoad=%CD%\project.properties
set featureToBuild=
set run_after_test=true

	rem Parse command line switches to figure out what to do
:parse_parameter_flags
		IF [%1]==[] (
			GOTO end_parse
		) else IF [%1]==[prj] (
			set projectToLoad=%2
			SHIFT
		) else IF [%1]==[feature] (
			set featureToBuild=%2
			SHIFT
		) else IF [%1]==[native] (
			set buildNative=true
		) else IF [%1]==[gui] (
			set guiRunner=true
		) else IF [%1]==[console] (
			set consoleRunner=true
		) else IF [%1]==[xml] (
			set xmlReport="/xml=%2"
			SHIFT
		) else IF [%1]==[ghost] (
			set buildGhost=true
		) else IF [%1]==[delta] (
			set deltaRun=--delta=%date% %time%
		) else IF [%1]==[target] (
			set selectedTarget=%~2
			SHIFT
		) else IF [%1]==[toolLog] (
			set showToolLog=/toolLog
		) else IF [%1]==[halwayiPath] (
			IF [%2]==[] (
				echo halwayi path not provided..
				goto exit_script
			)
			set halwayiPath=%2
			SHIFT
		) else IF [%1]==[clean] (
			set clean=true
			set testFile=%2
			IF [%2]==[] (
				echo Cleaning all..
				set msbuild_target=cleanAll
			) else (
				echo Cleaning Test: %2..
				set msbuild_target=clean
			)
			SHIFT
		) else IF [%1]==[build] ( 
			set build=true
			set testFile=%2
			set onlyFileName=%~n2
			IF [%2]==[] (
				rem echo Building all..
				set msbuild_target=buildAll
			) else (
				rem echo Building Test: %2..
				set msbuild_target=build
			)
			SHIFT
		) else IF [%1]==[releaseAll] (
			set msbuild_target=ReleaseAll
			set releaseOrDebugBuild=true
			set build=true
		) else IF [%1]==[releaseAllForDebug] (
			set msbuild_target=ReleaseAllForDebug
			set releaseOrDebugBuild=true
			set build=true
		) else IF [%1]==[cleanReleaseAll] (
			set msbuild_target=CleanReleaseAll
			set clean=true
		) else IF [%1]==[cleanReleaseAllForDebug] (
			set msbuild_target=CleanReleaseAllForDebug
			set clean=true
		) else IF [%1]==[quiet] (
			set verbosity=q
		) else IF [%1]==[q] (
			set verbosity=q
		) else IF [%1]==[normal] (
			set verbosity=n
		) else IF [%1]==[n] (
			set verbosity=n
		) else IF [%1]==[diagnose] (
			set verbosity=d
		) else IF [%1]==[d] (
			set verbosity=d
		) else IF [%1]==[minimal] (
			set verbosity=m
		) else IF [%1]==[m] (
			set verbosity=m
		) else (
			ECHO unknown flag '%1'. 
			exit /b 1
		)
		SHIFT
	GOTO parse_parameter_flags
:end_parse


	

	rem Some sanity check
if [%clean%]==[true] if [%build%]==[true] (
	ECHO cannot build and clean simulataneously
	exit /b 1
)

if ["%verbosity%"]==[""] (
	set verbosity=n
)

if [%buildGhost%]==[false] if [%buildNative%]==[false] (
	set buildGhost=true
)

if NOT EXIST %projectToLoad% (
	set projectToLoad=%CD%\project\project.properties
)

if %clean%==false if %build%==false (
	ECHO Usage
	ECHO 	- "prj <filename>" to load a specific project, 
	ECHO 	  otherwise, the default "project.properties" is built
	ECHO 	- "feature <filename>" to build a release using the
	ECHO 	  specificied feature.
	ECHO .
	ECHO 	- "build <filename>" to build and test a single file
	ECHO 	- "build" to build and run all
	ECHO 	- "clean <filename>" to clean a single file
	ECHO 	- "clean" to clean all
	ECHO 	- "releaseAll" to build a Release build in 'Release' 
	ECHO 	  configuration
	ECHO 	- "releaseAllForDebug" to build a Release build in
	ECHO 	  'Debug' configuration
	ECHO 	- "cleanReleaseAll" to clean a release build
	ECHO 	- "cleanReleaseAllForDebug" to clean a debug build
	ECHO .
	ECHO 	- "native" to build native executables
	ECHO 	- "ghost" to build ghost executables
	ECHO .	
	ECHO 	- "q" for verbosity set to quite
	ECHO 	- "n" for verbosity set to normal
	ECHO 	- "m" for verbosity set to minimal
	ECHO 	- "d" for verbosity set to diagnostics
	ECHO .	
	ECHO 	- "gui" for executing tests in Runner GUI version
	ECHO 	   By default Runner console version is employed
	ECHO 	- "xml <filename>" to generate an nUnit compatible xml
	ECHO 	  test report named "<filename>"
	ECHO 	- "toolLog" to display tool output onto the console.
	ECHO 	- "delta" to run only those tests which have witnessed
	ECHO 	  a change.
	ECHO .	
	ECHO 	- "halwayiPath <path>" to specify a different path to
	ECHO 	  halwayi than the default "$(ROOT)\tools\halwayi" path
	ECHO .
	ECHO 	- "var <variant name>" to perform the selected action on
	ECHO 	  only the provided "<variant name>".	
	GOTO exit_script
)

msbuild "%HalwayiToolsRoot%\project.builder" /v:%verbosity% /nologo /t:%msbuild_target% /p:ProjectFile="%projectToLoad%";BuildNative=%buildNative%;GlobPattern=%testFile%;BuildGhost=%buildGhost%;SelectedTarget=%selectedTarget%;BuildFeature="%featureToBuild%";FeatureName=%FeatureName%;BuildIDE=%build_ide%;GhostToolchainName=%GhostToolchain%


if errorlevel 1 (
	exit /b 1
)
	echo Done.
	echo ____________

:exit_script
	exit /b 0
