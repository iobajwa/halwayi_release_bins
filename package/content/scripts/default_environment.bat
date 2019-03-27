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
set ArtifactsRoot=%ProjectRoot%\artifacts
set BinRoot=%ProjectRoot%\bin
set PackagesRoot=%ArtifactsRoot%\packages
set BuildMagicRoot=%ArtifactsRoot%\scripts
set ToolsRoot=%PackagesRoot%
set HalwayiToolsRoot=%ToolsRoot%\halwayi
set HalwayiMagicRoot=%ToolsRoot%\halwayi\scripts
set CodeRoot=%ProjectRoot%\code
set SourceRoot=%CodeRoot%\source
set MagicRoot=%ScriptsRoot%
set TargetsRoot=%MagicRoot%\targets
set RecipesRoot=%ScriptsRoot%\recipes
set FeaturesRoot=%ProjectRoot%\features
set FeatureCodeRoot=%CodeRoot%\features
set ProjectFile=%ProjectRoot%\project.properties
set CTypesFile=boski.h
set DocsRoot=%ProjectRoot%\docs
set ScriptsRoot=%ProjectRoot%\scripts
set CodeLibRoot=%CodeRoot%\lib
set FeatureSourceName=main.c
set TestReportName=results.xml


	rem default paths for flash tools
IF exist "C:\Program Files\Microchip\MPLABX\mplab_ide\bin\mdb.bat" (
	set "mdbPath=C:\Program Files\Microchip\MPLABX\mplab_ide\bin\mdb.bat"
) else IF exist "C:\Program Files (x86)\Microchip\MPLABX\mplab_ide\bin\mdb.bat" (
	set "mdbPath=C:\Program Files (x86)\Microchip\MPLABX\mplab_ide\bin\mdb.bat" 
) else (
	set mdbPath="c:\dummy-nonexistant-path"
)

if exist "C:\Program Files (x86)\SEGGER\JLink_V630h\JLink.exe" (
	set "jlinkPath=C:\Program Files (x86)\SEGGER\JLink_V630h\JLink.exe"
) else IF exist "C:\Program Files\SEGGER\JLink_V630h\JLink.exe" (
	set "jlinkPath="C:\Program Files\SEGGER\JLink_V630h\JLink.exe""
) else (
	set jlinkPath="c:\dummy-nonexistant-path"
)

if exist "C:\Program Files (x86)\STMicroelectronics\STM32 ST-LINK Utility\ST-LINK Utility\ST-LINK_CLI.exe" (
	set "stlinkPath=C:\Program Files (x86)\STMicroelectronics\STM32 ST-LINK Utility\ST-LINK Utility\ST-LINK_CLI.exe"
) else IF exist "C:\Program Files\STMicroelectronics\STM32 ST-LINK Utility\ST-LINK Utility\ST-LINK_CLI.exe" (
	set "stlinkPath=C:\Program Files\STMicroelectronics\STM32 ST-LINK Utility\ST-LINK Utility\ST-LINK_CLI.exe"
) else (
	set stlinkPath="c:\dummy-nonexistant-path"
)
