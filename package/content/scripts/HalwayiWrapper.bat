@echo off

rem Copyright Bhavnit Singh Bajwa   iobajwa@gmail.com
rem Please refer to Halwayi's license agreement for more details


IF NOT exist "%HalwayiToolsRoot%\halwayiDelegator.bat" (
	echo Could not find halwayiDelegator.bat!
	exit /b 1
)


pushd "%CD%"
cd %ProjectRoot%

call %HalwayiToolsRoot%\halwayiDelegator.bat %*

if %ERRORLEVEL% GTR 0 (
	popd
	exit /b %ERRORLEVEL%
)

popd
