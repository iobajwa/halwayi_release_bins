<?xml version="1.0" encoding="utf-8"?>

<!-- 
Copyright Bhavnit Singh Bajwa   iobajwa@gmail.com
Please refer to Halwayi's license agreement for more details
-->

<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003" ToolsVersion="4.0">

  <PropertyGroup>
    <!-- Required Parameters -->
    <BuildNative></BuildNative>
    <BuildGhost></BuildGhost>

    <!-- Properties for internal use -->
    <ArtifactsOutput></ArtifactsOutput>
    <BinOutput></BinOutput>
    <GlobPattern></GlobPattern>
    <SelectedTarget></SelectedTarget>
    <BuildTarget>BuildAll</BuildTarget>
    <ProjectFixtureFileName>project.fixture_config</ProjectFixtureFileName>
    <TargetFile>variant.builder</TargetFile>

    <SelectedTargetError>false</SelectedTargetError>

    <SelectedConfiguration>Release</SelectedConfiguration>
    <BuildFeature></BuildFeature>
    <FeatureCFile></FeatureCFile>
    <FeatureName></FeatureName>
    <BuildIDE>false</BuildIDE>
    <GhostToolchainName></GhostToolchainName>
  </PropertyGroup>

  <PropertyGroup Condition= "$([System.String]::IsNullOrEmpty('$(SelectedTarget)')) == 'false'">
    <SelectedTargetError>true</SelectedTargetError>
  </PropertyGroup>



  <!-- 
  ************************************************************************************************************************
                                              Include External Dependencies
  ************************************************************************************************************************
  -->

  <Import Project="$(MSBuildThisFileDirectory)default.properties" />
  <Import Project="$(ProjectFile)" Condition= "Exists($(ProjectFile))" />
  
  <UsingTask AssemblyFile= "$(BuilderTasksPath)\halwayiTasks.dll" TaskName= "TestFixtureGeneratorTask" />
  <UsingTask AssemblyFile= "$(BuilderTasksPath)\halwayiTasks.dll" TaskName= "CheckMetadataTask" />
  <UsingTask AssemblyFile= "$(BuilderTasksPath)\halwayiTasks.dll" TaskName= "RelativeToAbsolutePathsTask" />
  <UsingTask AssemblyFile= "$(BuilderTasksPath)\halwayiTasks.dll" TaskName= "TransformDefinesTask" />
  <UsingTask AssemblyFile= "$(BuilderTasksPath)\halwayiTasks.dll" TaskName= "RecipeFileListCreationTask" />
  <UsingTask AssemblyFile= "$(BuilderTasksPath)\halwayiTasks.dll" TaskName= "FeatureTask" />
  <UsingTask AssemblyFile= "$(BuilderTasksPath)\halwayiTasks.dll" TaskName= "FilterVariantPlatformTask" />
  <UsingTask AssemblyFile= "$(BuilderTasksPath)\halwayiTasks.dll" TaskName= "ClubVariantPlatformTask" />
  <UsingTask AssemblyFile= "$(BuilderTasksPath)\halwayiTasks.dll" TaskName= "TargetParserTask" />
  <UsingTask AssemblyFile= "$(BuilderTasksPath)\halwayiTasks.dll" TaskName= "FilterTargetsTask" />








  <!-- 
  ************************************************************************************************************************
                                                     Public Targets
  ************************************************************************************************************************
  -->


  <!-- 
    Builds all test files found 
    Builds all tests in the $(SelectedTarget) if a variant has been provided.
    -->
  <Target Name= "BuildAll" DependsOnTargets= "_SanityCheckBuildAll;_CreateArtifactsAndBinRootFoldersForTests;
                                                _DelegateWorkToVariantBuilder;_CreateTestFixtureFile">
  </Target>



  <!-- 
    Builds all test files matching the provided filter criteria 
    Builds all test files matching in the $(SelectedTarget) if a variant has been provided.
  -->
  <Target Name= "Build" DependsOnTargets= "_SanityCheckBuild;_DisplayContextBuild;BuildAll;_CreateTestFixtureFile">
  </Target>
  
  
  
  <!-- 
    Performs clean on all Tests: Deletes  $(ArtifactRoot)\$(_VariantName)\*    $(BinRoot)\$(_VariantName)\* 
    Cleans only the $(SelectedTarget) if a variant has been provided.
  -->
  <Target Name= "CleanAll" DependsOnTargets= "_SanityCheckCleanAll;_SetupOutputFolderPropertiesForTests;_DelegateWorkToVariantBuilder">
  </Target>


  <!-- 
    Cleans all test files matching the provided filter criteria 
    Cleans only matching files in the $(SelectedTarget) if a variant has been provided
  -->
  <Target Name= "Clean" DependsOnTargets="_SanityCheckClean;_SetupOutputFolderPropertiesForTests;_DisplayContextClean;_DelegateWorkToVariantBuilder">
  </Target>


  <!-- 
    Builds only the source files for every variant and creates a executable in 'release' configuration.
    Like all other build related tasks, Incremental building is performed.
  -->
  <Target Name= "ReleaseAll" DependsOnTargets="_SanityReleaseAll;_SetupOutputFolderPropertiesForRelease;_PerformSetupForNonTestTargets;_DelegateWorkToVariantBuilder">
  </Target>



  <!-- 
    Builds only the source files for every variant and creates a executable in 'debug' configuration.
    Like all other build related tasks, Incremental building is performed.
  -->
  <Target Name= "ReleaseAllForDebug" DependsOnTargets="_SanityReleaseAll;_SetupForDebugConfiguration;_SetupOutputFolderPropertiesForRelease;_PerformSetupForNonTestTargets;_DelegateWorkToVariantBuilder">
  </Target>



  <!-- 
    Performs clean on Releases: Deletes  $(ArtifactRoot)\Release\$(_VariantName)\*    $(BinRoot)\Release\$(_VariantName)\* 
    Cleans only the $(SelectedTarget) if a variant has been provided.
  -->
  <Target Name= "CleanReleaseAll" DependsOnTargets= "_SanityCheckCleanAll;_SetupOutputFolderPropertiesForRelease;_PerformSetupForNonTestTargets;_DelegateWorkToVariantBuilder">
  </Target>



  <!-- 
    Performs clean on Debug Releases: Deletes  $(ArtifactRoot)\Release\$(_VariantName)\*    $(BinRoot)\Release\$(_VariantName)\* 
    Cleans only the $(SelectedTarget) if a variant has been provided.
  -->
  <Target Name= "CleanReleaseAllForDebug" DependsOnTargets= "_SanityCheckCleanAll;_SetupForDebugConfiguration;_SetupOutputFolderPropertiesForRelease;_PerformSetupForNonTestTargets;_DelegateWorkToVariantBuilder">
  </Target>









  <!--
  ************************************************************************************************************************
                                                     Internal Targets
  ************************************************************************************************************************
  -->

  <!-- ========================================
      Targets shared by multiple Public Targets
  ========================================= -->

  <Target Name= "_DelegateWorkToVariantBuilder" DependsOnTargets="_CreateVariantBatch" Outputs= "%(TargetsFiltered.Identity)">

    <Message Text= "=== %(TargetsFiltered.Variant) : %(TargetsFiltered.Platform) ===" Importance="high" Condition="'@(TargetsFiltered->Count())' &gt; 1"/>
    
        <!-- Setup default settings if none has been provided for this variant -->
        <CheckMetadataTask Items="@(TargetsFiltered)" ItemToSearch="%(TargetsFiltered.Identity)" MetadataToCheck="Recipes">
          <Output PropertyName="__containsRecipeFolders" TaskParameter="ContainsMetadata" />
        </CheckMetadataTask>
        <CheckMetadataTask Items="@(TargetsFiltered)" ItemToSearch="%(TargetsFiltered.Identity)" MetadataToCheck="ToolScripts">
          <Output PropertyName="__containsToolScripts" TaskParameter="ContainsMetadata" />
        </CheckMetadataTask>
        <CheckMetadataTask Items= "@(TargetsFiltered)" ItemToSearch="%(TargetsFiltered.Identity)" MetadataToCheck="ReleaseDefines">
          <Output PropertyName= "__containsReleaseDefines" TaskParameter= "ContainsMetadata" />
        </CheckMetadataTask>
        <CheckMetadataTask Items= "@(TargetsFiltered)" ItemToSearch="%(TargetsFiltered.Identity)" MetadataToCheck="TestDefines">
          <Output PropertyName= "__containsTestDefines" TaskParameter= "ContainsMetadata" />
        </CheckMetadataTask>


        <!-- Use the default values if none has been provided-->
        <PropertyGroup>
          <_tv_RecipeFolders Condition=" '$(__containsRecipeFolders)' == 'False' " >$(RecipesRoot)</_tv_RecipeFolders>
          <_tv_ToolScripts Condition=" '$(__containsToolScripts)' == 'False' " >$(ScriptsRoot)\config</_tv_ToolScripts>
          <_tv_ProjectSwitch>__$(ProjectName.Trim().ToUpper().Replace(' ', '_').Replace('-', '_'))__</_tv_ProjectSwitch>
        </PropertyGroup>

        <PropertyGroup Condition= " '$(BuildFeature)' != '' AND Exists($(BuildFeature))">
          <_tv_FeatureSwitch>$([System.IO.Path]::GetFilenameWithoutExtension('$(BuildFeature)'))</_tv_FeatureSwitch>
          <_tv_FeatureSwitch>__$(_tv_FeatureSwitch.Trim().ToUpper().Replace(' ', '_').Replace('-', '_'))_FEATURE__</_tv_FeatureSwitch>
        </PropertyGroup>


        <!-- Else use the ones that have been provided -->
        <PropertyGroup>
          <_tv_testDefines Condition=" '$(__containsTestDefines)' == 'True'" >%(TargetsFiltered.TestDefines)</_tv_testDefines>
          <_tv_ReleaseDefines Condition=" '$(__containsReleaseDefines)' == 'True'" >%(TargetsFiltered.ReleaseDefines)</_tv_ReleaseDefines>
          <_tv_RecipeFolders Condition=" '$(__containsRecipeFolders)' == 'True' ">%(TargetsFiltered.Recipes)</_tv_RecipeFolders>
          <_tv_ToolScripts Condition=" '$(__containsToolScripts)' == 'True' ">%(TargetsFiltered.ToolScripts)</_tv_ToolScripts>
          <_tv_TestFolders>%(TargetsFiltered.TestFolders)</_tv_TestFolders>
          <_tv_SourceFolders>%(TargetsFiltered.SourceFolders)</_tv_SourceFolders>
          <_tv_FeatureFolders>%(TargetsFiltered.FeatureFolders)</_tv_FeatureFolders>
        </PropertyGroup>


        <!-- Some sanity check -->
        <Error Text="%(TargetsFiltered.Identity) (%(TargetsFiltered.Variant)+%(TargetsFiltered.Platform)) target has no TestFolders defined." Condition="'$(ReleaseBuild)' != 'true' AND '$([System.String]::IsNullOrWhiteSpace($(_tv_TestFolders)))' == 'true'" />
        <Error Text="%(TargetsFiltered.Identity) (%(TargetsFiltered.Variant)+%(TargetsFiltered.Platform)) target has no SourceFolders defined." Condition="'$(ReleaseBuild)' == 'true' AND '$([System.String]::IsNullOrWhiteSpace($(_tv_SourceFolders)))' == 'true'" />
        <Error Text="%(TargetsFiltered.Identity) (%(TargetsFiltered.Variant)+%(TargetsFiltered.Platform)) target has no FeatureFolders defined." Condition="'$(ReleaseBuild)' == 'true' AND '$([System.String]::IsNullOrWhiteSpace($(_tv_FeatureFolders)))' == 'true'" />


    <!-- Append project switch -->
    <PropertyGroup>
      <_tv_ReleaseDefines>$(_tv_ProjectSwitch);$(_tv_FeatureSwitch);$(_tv_ReleaseDefines)</_tv_ReleaseDefines>
      <_tv_testDefines>$(_tv_ProjectSwitch);$(_tv_testDefines)</_tv_testDefines>
    </PropertyGroup>


    <TransformDefinesTask Directives="$(_tv_ReleaseDefines)" Symbol=" " Replacement="?">
      <Output PropertyName= "_tv_ReleaseDefines" TaskParameter= "ProcessedOutput" />
    </TransformDefinesTask>


    <!-- ================================= -->
              <!-- Find Recipes -->
        <!-- Convert relative folder paths to full paths -->
        <RelativeToAbsolutePathsTask PathsToCheck="$(_tv_RecipeFolders)" Root="$(ProjectRoot)" Condition= " '$([System.String]::IsNullOrWhiteSpace($(_tv_RecipeFolders)))' == 'false' AND '$(ReleaseBuild)' == 'true' " >
          <Output PropertyName="_tv_RecipeFolders" TaskParameter="ConvertedPaths" />
        </RelativeToAbsolutePathsTask>

        <PropertyGroup Condition=" '$(ReleaseBuild)' == 'true' ">
          <RecipeListFile>$(EtcFolder)\%(TargetsFiltered.Identity).recipe_list</RecipeListFile>
        </PropertyGroup>

        <ItemGroup Condition= " '$(ReleaseBuild)' == 'true' ">
          <RecipeFolderItems Include="$(_tv_RecipeFolders.Split(';'))" />
          <RecipeFiles Include="%(RecipeFolderItems.Identity)\*.recipe" />
        </ItemGroup>

        <RecipeFileListCreationTask File="$(RecipeListFile)" Recipes="@(RecipeFiles)" Condition= " '$(ReleaseBuild)' == 'true' " />
    <!-- ================================= -->




    <!-- Finally delegate the work -->

    <PropertyGroup Condition="'$(ReleaseBuild)' == 'true'">
      <NativeCPU>%(TargetsFiltered.ReleaseCPU)</NativeCPU>
      <NativeToolChain>%(TargetsFiltered.ReleaseToolChain)</NativeToolChain>
      <NativeToolChainPath>%(TargetsFiltered.ReleaseToolChainPath)</NativeToolChainPath>
      <NativeToolChainTimeout>%(TargetsFiltered.ReleaseToolChainTimeoutPeriod)</NativeToolChainTimeout>
      <NativeLinkerArgs>%(TargetsFiltered.ReleaseNativeLinkerArgs)</NativeLinkerArgs>
      <NativeCompilerArgs>%(TargetsFiltered.ReleaseNativeCompilerArgs)</NativeCompilerArgs>
      <GhostCompilerArgs>%(TargetsFiltered.ReleaseGhostCompilerArgs)</GhostCompilerArgs>
      <GhostLinkerArgs>%(TargetsFiltered.ReleaseGhostLinkerArgs)</GhostLinkerArgs>
    </PropertyGroup>
    <PropertyGroup Condition="'$(ReleaseBuild)' != 'true'">
      <NativeCPU>%(TargetsFiltered.TestCPU)</NativeCPU>
      <NativeToolChain>%(TargetsFiltered.TestToolChain)</NativeToolChain>
      <NativeToolChainPath>%(TargetsFiltered.TestToolChainPath)</NativeToolChainPath>
      <NativeToolChainTimeout>%(TargetsFiltered.TestToolChainTimeoutPeriod)</NativeToolChainTimeout>
      <NativeLinkerArgs>%(TargetsFiltered.TestNativeLinkerArgs)</NativeLinkerArgs>
      <NativeCompilerArgs>%(TargetsFiltered.TestNativeCompilerArgs)</NativeCompilerArgs>
      <GhostCompilerArgs>%(TargetsFiltered.TestGhostCompilerArgs)</GhostCompilerArgs>
      <GhostLinkerArgs>%(TargetsFiltered.TestGhostLinkerArgs)</GhostLinkerArgs>
    </PropertyGroup>



    <ItemGroup>
      <FeatureFoldersItem Include="$(_tv_FeatureFolders)" />
    </ItemGroup>
    <RelativeToAbsolutePathsTask PathsToCheck="$(_tv_FeatureFolders)" Root="$(ProjectRoot)">
      <Output  ItemName     = "__FeatureFoldersItem"  TaskParameter = "ConvertedPathsItem" />
      <Output  PropertyName = "_tv_FeatureFolders"    TaskParameter = "ConvertedPaths" />
    </RelativeToAbsolutePathsTask>
    <ItemGroup>
      <FeatureFoldersItem Remove="%(FeatureFoldersItem.Identity)" />
      <FeatureFoldersItem Include="%(__FeatureFoldersItem.Identity)" />
    </ItemGroup>

    <!-- Resolve Feature -->
    <FeatureTask UserHint= "$(BuildFeature)" 
                 FeaturesRoot= "@(FeatureFoldersItem)"
                 FeaturesCodeRoot= "@(FeatureFoldersItem)"
                 OutputFolder= "$(EtcFolder)"
                 FeatureSourceName= "$(FeatureSourceName)"
                 FeatureNamingPattern="$(FeatureNamingPattern)"
                 FeatureFileExtension="$(FeatureFileExtension)"
                 FinalFeatureName="$(FinalFeatureName)"
                 SourcePaths="$(CodeRoot)\source"
                 Condition=" '$(ReleaseBuild)' == 'true' "
                 >
      <Output PropertyName= "BuildFeature" TaskParameter= "FeatureFile" />
      <Output PropertyName= "FeatureCFile" TaskParameter= "FeatureMetaFile" />
    </FeatureTask>



    <MSBuild Projects= "$(TargetsToolPath)\$(TargetFile)"
             Targets= "$(BuildTarget)"
             Properties= " _TargetName = %(TargetsFiltered.Identity); _VariantName = %(TargetsFiltered.Variant);
                           _PlatformName = %(TargetsFiltered.Platform); _VariantSwitch = %(TargetsFiltered.Switch);
                           ProjectFile = $(ProjectFile); _NativeToolChain = $(NativeToolChain); 
                           _TestFolders = %(TestFolders); 
                           _SourceFolders = %(SourceFolders); _SupportFolders = %(TargetsFiltered.SupportFolders); 
                           _NativeSourceFolders = %(TargetsFiltered.NativeSourceFolders); _GhostSourceFolders = %(TargetsFiltered.GhostSourceFolders); 
                           _NativeSupportFolders = %(TargetsFiltered.NativeSupportFolders); _GhostSupportFolders = %(TargetsFiltered.GhostSupportFolders); 
                           _IncludeFolders = %(TargetsFiltered.IncludeFolders);  BuildNativeAsWell = $(BuildNative); BuildGhostAsWell = $(BuildGhost);
                           PassedGlob = $(GlobPattern); ArtifactsFolderRoot = $(ArtifactsOutput); 
                           BinFolderRoot = $(BinOutput); NativeCPU = $(NativeCPU); 
                           Defines = $(_tv_testDefines); ReleaseDefines = $(_tv_ReleaseDefines);
                           DefaultPropertyFile = $(MSBuildThisFileDirectory)default.properties; FeatureName = $(FeatureName); IdeFolderRoot = $(IdeFolder);
                           SelectedConfiguration = $(SelectedConfiguration); BuildFeature = $(BuildFeature); FeatureCFile = $(FeatureCFile);
                           NativeLinkerArgs = $(NativeLinkerArgs); RecipeListFile = $(RecipeListFile);
                           ToolScriptsFolders = $(_tv_ToolScripts); ToolChainPath = $(NativeToolChainPath);
                           ToolChainTimeoutPeriod = $(NativeToolChainTimeout); PlatformName = %(TargetsFiltered.Platform);
                           NativeCompilerArgs = $(NativeCompilerArgs); GhostCompilerArgs = $(GhostCompilerArgs); GhostLinkerArgs = $(GhostLinkerArgs);
                           BuildIDE = $(BuildIDE); GhostToolname=$(GhostToolchainName);
                        "
             />
  </Target>


  <Target Name="_CreateVariantBatch">

    <TargetParserTask
        Targets="@(Targets)"
        Variants="@(Variants)"
        Platforms="@(Platforms)"
        PlatformNameToken="$(PlatformName)"
        KnownToolChains="@(ToolChains)"
        DefaultGhostTimeoutPeriod="$(GhostTimeoutPeriod)"
        DefaultSimulatorTimeoutPeriod="$(SimulatorTimeoutPeriod)"
        GhostToolchain="$(GhostToolchainName)"
      >
      <Output ItemName= "TargetsAll" TaskParameter= "ParsedTargets" />
    </TargetParserTask>

    <FilterTargetsTask
        Targets="@(TargetsAll)"
        UserTargetChoice="$(SelectedTarget)"
      >
      <Output ItemName= "TargetsFiltered" TaskParameter= "FilteredTargets" />
    </FilterTargetsTask>

  </Target>

  
  <Target Name="_SetupOutputFolderPropertiesForTests">
    <PropertyGroup>
      <ArtifactsOutput>$(ArtifactsRoot)\tests</ArtifactsOutput>
      <BinOutput>$(BinRoot)\tests</BinOutput>
    </PropertyGroup>
  </Target>


  <Target Name="_SetupOutputFolderPropertiesForRelease">
    <PropertyGroup>
      <ArtifactsOutput>$(ArtifactsRoot)</ArtifactsOutput>
      <BinOutput>$(BinRoot)</BinOutput>
      <EtcFolder>$(ArtifactsRoot)\etc</EtcFolder>
      <IdeFolder>$(ArtifactsRoot)\ide</IdeFolder>
      <FeatureName>$(BuildFeature)</FeatureName>
    </PropertyGroup>

    <MakeDir Directories="$(EtcFolder)" />
    <MakeDir Directories="$(IdeFolder)" />
  </Target>


  <Target Name="_CreateTestFixtureFile">
    <Message Text="File out-of-date: '$(BinOutput)\$(ProjectFixtureFileName)'. Creating file." Importance="normal" />
    <Message Text="@(Variants)" />

    <TestFixtureGeneratorTask
      Targets="@(TargetsAll)"
      Variants="@(Variants)"
      Platforms="@(Platforms)"
      ProjectName="$(ProjectName)"
      TestFixtureFileName="$(BinOutput)\$(ProjectFixtureFileName)"
      KnownToolChains="@(ToolChains)"
      DefaultGhostTimeoutPeriod="$(GhostTimeoutPeriod)"
      DefaultSimulatorTimeoutPeriod="$(SimulatorTimeoutPeriod)"
      />
  </Target>


  <Target Name= "_SanityCheckSelectedTarget" Condition= "$([System.String]::IsNullOrEmpty('$(SelectedTarget)')) == 'false'" DependsOnTargets= "_CheckSelectedVariantAgainstAllTargetNames">
    <Error Text= "Target '$(SelectedTarget)' not found" Condition= "'$(SelectedTargetError)' == 'true' " />
  </Target>

  <Target Name= "_CheckSelectedVariantAgainstAllTargetNames" Condition= "$([System.String]::IsNullOrEmpty('$(SelectedTarget)')) == 'false'" Outputs= "%(Targets.Identity)">
    <PropertyGroup>
      <__thisVariant>%(Targets.Identity)</__thisVariant>
    </PropertyGroup>
    <PropertyGroup Condition= " '$(SelectedTarget)' == '$(__thisVariant)' ">
      <SelectedTargetError>false</SelectedTargetError>
    </PropertyGroup>
  </Target>

  <Target Name= "_PerformSetupForNonTestTargets">
    <PropertyGroup>
      <TargetFile>releaseAll.targets</TargetFile>
      <ReleaseBuild>true</ReleaseBuild>
    </PropertyGroup>
  </Target>

  <Target Name= "_SetupForDebugConfiguration">
    <PropertyGroup>
      <SelectedConfiguration>Debug</SelectedConfiguration>
    </PropertyGroup>
  </Target>
    

  
  




  <!-- ========================================
      'BuildAll' private helper targets 
  ========================================= -->

  <Target Name= "_SanityCheckBuildAll" DependsOnTargets= "_SanityCheckSelectedTarget">
    <Error Text= "Project file '$(ProjectFile)' not found." Condition= " !Exists($(ProjectFile)) " />
    <Error Text= "BuildNative not provided." Condition= " '$(BuildNative)' == '' " />
    <Error Text= "BuildGhost not provided." Condition= " '$(BuildGhost)' == '' " />
    <Error Text= "Nothing to build- neither ghost nor native." Condition= " '$(BuildNative)' == 'false' AND '$(BuildGhost)' == 'false' " />
  </Target>

  
  <Target Name= "_CreateArtifactsAndBinRootFoldersForTests" DependsOnTargets="_SetupOutputFolderPropertiesForTests">
    <MakeDir Directories="$(ArtifactsOutput)" />
    <MakeDir Directories="$(BinOutput)" />
  </Target>


  
  
  
  
  <!-- ========================================
      'ReleaseAll' private helper targets 
  ========================================= -->

  <Target Name= "_SanityReleaseAll" DependsOnTargets="_SanityCheckBuildAll" />
  
  
  
  
  
  <!-- ========================================
      'Build' private helper targets 
  ========================================= -->
  
  <Target Name= "_SanityCheckBuild" DependsOnTargets= "_SanityCheckSelectedTarget">
    <Error Text= "Test File not provided." Condition= " $([System.String]::IsNullOrEmpty('$(GlobPattern)')) == 'true' " />
    <Error Text= "Nothing to build- neither ghost nor native." Condition= " '$(BuildNative)' == 'false' AND '$(BuildGhost)' == 'false' " />
    <PropertyGroup>
      <BuildTarget>Build</BuildTarget>
    </PropertyGroup>
  </Target>

  <Target Name= "_DisplayContextBuild">
    <Message Text= "Building All tests matching '$(GlobPattern)'" Importance="high" />
  </Target>




  <!-- ========================================
      'CleanAll' private helper targets 
  ========================================= -->

  <Target Name= "_SanityCheckCleanAll" DependsOnTargets= "_SanityCheckSelectedTarget">
    <PropertyGroup>
      <BuildTarget>CleanAll</BuildTarget>
    </PropertyGroup>
    <Error Text= "Nothing to clean- neither ghost nor native." Condition= " '$(BuildNative)' == 'false' AND '$(BuildGhost)' == 'false' " />
  </Target>

  <Target Name= "_RemoveRootFolders" Condition ="$([System.String]::IsNullOrEmpty('$(SelectedTarget)')) == 'true'" >
    <RemoveDir Directories="$(ArtifactsOutput)" />
    <RemoveDir Directories="$(BinOutput)" />

    <Message Text= " " Importance= "high" />
    <Message Text= "Deleted Tests Artifacts Root: $(ArtifactsOutput)" Importance= "high" />
    <Message Text= "Deleted Tests Bin Root: $(BinOutput)" Importance= "high" />
  </Target>




  <!-- ========================================
      'Clean' private helper targets 
  ========================================= -->
  <Target Name= "_SanityCheckClean" DependsOnTargets= "_SanityCheckBuild">
    <PropertyGroup>
      <BuildTarget>Clean</BuildTarget>
    </PropertyGroup>
  </Target>

  
  <Target Name= "_DisplayContextClean">
    <Message Text= "Cleaning All tests named '$(GlobPattern)'" Importance="high" />
  </Target>




</Project>
