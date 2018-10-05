rem Copyright Bhavnit Singh Bajwa   iobajwa@gmail.com
rem Please refer to Halwayi's license agreement for more details

	rem Settings for the tandoor project, slightly tedious
set ProjectRoot=%CD%\..\..\..\tandoor
set ToolsRoot=%CD%\..\tools
set HalwayiToolsRoot=%CD%\..
set ScriptsRoot=%ProjectRoot%\scripts
set MagicRoot=%ScriptsRoot%
set CodeRoot=%ProjectRoot%\code
set FeatureCodeRoot=%CodeRoot%\features
set FeatureSourceName=main.c
set BinRoot=%ProjectRoot%\bin
set ArtifactsRoot=%ProjectRoot%\artifacts
set BuildMagicRoot=%ArtifactsRoot%\scripts
set RecipesRoot=%ProjectRoot%\recipes
set FeaturesRoot=%ProjectRoot%\features
set ProjectFile=%ProjectRoot%\project.properties
set GhostToolchain=gcc
set TargetsRoot=%MagicRoot%\targets
rem set GhostToolchain=vcc

set FlashTool=jlink
rem set FlashTool=nsprog
rem set FlashTool=mdb
