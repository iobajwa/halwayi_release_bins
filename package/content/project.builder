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
    <SelectedVariant></SelectedVariant>
    <SelectedPlatform></SelectedPlatform>
    <BuildTarget>BuildAll</BuildTarget>
    <ProjectFixtureFileName>project.fixture_config</ProjectFixtureFileName>
    <TargetFile>variant.builder</TargetFile>

    <SelectedVariantError>false</SelectedVariantError>

    <SelectedConfiguration>Release</SelectedConfiguration>
    <BuildFeature></BuildFeature>
    <FeatureCFile></FeatureCFile>
    <FeatureName></FeatureName>
    <BuildIDE>false</BuildIDE>
    <GhostToolchainName></GhostToolchainName>
  </PropertyGroup>

  <PropertyGroup Condition= "$([System.String]::IsNullOrEmpty('$(SelectedVariant)')) == 'false'">
    <SelectedVariantError>true</SelectedVariantError>
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








  <!-- 
  ************************************************************************************************************************
                                                     Public Targets
  ************************************************************************************************************************
  -->


  <!-- 
    Builds all test files found 
    Builds all tests in the $(SelectedVariant) if a variant has been provided.
    -->
  <Target Name= "BuildAll" DependsOnTargets= "_SanityCheckBuildAll;_CreateArtifactsAndBinRootFoldersForTests;
                                                _DelegateWorkToVariantBuilder;_CreateTestFixtureFile">
  </Target>



  <!-- 
    Builds all test files matching the provided filter criteria 
    Builds all test files matching in the $(SelectedVariant) if a variant has been provided.
  -->
  <Target Name= "Build" DependsOnTargets= "_SanityCheckBuild;_DisplayContextBuild;BuildAll;_CreateTestFixtureFile">
  </Target>
  
  
  
  <!-- 
    Performs clean on all Tests: Deletes  $(ArtifactRoot)\$(_VariantName)\*    $(BinRoot)\$(_VariantName)\* 
    Cleans only the $(SelectedVariant) if a variant has been provided.
  -->
  <Target Name= "CleanAll" DependsOnTargets= "_SanityCheckCleanAll;_SetupOutputFolderPropertiesForTests;_DelegateWorkToVariantBuilder">
  </Target>


  <!-- 
    Cleans all test files matching the provided filter criteria 
    Cleans only matching files in the $(SelectedVariant) if a variant has been provided
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
    Cleans only the $(SelectedVariant) if a variant has been provided.
  -->
  <Target Name= "CleanReleaseAll" DependsOnTargets= "_SanityCheckCleanAll;_SetupOutputFolderPropertiesForRelease;_PerformSetupForNonTestTargets;_DelegateWorkToVariantBuilder">
  </Target>



  <!-- 
    Performs clean on Debug Releases: Deletes  $(ArtifactRoot)\Release\$(_VariantName)\*    $(BinRoot)\Release\$(_VariantName)\* 
    Cleans only the $(SelectedVariant) if a variant has been provided.
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

  <Target Name= "_DelegateWorkToVariantBuilder" DependsOnTargets="_CreateVariantBatch" Outputs= "%(VariantsBatch.Identity)">

    <Message Text= "=== %(VariantsBatch.Variant) : %(VariantsBatch.Platform) ===" Importance="high" Condition="'@(VariantsBatch->Count())' &gt; 1"/>
    
        <!-- Setup default settings if none has been provided for this variant -->
        <CheckMetadataTask Items="@(VariantsBatch)" ItemToSearch="%(VariantsBatch.Identity)" MetadataToCheck="Recipes">
          <Output PropertyName="__containsRecipeFolders" TaskParameter="ContainsMetadata" />
        </CheckMetadataTask>
        <CheckMetadataTask Items="@(VariantsBatch)" ItemToSearch="%(VariantsBatch.Identity)" MetadataToCheck="ToolScripts">
          <Output PropertyName="__containsToolScripts" TaskParameter="ContainsMetadata" />
        </CheckMetadataTask>
        <CheckMetadataTask Items= "@(VariantsBatch)" ItemToSearch="%(VariantsBatch.Identity)" MetadataToCheck="ReleaseDefines">
          <Output PropertyName= "__containsReleaseDefines" TaskParameter= "ContainsMetadata" />
        </CheckMetadataTask>
        <CheckMetadataTask Items= "@(VariantsBatch)" ItemToSearch="%(VariantsBatch.Identity)" MetadataToCheck="TestDefines">
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
          <_tv_testDefines Condition=" '$(__containsTestDefines)' == 'True'" >%(VariantsBatch.TestDefines)</_tv_testDefines>
          <_tv_ReleaseDefines Condition=" '$(__containsReleaseDefines)' == 'True'" >%(VariantsBatch.ReleaseDefines)</_tv_ReleaseDefines>
          <_tv_RecipeFolders Condition=" '$(__containsRecipeFolders)' == 'True' ">%(VariantsBatch.Recipes)</_tv_RecipeFolders>
          <_tv_ToolScripts Condition=" '$(__containsToolScripts)' == 'True' ">%(VariantsBatch.ToolScripts)</_tv_ToolScripts>
          <_tv_TestFolders>%(VariantsBatch.TestFolders)</_tv_TestFolders>
          <_tv_SourceFolders>%(VariantsBatch.SourceFolders)</_tv_SourceFolders>
        </PropertyGroup>


        <!-- Some sanity check -->
        <Error Text="Variant+Platform (%(VariantsBatch.Variant)+%(VariantsBatch.Platform)) configuration has no TestFolders defined." Condition="'$(ReleaseBuild)' != 'true' AND '$([System.String]::IsNullOrWhiteSpace($(_tv_TestFolders)))' == 'true'" />
        <Error Text="Variant+Platform (%(VariantsBatch.Variant)+%(VariantsBatch.Platform)) configuration has no SourceFolders defined." Condition="'$(ReleaseBuild)' == 'true' AND '$([System.String]::IsNullOrWhiteSpace($(_tv_SourceFolders)))' == 'true'" />


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
          <RecipeListFile>$(EtcFolder)\%(VariantsBatch.Identity).recipe_list</RecipeListFile>
        </PropertyGroup>

        <ItemGroup Condition= " '$(ReleaseBuild)' == 'true' ">
          <RecipeFolderItems Include="$(_tv_RecipeFolders.Split(';'))" />
          <RecipeFiles Include="%(RecipeFolderItems.Identity)\*.recipe" />
        </ItemGroup>

        <RecipeFileListCreationTask File="$(RecipeListFile)" Recipes="@(RecipeFiles)" Condition= " '$(ReleaseBuild)' == 'true' " />
    <!-- ================================= -->




    <!-- Finally delegate the work -->

    <PropertyGroup Condition="'$(ReleaseBuild)' == 'true'">
      <NativeCPU>%(VariantsBatch.ReleaseCPU)</NativeCPU>
      <NativeToolChain>%(VariantsBatch.ReleaseToolChain)</NativeToolChain>
      <NativeToolChainPath>%(VariantsBatch.ReleaseToolChainPath)</NativeToolChainPath>
      <NativeToolChainTimeout>%(VariantsBatch.ReleaseToolChainTimeoutPeriod)</NativeToolChainTimeout>
      <NativeLinkerArgs>%(VariantsBatch.ReleaseNativeLinkerArgs)</NativeLinkerArgs>
      <NativeCompilerArgs>%(VariantsBatch.ReleaseNativeCompilerArgs)</NativeCompilerArgs>
      <GhostCompilerArgs>%(VariantsBatch.ReleaseGhostCompilerArgs)</GhostCompilerArgs>
      <GhostLinkerArgs>%(VariantsBatch.ReleaseGhostLinkerArgs)</GhostLinkerArgs>
    </PropertyGroup>
    <PropertyGroup Condition="'$(ReleaseBuild)' != 'true'">
      <NativeCPU>%(VariantsBatch.TestCPU)</NativeCPU>
      <NativeToolChain>%(VariantsBatch.TestToolChain)</NativeToolChain>
      <NativeToolChainPath>%(VariantsBatch.TestToolChainPath)</NativeToolChainPath>
      <NativeToolChainTimeout>%(VariantsBatch.TestToolChainTimeoutPeriod)</NativeToolChainTimeout>
      <NativeLinkerArgs>%(VariantsBatch.TestNativeLinkerArgs)</NativeLinkerArgs>
      <NativeCompilerArgs>%(VariantsBatch.TestNativeCompilerArgs)</NativeCompilerArgs>
      <GhostCompilerArgs>%(VariantsBatch.TestGhostCompilerArgs)</GhostCompilerArgs>
      <GhostLinkerArgs>%(VariantsBatch.TestGhostLinkerArgs)</GhostLinkerArgs>
    </PropertyGroup>

    <MSBuild Projects= "$(TargetsToolPath)\$(TargetFile)"
             Targets= "$(BuildTarget)"
             Properties= "_VariantName = %(VariantsBatch.Identity); _VariantSwitch = %(VariantsBatch.Switch);
                           ProjectFile = $(ProjectFile); _NativeToolChain = $(NativeToolChain); 
                           _TestFolders = %(TestFolders); 
                           _SourceFolders = %(SourceFolders); _SupportFolders = %(VariantsBatch.SupportFolders); 
                           _NativeSourceFolders = %(VariantsBatch.NativeSourceFolders); _GhostSourceFolders = %(VariantsBatch.GhostSourceFolders); 
                           _NativeSupportFolders = %(VariantsBatch.NativeSupportFolders); _GhostSupportFolders = %(VariantsBatch.GhostSupportFolders); 
                           _IncludeFolders = %(VariantsBatch.IncludeFolders);  BuildNativeAsWell = $(BuildNative); BuildGhostAsWell = $(BuildGhost);
                           PassedGlob = $(GlobPattern); ArtifactsFolderRoot = $(ArtifactsOutput); 
                           BinFolderRoot = $(BinOutput); NativeCPU = $(NativeCPU); 
                           Defines = $(_tv_testDefines); ReleaseDefines = $(_tv_ReleaseDefines);
                           DefaultPropertyFile = $(MSBuildThisFileDirectory)default.properties; FeatureName = $(FeatureName); IdeFolderRoot = $(IdeFolder);
                           SelectedConfiguration = $(SelectedConfiguration); BuildFeature = $(BuildFeature); FeatureCFile = $(FeatureCFile);
                           NativeLinkerArgs = $(NativeLinkerArgs); RecipeListFile = $(RecipeListFile);
                           ToolScriptsFolders = $(_tv_ToolScripts); ToolChainPath = $(NativeToolChainPath);
                           ToolChainTimeoutPeriod = $(NativeToolChainTimeout); PlatformName = %(VariantsBatch.Platform);
                           NativeCompilerArgs = $(NativeCompilerArgs); GhostCompilerArgs = $(GhostCompilerArgs); GhostLinkerArgs = $(GhostLinkerArgs);
                           BuildIDE = $(BuildIDE); GhostToolname=$(GhostToolchainName);
                        "
             />
  </Target>


  <Target Name="_CreateVariantBatch">

    <ClubVariantPlatformTask
        Variants="@(Variants)"
        Platforms="@(Platforms)"
        PlatformNameToken="$(PlatformName)"
        KnownToolChains="@(ToolChains)"
        DefaultGhostTimeoutPeriod="$(GhostTimeoutPeriod)"
        DefaultSimulatorTimeoutPeriod="$(SimulatorTimeoutPeriod)"
        GhostToolchain="$(GhostToolchainName)"
      >
      <Output ItemName= "VariantsBatchAll" TaskParameter= "VariantsClubbed" />
    </ClubVariantPlatformTask>

    <FilterVariantPlatformTask
        Variants="@(VariantsBatchAll)"
        Platforms="@(Platforms)"
        UserVariantChoice="$(SelectedVariant)"
        UserPlatformChoice="$(SelectedPlatform)"
      >
      <Output ItemName= "VariantsBatch" TaskParameter= "FilteredVariants" />
    </FilterVariantPlatformTask>

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

    <!-- Resolve Feature -->
    <FeatureTask UserHint= "$(BuildFeature)" 
                 FeaturesRoot= "$(FeaturesRoot)"
                 FeaturesCodeRoot= "$(FeatureCodeRoot)"
                 OutputFolder= "$(EtcFolder)"
                 FeatureSourceName= "$(FeatureSourceName)"
                 FeatureNamingPattern="$(FeatureNamingPattern)"
                 FeatureFileExtension="$(FeatureFileExtension)"
                 FinalFeatureName="$(FinalFeatureName)"
                 SourcePaths="$(CodeRoot)\source"
                 >
      <Output PropertyName= "BuildFeature" TaskParameter= "FeatureFile" />
      <Output PropertyName= "FeatureCFile" TaskParameter= "FeatureMetaFile" />
    </FeatureTask>
  </Target>


  <Target Name="_CreateTestFixtureFile" Inputs="$(ProjectFile)" Outputs="$(BinOutput)\$(ProjectFixtureFileName)">
    <Message Text="File out-of-date: '$(BinOutput)\$(ProjectFixtureFileName)'. Creating file." Importance="normal" />

    <TestFixtureGeneratorTask
      Variants="@(VariantsBatchAll)"
      Platforms="@(Platforms)"
      ProjectName="$(ProjectName)"
      TestFixtureFileName="$(BinOutput)\$(ProjectFixtureFileName)"
      KnownToolChains="@(ToolChains)"
      DefaultGhostTimeoutPeriod="$(GhostTimeoutPeriod)"
      DefaultSimulatorTimeoutPeriod="$(SimulatorTimeoutPeriod)"
      />
  </Target>


  <Target Name= "_SanityCheckSelectedVariant" Condition= "$([System.String]::IsNullOrEmpty('$(SelectedVariant)')) == 'false'" DependsOnTargets= "_CheckSelectedVariantAgainstAllVariantNames">
    <Error Text= "Variant '$(SelectedVariant)' not found" Condition= "'$(SelectedVariantError)' == 'true' " />
  </Target>

  <Target Name= "_CheckSelectedVariantAgainstAllVariantNames" Condition= "$([System.String]::IsNullOrEmpty('$(SelectedVariant)')) == 'false'" Outputs= "%(Variants.Identity)">
    <PropertyGroup>
      <__thisVariant>%(Variants.Identity)</__thisVariant>
    </PropertyGroup>
    <PropertyGroup Condition= " '$(SelectedVariant)' == '$(__thisVariant)' ">
      <SelectedVariantError>false</SelectedVariantError>
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

  <Target Name= "_SanityCheckBuildAll" DependsOnTargets= "_SanityCheckSelectedVariant">
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
  
  <Target Name= "_SanityCheckBuild" DependsOnTargets= "_SanityCheckSelectedVariant">
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

  <Target Name= "_SanityCheckCleanAll" DependsOnTargets= "_SanityCheckSelectedVariant">
    <PropertyGroup>
      <BuildTarget>CleanAll</BuildTarget>
    </PropertyGroup>
    <Error Text= "Nothing to clean- neither ghost nor native." Condition= " '$(BuildNative)' == 'false' AND '$(BuildGhost)' == 'false' " />
  </Target>

  <Target Name= "_RemoveRootFolders" Condition ="$([System.String]::IsNullOrEmpty('$(SelectedVariant)')) == 'true'" >
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
