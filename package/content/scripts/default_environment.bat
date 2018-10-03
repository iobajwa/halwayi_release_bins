rem Copyright Bhavnit Singh Bajwa   iobajwa@gmail.com
rem Please refer to Halwayi's license agreement for more details

	rem settings related to building tests/features and running them
set CoresUsage=%NUMBER_OF_PROCESSORS%
set GhostTimeoutPeriod=400
set SimulatorTimeoutPeriod=10000
set FlashTool=pickit3
set FlashToolInterface=SWD

	rem settings related to project structure
set ProjectRoot=%CD%\..
set DocsRoot=%ProjectRoot%\docs
set ToolsRoot=%ProjectRoot%\tools
set HalwayiToolsRoot=%ToolsRoot%\halwayi
set ScriptsRoot=%ProjectRoot%\scripts
set TargetsRoot=%MagicRoot%\targets
set CodeRoot=%ProjectRoot%\code
set CodeLibRoot=%CodeRoot%\lib
set BinRoot=%ProjectRoot%\bin
set ArtifactsRoot=%ProjectRoot%\artifacts
set RecipesRoot=%ScriptsRoot%\recipes
set FeaturesRoot=%ProjectRoot%\features
set ProjectFile=%ProjectRoot%\project.properties
set BuildMagicRoot=%ArtifactsRoot%\scripts
set FeatureSourceName=main.c
set FeatureCodeRoot=%CodeRoot%\features
set TestReportName=results.xml
set CTypesFile=boski.h


	rem default paths for flash tools
IF exist "C:\Program Files\Microchip\MPLABX\mplab_ide\bin\mdb.bat" (
	set "mdbPath=C:\Program Files\Microchip\MPLABX\mplab_ide\bin\mdb.bat"
) else IF exist "C:\Program Files (x86)\Microchip\MPLABX\mplab_ide\bin\mdb.bat" (
	set "mdbPath=C:\Program Files (x86)\Microchip\MPLABX\mplab_ide\bin\mdb.bat" 
) else (
	set mdbPath="x:\"
)

if exist "C:\Program Files (x86)\SEGGER\JLink_V630h\JLink.exe" (
	set "jlinkPath=C:\Program Files (x86)\SEGGER\JLink_V630h\JLink.exe"
) else IF exist "C:\Program Files\SEGGER\JLink_V630h\JLink.exe" (
	set "jlinkPath="C:\Program Files\SEGGER\JLink_V630h\JLink.exe""
) else (
	set jlinkPath="x:\"
)

if exist "C:\Program Files (x86)\STMicroelectronics\STM32 ST-LINK Utility\ST-LINK Utility\ST-LINK_CLI.exe" (
	set "stlinkPath=C:\Program Files (x86)\STMicroelectronics\STM32 ST-LINK Utility\ST-LINK Utility\ST-LINK_CLI.exe"
) else IF exist "C:\Program Files\STMicroelectronics\STM32 ST-LINK Utility\ST-LINK Utility\ST-LINK_CLI.exe" (
	set "stlinkPath=C:\Program Files\STMicroelectronics\STM32 ST-LINK Utility\ST-LINK Utility\ST-LINK_CLI.exe"
) else (
	set stlinkPath="x:\"
)
