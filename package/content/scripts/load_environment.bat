rem Copyright Bhavnit Singh Bajwa   iobajwa@gmail.com
rem Please refer to Halwayi's license agreement for more details

call  default_environment.bat

rem let the user override any of these
if EXIST environment.bat (
	call environment.bat
) else IF exist "..\environment.bat" (
	call "..\environment.bat"
) else IF exist "..\..\environment.bat" (
	call "..\..\environment.bat"
) else IF exist "..\..\..\environment.bat" (
	call "..\..\..\environment.bat"
) else IF exist "..\..\..\..\environment.bat" (
	call "..\..\..\..\environment.bat"
) else IF exist "..\..\..\..\..\environment.bat" (
	call "..\..\..\..\..\environment.bat"
) else IF exist "..\..\..\..\..\..\environment.bat" (
	call "..\..\..\..\..\..\environment.bat"
) else IF exist "..\..\..\..\..\..\..\environment.bat" (
	call "..\..\..\..\..\..\..\environment.bat"
) else IF exist "..\..\..\..\..\..\..\..\environment.bat" (
	call "..\..\..\..\..\..\..\..\environment.bat"
)

	rem flush error code from last run
ver > nul
set ERRORLEVEL=0
	