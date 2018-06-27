<?xml version="1.0" encoding="utf-8"?>

<!--
Copyright Bhavnit Singh Bajwa   iobajwa@gmail.com
Please refer to Halwayi's license agreement for more details
-->

<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003" ToolsVersion="4.0">

  <PropertyGroup>
    <__VariantName></__VariantName>
    
    <TestFile></TestFile>
    <TestFileContents></TestFileContents>
    <TestFileArtifactFolder></TestFileArtifactFolder>
    <TestFileBinFolder></TestFileBinFolder>
    <TestPropertyFile></TestPropertyFile>
    <FlavourCount>0</FlavourCount>
    <NativeIncludedPaths></NativeIncludedPaths>
    <GhostIncludedPaths></GhostIncludedPaths>
    <TestFileName></TestFileName>
    <TestFileNameWithExtension></TestFileNameWithExtension>
    <TestFileFullname></TestFileFullname>
    <_Defines></_Defines>
    
    <BuildNativeAlso></BuildNativeAlso>
    <BuildGhostAlso></BuildGhostAlso>
    <NativeMainFile></NativeMainFile>
    <NativeProcessor></NativeProcessor>
    <NativeToolChainID></NativeToolChainID>

    <_ProjectFile></_ProjectFile>
    <_DefaultPropertyFile></_DefaultPropertyFile>

    <CMockStrictOrderingEnabled>false</CMockStrictOrderingEnabled>
    <CExceptionIncludedGhost>false</CExceptionIncludedGhost>
    <_ToolChainPath></_ToolChainPath>
    <_ToolChainTimeoutPeriod></_ToolChainTimeoutPeriod>
  </PropertyGroup>

  <ItemGroup>
    <TestFileItem Include="$(TestFile)" />
  </ItemGroup>




  <!-- 
  ************************************************************************************************************************
                                              Include External Dependencies
  ************************************************************************************************************************
  -->

  <Import Project= "$(_DefaultPropertyFile)" />
  <Import Project= "$(_ProjectFile)"/>
  <Import Project= "$(TargetsToolPath)\automock.targets"/>
  <Import Project= "$(TargetsToolPath)\cstub.targets"/>
  
  <UsingTask AssemblyFile= "$(BuilderTasksPath)\halwayiTasks.dll" TaskName= "TestRunnerGeneratorTask" />
  <UsingTask AssemblyFile= "$(BuilderTasksPath)\halwayiTasks.dll" TaskName= "CreateExpectationsTask" />
  <UsingTask AssemblyFile= "$(BuilderTasksPath)\halwayiTasks.dll" TaskName= "FindSourceLinksTask" />
  <UsingTask AssemblyFile= "$(BuilderTasksPath)\halwayiTasks.dll" TaskName= "LinkFileCreationTask" />
  <UsingTask AssemblyFile= "$(BuilderTasksPath)\halwayiTasks.dll" TaskName= "PathReaderTask" />
  <UsingTask AssemblyFile= "$(BuilderTasksPath)\halwayiTasks.dll" TaskName= "FlavourParserTask" />
  <UsingTask AssemblyFile= "$(BuilderTasksPath)\halwayiTasks.dll" TaskName= "FindIncludedFilesTask" />
  <UsingTask AssemblyFile= "$(BuilderTasksPath)\halwayiTasks.dll" TaskName= "MetadataValueParserTask" />
  <UsingTask AssemblyFile= "$(BuilderTasksPath)\halwayiTasks.dll" TaskName= "FindFixturesTask" />














  <!--
  ************************************************************************************************************************
                                                     Public Targets
  ************************************************************************************************************************
  -->
  
  
  <Target Name="TestBuildTestFile" Outputs="%(TestFileItem.Filename)" DependsOnTargets= " _SanityCheck; 
                                                                                          _AppendTestFolderToPaths;
                                                                                          _ReadFileContents;
                                                                                          _ParseFlavours;
                                                                                          _ParseIncludedFiles;
                                                                                          _ParseFixtures;
                                                                                          _ParseEncodedDefines;
                                                                                          _ParseEncodedPaths;
                                                                                          _CreatePathItems;
                                                                                          _CreateBatch;
                                                                                          _CreateFlavoursArtifactFolders;
                                                                                          _CreateFlavoursBinFolders;
                                                                                          _GenerateAnyRequiredMocks;
                                                                                          _SetupPropertiesForCStub;
                                                                                          _GenerateAnyRequiredStubs;
                                                                                          _GenerateLinkFileForEachFlavour;
                                                                                          _GenerateCommonRunner;
                                                                                          _GenerateExpectationsFile;
                                                                                          _CopyExpectationsFileForEachFlavour" >

    <MSBuild Projects= "$(TargetsToolPath)\tests.targets"
             Targets= "Test__BuildTestFile" 
             Properties= "  TestArtifactFolder = $(TestFileArtifactFolder)%(TestFileFlavoured.Flavour)\; 
                            TestBinFolder = $(TestFileBinFolder)%(TestFileFlavoured.Flavour)\; 
                            GhostLinkFile = $(TestFileArtifactFolder)%(TestFileFlavoured.Filename)_ghost.links; 
                            NativeLinkFile = $(TestFileArtifactFolder)%(TestFileFlavoured.Filename)_native.links; 
                            FlavourName = %(TestFileFlavoured.Flavour); Directives = %(TestFileFlavoured.Directives); 
                            OutputName = %(TestFileFlavoured.Filename); NativeIncludedPaths = $(NativeIncludedPaths); 
                            GhostIncludedPaths = $(GhostIncludedPaths); 
                            BuildNative = $(BuildNativeAlso); NativeMain = $(NativeMainFile); 
                            NativeProcessor = $(NativeProcessor); ProjectPropertySheet = $(_ProjectFile); 
                            NativeToolChain = $(NativeToolChainID); ToolChainPath = $(_ToolChainPath);
                            ToolChainTimeoutPeriod = $(_ToolChainTimeoutPeriod);
                            __DefaultPropertyFile = $(_DefaultPropertyFile); BuildGhost = $(BuildGhostAlso)"
             />
  </Target>



  <Target Name="_AppendTestFolderToPaths">
    <PropertyGroup>
      <TestFileFolder>$([System.IO.Path]::GetDirectoryName('%(TestFileItem.FullPath)'))</TestFileFolder>
      <GhostIncludedPaths>$(GhostIncludedPaths);$(TestFileFolder)</GhostIncludedPaths>
      <NativeIncludedPaths>$(NativeIncludedPaths);$(TestFileFolder)</NativeIncludedPaths>
    </PropertyGroup>  
  </Target>
  
  <Target Name="_ReadFileContents">
    <PropertyGroup>
      <TestFileContents>$([System.IO.File]::ReadAllText($(TestFile)))</TestFileContents>
    </PropertyGroup>
  </Target>

  <Target Name="_ParseFlavours">
    <FlavourParserTask TestFileContents="$(TestFileContents)">
      <Output ItemName= "Flavours" TaskParameter= "Flavours" />
      <Output PropertyName= "FlavourCount" TaskParameter= "Count" />
    </FlavourParserTask>
  </Target>

  <Target Name="_ParseIncludedFiles">
    <FindIncludedFilesTask FileContents="$(TestFileContents)">
      <Output ItemName= "IncludedFilesItem" TaskParameter= "DetectedFiles" />
    </FindIncludedFilesTask>
  </Target>

  <Target Name="_ParseFixtures">
    <FindFixturesTask IncludedFiles="@(IncludedFilesItem)" 
                      FixturePrefix="$(FixturePrefix)"
                      SearchPaths="$(GhostIncludedPaths)">  <!-- It is unlikely that we are going to have seperate fixtures for ghost and natives! -->
      <Output ItemName= "IncludedFilesItemTemp" TaskParameter= "UpdatedFileList" />
      <Output ItemName= "__FoundFixtures" TaskParameter= "FoundFixtures" />
    </FindFixturesTask>
    <ItemGroup>
      <IncludedFilesItem Remove="@(IncludedFilesItem)" />
      <IncludedFilesItem Include="@(IncludedFilesItemTemp)" />
    </ItemGroup>
  </Target>

  <Target Name="_ParseEncodedDefines">
    <MetadataValueParserTask Key="define" IncludedFiles="@(IncludedFilesItem)">
      <Output PropertyName= "_DefinesEncodedInTest" TaskParameter= "Values" />
    </MetadataValueParserTask>
    <PropertyGroup Condition=" '$(_DefinesEncodedInTest)' != '' ">
      <_Defines>$(_DefinesEncodedInTest)$(_Defines)</_Defines>
    </PropertyGroup>
    
    <Message Text="Found Defines: $(_Defines)" Importance="Normal" Condition=" '$(_DefinesEncodedInTest)' != '' "/>
  </Target>

  <Target Name="_ParseEncodedPaths">
    <PathReaderTask IncludedFiles= "@(IncludedFilesItem)" RootPath= "$(ProjectRoot)" Key= "add_paths">
      <Output PropertyName= "_PathsEncodedInTest" TaskParameter= "FullPathsFound" />
    </PathReaderTask>
    <PropertyGroup Condition=" '$(_PathsEncodedInTest)' != '' ">
      <GhostIncludedPaths>$(_PathsEncodedInTest);$(GhostIncludedPaths)</GhostIncludedPaths>
      <NativeIncludedPaths>$(_PathsEncodedInTest);$(NativeIncludedPaths)</NativeIncludedPaths>
    </PropertyGroup>

    <Message Text= "Found Paths: $(_PathsEncodedInTest)" Importance= "normal" Condition=" '$(_PathsEncodedInTest)' != '' "/>
  </Target>






  
  

  <!--
  ************************************************************************************************************************
                                                     Internal Targets
  ************************************************************************************************************************
  -->

  <Target Name="_GenerateExpectationsFile" Outputs="$(TestFileArtifactFolder)%(TestFileItem.Filename).expectations" Inputs="%(TestFileItem.Identity)">
    <CreateExpectationsTask  SourceCode="$(TestFileContents)" 
                             TestCasePrefix="$(TestCasePrefix)"
                             ExpectationsFile="$(TestFileArtifactFolder)%(TestFileItem.Filename).expectations" />
  </Target>

  <Target Name="_CopyExpectationsFileForEachFlavour" Outputs="%(TestFileItem.Filename)">
    <Copy SourceFiles="$(TestFileArtifactFolder)%(TestFileFlavoured.Filename).expectations" DestinationFiles="$(TestFileBinFolder)%(TestFileFlavoured.Flavour)\%(TestFileFlavoured.Filename).expectations" />
  </Target>

  <Target Name="_GenerateCommonRunner" Outputs="$(TestFileArtifactFolder)%(TestFileItem.Filename)_runner.c" Inputs="%(TestFileItem.Identity)">
    <PropertyGroup Condition="'$(NativeToolChainID)' != 'xc8_p16'">
      <TestRunnerScript>$(UnityAutoPath)\auto\generate_test_runner.rb</TestRunnerScript>
    </PropertyGroup>
    <PropertyGroup Condition="'$(NativeToolChainID)' == 'xc8_p16'">
      <TestRunnerScript>$(UnityAutoPath)\auto_xc8_p16\generate_test_runner.rb</TestRunnerScript>
    </PropertyGroup>
    <TestRunnerGeneratorTask TestFile="%(TestFileItem.Identity)" 
                             GeneratedFile="$(TestFileArtifactFolder)%(TestFileItem.Filename)_runner.c" 
                             ScriptPath="$(TestRunnerScript)" 
                             SupportCException="$(CExceptionIncludedGhost)" 
                             SupportCMockStrictOrdering="$(CMockStrictOrderingEnabled)" 
                             IncludedFiles="@(RunnerIncludeFilesItem)" />
  </Target>

  <Target Name="_GenerateLinkFileForEachFlavour" Outputs="%(TestFileItem.Identity)" DependsOnTargets="_DeleteGhostLinkFile;
                                                                                                      _DeleteNativeLinkFile;
                                                                                                      _BuildGhostLinkFile;
                                                                                                      _BuildNativeLinkFile;
                                                                                                      _SanityCheckLinks" 
  />

  <Target Name="_SanityCheckLinks">
    <Error Text="CException Mistmatch: Variant: ('$(__VariantName)') Ghost ('$(CExceptionIncludedGhost)') Native ('$(NativeToolChainID)': '$(CExceptionIncludedNative)')" 
      Condition= " '$(CExceptionIncludedGhost)' != '$(CExceptionIncludedNative)' AND 
                   '$(BuildNativeAlso.ToLower())' == 'true' AND 
                   '$(BuildGhostAlso.ToLower())' == 'true' AND 
                   '$(CExceptionIncludedNative)' != '' AND 
                   '$(CExceptionIncludedGhost)' != ''" />
    <PropertyGroup>
      <CExceptionIncludedGhost Condition="'$(BuildGhostAlso.ToLower())' == 'false' ">$(CExceptionIncludedNative)</CExceptionIncludedGhost>
    </PropertyGroup>
  </Target>
  
  <Target Name="_DeleteGhostLinkFile" Inputs="%(TestFileItem.Identity)" Outputs="$(TestFileArtifactFolder)%(TestFileItem.Filename)_ghost.links" Condition= " '$(BuildGhostAlso.ToLower())' == 'true' ">
    <Delete Files="$(TestFileArtifactFolder)%(TestFileItem.Filename)_ghost.links" />
  </Target>

  <Target Name="_DeleteNativeLinkFile" Inputs="%(TestFileItem.Identity)" Outputs="$(TestFileArtifactFolder)%(TestFileItem.Filename)_native.links" Condition= " '$(BuildNativeAlso.ToLower())' == 'true' ">
    <Delete Files="$(TestFileArtifactFolder)%(TestFileItem.Filename)_native.links" />
  </Target>

  <Target Name="_BuildGhostLinkFile" Inputs="%(TestFileItem.Identity)" Outputs="$(TestFileArtifactFolder)%(TestFileItem.Filename)_ghost.links" Condition= " '$(BuildGhostAlso.ToLower())' == 'true' ">
    <Message Text= "Finding Ghost Links for %(TestFileItem.Identity)" Importance= "normal" />

    <FindSourceLinksTask IncludedFiles="@(IncludedFilesItem)" IncludePaths= "@(GhostIncludedPathsItem)" >
      <Output PropertyName= "CExceptionIncludedGhost" TaskParameter= "ContainsCExceptionDependency" />
      <Output ItemName= "_discovered_links_ghost_" TaskParameter= "FoundLinks" />
    </FindSourceLinksTask>

    <ItemGroup>
      <_discovered_links_ghost_ Include= "$(TestFileArtifactFolder)%(TestFileItem.Filename)_runner.c" />
      <_discovered_links_ghost_ Include= "%(TestFileItem.Identity)" />
      <_discovered_links_ghost_ Include= "@(GhostInjectedLinks)" /> <!-- Add Automock links -->
    </ItemGroup>

    <Message Text= "  Found Links: " Importance= "low" />
    <Message Text= "             %(_discovered_links_ghost_.Identity)" Importance= "low" />

    <LinkFileCreationTask LinkFile="$(TestFileArtifactFolder)%(TestFileItem.Filename)_ghost.links" Links="@(_discovered_links_ghost_)" ItemName= "ClCompile"/>
  </Target>

  <Target Name="_BuildNativeLinkFile" Inputs="%(TestFileItem.Identity)" Outputs="$(TestFileArtifactFolder)%(TestFileItem.Filename)_native.links" Condition= " '$(BuildNativeAlso.ToLower())' == 'true' ">
    <PropertyGroup>
      <LinkFileTemp></LinkFileTemp>
    </PropertyGroup>

    <Message Text= "Finding Native Links for %(TestFileItem.Identity)" Importance= "normal" />

    <FindSourceLinksTask IncludedFiles="@(IncludedFilesItem)" IncludePaths= "@(NativeIncludedPathsItem)" >
      <Output PropertyName= "CExceptionIncludedNative" TaskParameter= "ContainsCExceptionDependency" />
      <Output ItemName= "_discovered_links_native_" TaskParameter= "FoundLinks" />
    </FindSourceLinksTask>

    <ItemGroup>
      <_discovered_links_native_ Include= "$(TestFileArtifactFolder)%(TestFileItem.Filename)_runner.c" />
      <_discovered_links_native_ Include= "%(TestFileItem.Identity)" />
      <_discovered_links_native_ Include= "@(NativeInjectedLinks)" />  <!-- Add Automock links -->
    </ItemGroup>

    <Message Text= "  Found Links: " Importance= "low" />
    <Message Text= "             %(_discovered_links_native_.Identity)" Importance= "low" />

    <LinkFileCreationTask LinkFile="$(TestFileArtifactFolder)%(TestFileItem.Filename)_native.links" Links="@(_discovered_links_native_)" ItemName= "NativeCompile"/>
  </Target>
  
  
  
  <Target Name="_SanityCheck">
    <Error Text= "TestFile '$(TestFile)' does not exists" Condition="!Exists($(TestFile))" />
    <Error Text= "Artifacts Folder for Test file does not exists" Condition="!Exists($(TestFileArtifactFolder))" />
    <Error Text= "TestFileBinFolder $(TestFileBinFolder) does not exists" Condition="!Exists($(TestFileBinFolder))" />
    <Error Text= "Native Main File '$(NativeMainFile)' does not exists" Condition="!Exists($(NativeMainFile)) AND '$(BuildNativeAlso.ToLower())' == 'true'" />
    <Error Text= "Native Processor not defined" Condition="'$([System.String]::IsNullOrWhiteSpace($(NativeProcessor)))' == 'true'" />
    <Error Text= "Native Tool Chain ID not provided" Condition= " '$([System.String]::IsNullOrWhiteSpace($(NativeToolChainID)))' == 'true' "  />
  </Target>

  
  <Target Name="_CreatePathItems">
    <PropertyGroup>
      <TestFileName>%(TestFileItem.Filename)</TestFileName>
      <TestFileNameWithExtension>%(TestFileItem.Filename)%(TestFileItem.Extension)</TestFileNameWithExtension>
      <TestFileFullname>%(TestFileItem.Identity)</TestFileFullname>
      <NativeIncludedPaths>$(TestFileArtifactFolder)\$(NativeToolChainID);$(NativeIncludedPaths)</NativeIncludedPaths>
      <NativeIncludedPaths>$(TestFileArtifactFolder);$(NativeIncludedPaths)</NativeIncludedPaths>
      <GhostIncludedPaths>$(TestFileArtifactFolder)\Ghost;$(GhostIncludedPaths)</GhostIncludedPaths>
      <GhostIncludedPaths>$(TestFileArtifactFolder);$(GhostIncludedPaths)</GhostIncludedPaths>
    </PropertyGroup>

    <ItemGroup>
      <NativeIncludedPathsItem Include= "$(NativeIncludedPaths.Split(';'))" />
    </ItemGroup>

    <ItemGroup>
      <GhostIncludedPathsItem Include= "$(GhostIncludedPaths.Split(';'))" />
    </ItemGroup>
  </Target>
  
  <Target Name="_CreateFlavoursArtifactFolders" Outputs="%(TestFileFlavoured.Identity)">
    <MakeDir Directories="%(TestFileFlavoured.GhostArtifactFolder)" Condition= " '$(BuildGhostAlso.ToLower())' == 'true' "/>
    <MakeDir Directories="%(TestFileFlavoured.NativeArtifactFolder)" Condition= " '$(BuildNativeAlso.ToLower())' == 'true' "/>
  </Target>

  <Target Name="_SetupPropertiesForCStub">
    <PropertyGroup>
      <CStubGhostRoot>$(TestFileArtifactFolder)\Ghost</CStubGhostRoot>
      <CStubNativeRoot>$(TestFileArtifactFolder)\$(NativeToolChainID)</CStubNativeRoot>
    </PropertyGroup>
    <MakeDir Directories="$(CStubGhostRoot)" Condition=" '$(BuildGhostAlso.ToLower())' == 'true' " />
    <MakeDir Directories="$(CStubNativeRoot)" Condition=" '$(BuildNativeAlso.ToLower())' == 'true' " />
  </Target>

  <Target Name="_CreateFlavoursBinFolders" Outputs="%(Flavours.Identity)" Condition="'$(FlavourCount)' != '0'">
    <MakeDir Directories="$(TestFileBinFolder)%(Flavours.Identity)" />
  </Target>

  <Target Name= "_CreateBatch">
    <ItemGroup>
      <TestFileFlavoured Include= "@(TestFileItem)" Condition= " '$([System.String]::IsNullOrWhiteSpace($(_Defines)))' == 'true' ">
        <Flavour>%(Flavours.Identity)</Flavour>
        <Directives>%(Flavours.Directives)</Directives>
        <GhostArtifactFolder>$(TestFileArtifactFolder)%(Flavours.Identity)\Ghost</GhostArtifactFolder>
        <NativeArtifactFolder>$(TestFileArtifactFolder)%(Flavours.Identity)\$(NativeToolChainID)</NativeArtifactFolder>
      </TestFileFlavoured>
      <TestFileFlavoured Include= "@(TestFileItem)" Condition= " '$([System.String]::IsNullOrWhiteSpace($(_Defines)))' == 'false' ">
        <Flavour>%(Flavours.Identity)</Flavour>
        <Directives>$(_Defines);%(Flavours.Directives)</Directives>
        <GhostArtifactFolder>$(TestFileArtifactFolder)%(Flavours.Identity)\Ghost</GhostArtifactFolder>
        <NativeArtifactFolder>$(TestFileArtifactFolder)%(Flavours.Identity)\$(NativeToolChainID)</NativeArtifactFolder>
      </TestFileFlavoured>
    </ItemGroup>

    <Message Text="Discovered $(FlavourCount) Flavour(s) =>" Condition="'$(FlavourCount)' != '0'" Importance="normal"/>
    <Message Text="    %(Flavours.Identity)" Condition="'$(FlavourCount)' != '0'" Importance="normal" />
    
    <Message Text= "Flavoured Batch=> " Importance= "normal" Condition="'$(FlavourCount)' != '0'"/>
    <Message Text= "  %(TestFileFlavoured.Filename) : %(TestFileFlavoured.Flavour)" Importance="normal" Condition="'$(FlavourCount)' != '0'"/>
  </Target>


  
</Project>
