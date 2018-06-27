<?xml version="1.0" encoding="utf-8"?>

<!--
Copyright Bhavnit Singh Bajwa   iobajwa@gmail.com
Please refer to Halwayi's license agreement for more details
-->


<Project DefaultTargets="Build" xmlns="http://schemas.microsoft.com/developer/msbuild/2003" ToolsVersion="4.0">

	<!-- 
	************************************************************************************************************************
																							Declare Properties and Items
	************************************************************************************************************************
	-->
	<PropertyGroup>
		<!-- Public Properties -->
		<ProjectFile></ProjectFile>
		<DefaultPropertyFile></DefaultPropertyFile>
		<BuildNativeAsWell>false</BuildNativeAsWell>
		<BuildGhostAsWell>true</BuildGhostAsWell>
		<PassedGlob></PassedGlob>

		<!-- Variant information -->
		<_VariantName></_VariantName>
		<_VariantSwitch></_VariantSwitch>
		<NativeCPU></NativeCPU>
		<Defines></Defines>
		<NativeLinkerArgs></NativeLinkerArgs>
		
		<ArtifactsFolderRoot></ArtifactsFolderRoot>
		<BinFolderRoot></BinFolderRoot>
		
		<!-- Paths -->
		<_TestFolders></_TestFolders>
		<_SupportFolders></_SupportFolders>
		<_SourceFolders></_SourceFolders>
		<_IncludeFolders></_IncludeFolders>
		<_GhostSupportFolders></_GhostSupportFolders>
		<_NativeSupportFolders></_NativeSupportFolders>
		<_DefaultBuilderNativeSupportFolders></_DefaultBuilderNativeSupportFolders>
		<DefaultBuilderGhostSupportFolders></DefaultBuilderGhostSupportFolders>
		<DefaultBuilderSupportFolders></DefaultBuilderSupportFolders>
		<_AllNativeIncludedPaths></_AllNativeIncludedPaths>
		<_AllGhostIncludedPaths></_AllGhostIncludedPaths>
		
		<_GhostSourceFolders></_GhostSourceFolders>
		<_NativeSourceFolders></_NativeSourceFolders>
		
		
		<!-- Private Properties -->
		<_NativeMain></_NativeMain>
		<ToolChainPath></ToolChainPath>
		<ToolChainTimeoutPeriod></ToolChainTimeoutPeriod>
	</PropertyGroup>


	
	
	
	
	<!-- 
	************************************************************************************************************************
																							Include External Dependencies
	************************************************************************************************************************
	-->
	<UsingTask AssemblyFile="$(BuilderTasksPath)\halwayiTasks.dll" TaskName="CreatePropertiesTask" />
	<UsingTask AssemblyFile="$(BuilderTasksPath)\halwayiTasks.dll" TaskName="FindRelativeNamespaceTask" />
	<UsingTask AssemblyFile="$(BuilderTasksPath)\halwayiTasks.dll" TaskName="FindFileTask" />
	<UsingTask AssemblyFile="$(BuilderTasksPath)\halwayiTasks.dll" TaskName="RelativeToAbsolutePathsTask" />
	<UsingTask AssemblyFile="$(BuilderTasksPath)\halwayiTasks.dll" TaskName="FilterFilesListTask" />

	<Import Project="$(DefaultPropertyFile)" />
	<Import Project="$(ProjectFile)" />
	






	<!--
	************************************************************************************************************************
																										 Public Targets
	************************************************************************************************************************
	-->
	
	<!-- Runs the build process on all the Test Files that are detected in test file folders -->
	<Target Name="BuildAll" DependsOnTargets=" _SanityCheck_BuildAllTests;
																								 _BuildPathItems;
																								 _CheckPaths;
																								 _CreateIncludePathList; 
																								 _CreateVariantProperties; 
																								 _FindNativeMain;
																								 _CreateTestFileList;
																								 _TestIfNoTestsFound;
																								 _TestIfNativeMainNotFound;
																								 _FindRelativeNamespaceForEachTest;
																								 _FillTestProperties;
																								 _CreateArtifactFolderForThisVariant;
																								 _CreateBinFolderForThisVariant;
																								 _CreateArtifactFolderForEachTestFile;
																								 _CreateBinFolderForEachTestFile;
																								 _BuildTests">
	</Target>

		
	<!-- Performs clean on all Tests: Deletes  $(ArtifactRoot)\$(_VariantName)\*    $(BinRoot)\$(_VariantName)\* -->
	<Target Name="CleanAll" DependsOnTargets="_SanityCheck_CleanAll;_CreateVariantProperties;_DeleteArtifactAndBinFolders">
	</Target>

	
	<!-- Runs the build process $(PassedGlob) -->
	<Target Name="Build" DependsOnTargets=" _SanityCheck_SingleTest;
																						_BuildPathItems;
																						_CheckPaths;
																						_CreateIncludePathList;                                                 
																						_CreateVariantProperties;
																						_FindNativeMain;
																						_CreateTestFileList;
																						_FilterTestFileList;
																						_TestIfNoTestsFound;
																						_FindRelativeNamespaceForEachTest;
																						_FillTestProperties;
																						_TestIfNoTestsFound;
																						_TestIfNativeMainNotFound;
																						_CreateIncludePathList;
																						_CreateArtifactFolderForEachTestFile;
																						_CreateBinFolderForEachTestFile;
																						_BuildTests" >
	</Target>


	<!-- Performs a clean on $(PassedGlob) -->
	<Target Name="Clean" DependsOnTargets="_SanityCheck_CleanSingle;
                                             _CreateVariantProperties;
                                             _BuildPathItems;
                                             _CreateTestFileList;
                                             _FilterTestFileList;
                                             _TestIfNoTestsFound;
                                             _FindRelativeNamespaceForEachTest;
                                             _FillTestProperties;
                                             _DeleteArtifactAndBinFoldersForSingleTest">
	</Target>
	


	





	

	<!--
	************************************************************************************************************************
																										 Internal Targets
	************************************************************************************************************************
	-->

	<!-- ========================================
			Targets shareed by multiple Public Targets
	========================================= -->
	
	<Target Name="_SanityCheck_VariantProperties" >
		<Error Text="_VariantName not provided" Condition=" '$([System.String]::IsNullOrWhiteSpace($(_VariantName)))' == 'true' "  />
		<Error Text="_VariantSwitch not provided" Condition=" '$([System.String]::IsNullOrWhiteSpace($(_VariantSwitch)))' == 'true' " />

		<Error Text="Artifacts root folder not specified" Condition="!Exists($(ArtifactsFolderRoot))"></Error>
		<Error Text="Binary root folder not specified" Condition="!Exists($(BinFolderRoot))"></Error>
	</Target>

	<Target Name="_SanityCheck_BuildRelatedProperties">
		<Error Text="UnityAutoPath '$(UnityAutoPath)' does not exists" Condition=" !Exists($(UnityAutoPath)) " />
		<Error Text="CMockAutoPath '$(CMockAutoPath)' does not exists" Condition=" !Exists($(CMockAutoPath)) " />
	</Target>

	<Target Name="_CreateVariantProperties">
		<PropertyGroup>
			<VariantArtificatFolderRoot>$(ArtifactsFolderRoot)\$(_VariantName)</VariantArtificatFolderRoot>
		</PropertyGroup>
		<PropertyGroup>
			<VariantBinFolderRoot>$(BinFolderRoot)\$(_VariantName)</VariantBinFolderRoot>
		</PropertyGroup>
	</Target>


	<Target Name="_BuildPathItems" DependsOnTargets="_CreateDefaultBuilderPathProperties">
		<ItemGroup>
			<TestFoldersItem Include="$(_TestFolders)" />
			<SupportFoldersItem Include="$(_SupportFolders)" />
			<SourceFoldersItem Include="$(_SourceFolders)" />
			<IncludeFoldersItem Include="$(_IncludeFolders)" />

			<DefaultBuilderSupportFoldersItem Include="$(DefaultBuilderSupportFolders)" />

			<NativeSupportFoldersItem Include="$(_NativeSupportFolders)" />
			<DefaultBuilderNativeSupportFoldersItem Include="$(_DefaultBuilderNativeSupportFolders)" />

			<GhostSupportFoldersItem Include="$(_GhostSupportFolders)" />
			<DefaultBuilderGhostSupportFoldersItem Include="$(DefaultBuilderGhostSupportFolders)" />

			<GhostSourceFoldersItem Include="$(_GhostSourceFolders)" />
			<NativeSourceFoldersItem Include="$(_NativeSourceFolders)" />
		</ItemGroup>

		<!-- Convert any relative paths to abosute paths -->
				<RelativeToAbsolutePathsTask PathsToCheck="@(TestFoldersItem)" Root="$(ProjectRoot)">
					<Output ItemName="__Temp1" TaskParameter="ConvertedPathsItem" />
				</RelativeToAbsolutePathsTask>
				<ItemGroup>
					<TestFoldersItem Remove="%(TestFoldersItem.Identity)" />
					<TestFoldersItem Include="%(__Temp1.Identity)" />
				</ItemGroup>

				<RelativeToAbsolutePathsTask PathsToCheck="@(SupportFoldersItem)" Root="$(ProjectRoot)">
					<Output ItemName="__Temp2" TaskParameter="ConvertedPathsItem" />
				</RelativeToAbsolutePathsTask>
				<ItemGroup>
					<SupportFoldersItem Remove="%(SupportFoldersItem.Identity)" />
					<SupportFoldersItem Include="%(__Temp2.Identity)" />
				</ItemGroup>

				<RelativeToAbsolutePathsTask PathsToCheck="@(SourceFoldersItem)" Root="$(ProjectRoot)">
					<Output ItemName="__Temp3" TaskParameter="ConvertedPathsItem" />
				</RelativeToAbsolutePathsTask>
				<ItemGroup>
					<SourceFoldersItem Remove="%(SourceFoldersItem.Identity)" />
					<SourceFoldersItem Include="%(__Temp3.Identity)" />
				</ItemGroup>

				<RelativeToAbsolutePathsTask PathsToCheck="@(IncludeFoldersItem)" Root="$(ProjectRoot)">
					<Output ItemName="__Temp4" TaskParameter="ConvertedPathsItem" />
				</RelativeToAbsolutePathsTask>
				<ItemGroup>
					<IncludeFoldersItem Remove="%(IncludeFoldersItem.Identity)" />
					<IncludeFoldersItem Include="%(__Temp4.Identity)" />
				</ItemGroup>

				<RelativeToAbsolutePathsTask PathsToCheck="@(DefaultBuilderSupportFoldersItem)" Root="$(ProjectRoot)">
					<Output ItemName="__Temp5" TaskParameter="ConvertedPathsItem" />
				</RelativeToAbsolutePathsTask>
				<ItemGroup>
					<DefaultBuilderSupportFoldersItem Remove="%(DefaultBuilderSupportFoldersItem.Identity)" />
					<DefaultBuilderSupportFoldersItem Include="%(__Temp5.Identity)" />
				</ItemGroup>

				<RelativeToAbsolutePathsTask PathsToCheck="@(NativeSupportFoldersItem)" Root="$(ProjectRoot)">
					<Output ItemName="__Temp6" TaskParameter="ConvertedPathsItem" />
				</RelativeToAbsolutePathsTask>
				<ItemGroup>
					<NativeSupportFoldersItem Remove="%(NativeSupportFoldersItem.Identity)" />
					<NativeSupportFoldersItem Include="%(__Temp6.Identity)" />
				</ItemGroup>

				<RelativeToAbsolutePathsTask PathsToCheck="@(DefaultBuilderNativeSupportFoldersItem)" Root="$(ProjectRoot)">
					<Output ItemName="__Temp7" TaskParameter="ConvertedPathsItem" />
				</RelativeToAbsolutePathsTask>
				<ItemGroup>
					<DefaultBuilderNativeSupportFoldersItem Remove="%(DefaultBuilderNativeSupportFoldersItem.Identity)" />
					<DefaultBuilderNativeSupportFoldersItem Include="%(__Temp7.Identity)" />
				</ItemGroup>

				<RelativeToAbsolutePathsTask PathsToCheck="@(GhostSupportFoldersItem)" Root="$(ProjectRoot)">
					<Output ItemName="__Temp8" TaskParameter="ConvertedPathsItem" />
				</RelativeToAbsolutePathsTask>
				<ItemGroup>
					<GhostSupportFoldersItem Remove="%(GhostSupportFoldersItem.Identity)" />
					<GhostSupportFoldersItem Include="%(__Temp8.Identity)" />
				</ItemGroup>

				<RelativeToAbsolutePathsTask PathsToCheck="@(DefaultBuilderGhostSupportFoldersItem)" Root="$(ProjectRoot)">
					<Output ItemName="__Temp9" TaskParameter="ConvertedPathsItem" />
				</RelativeToAbsolutePathsTask>
				<ItemGroup>
					<DefaultBuilderGhostSupportFoldersItem Remove="%(DefaultBuilderGhostSupportFoldersItem.Identity)" />
					<DefaultBuilderGhostSupportFoldersItem Include="%(__Temp9.Identity)" />
				</ItemGroup>

				<RelativeToAbsolutePathsTask PathsToCheck="@(GhostSourceFoldersItem)" Root="$(ProjectRoot)">
					<Output ItemName="__Temp10" TaskParameter="ConvertedPathsItem" />
				</RelativeToAbsolutePathsTask>
				<ItemGroup>
					<GhostSourceFoldersItem Remove="%(GhostSourceFoldersItem.Identity)" />
					<GhostSourceFoldersItem Include="%(__Temp10.Identity)" />
				</ItemGroup>

				<RelativeToAbsolutePathsTask PathsToCheck="@(NativeSourceFoldersItem)" Root="$(ProjectRoot)">
					<Output ItemName="__Temp11" TaskParameter="ConvertedPathsItem" />
				</RelativeToAbsolutePathsTask>
				<ItemGroup>
					<NativeSourceFoldersItem Remove="%(NativeSourceFoldersItem.Identity)" />
					<NativeSourceFoldersItem Include="%(__Temp12.Identity)" />
				</ItemGroup>


		<!-- Create _NativeAllIncludedPathItem which will be used to search NativeMain.c among other things. -->
		<ItemGroup>
			<!-- Folder preference order:
						- Test Folder
						- Native Support Folder
						- Builder provided Native Support Folder
						- Common Support Folder
						- Builder provided Common Support Folder
						- Native Source Folder
						- Source Folders
						- Include Folders
			-->
			<_NativeAllIncludedPathItem Include="@(TestFoldersItem)" />
			<_NativeAllIncludedPathItem Include="@(NativeSupportFoldersItem)" />
			<_NativeAllIncludedPathItem Include="@(DefaultBuilderNativeSupportFoldersItem)" />
			<_NativeAllIncludedPathItem Include="@(SupportFoldersItem)" />
			<_NativeAllIncludedPathItem Include="@(DefaultBuilderSupportFoldersItem)" />
			<_NativeAllIncludedPathItem Include="@(NativeSourceFoldersItem)" />
			<_NativeAllIncludedPathItem Include="@(SourceFoldersItem)" />
			<_NativeAllIncludedPathItem Include="@(IncludeFoldersItem)" />
		</ItemGroup>

	</Target>

	<Target Name="_CreateDefaultBuilderPathProperties">
		<PropertyGroup>
			<_DefaultBuilderNativeSupportFolders>$(BuilderCodePath)\NativeSupport\$(_NativeToolChain)</_DefaultBuilderNativeSupportFolders>
		</PropertyGroup>
	</Target>

	<Target Name="_CheckPaths" DependsOnTargets="_CheckTestFolders;_CheckGhostSupportFolders;_CheckNativeSupportFolders;_CheckSupportFolders;_CheckSourceFolders;_CheckIncludeFolders;_CheckGhostFolders;_CheckGhostSourceFolders;_CheckNativeSourceFolders">
	</Target>
	
	<Target Name="_CheckTestFolders" Outputs="%(TestFoldersItem.Identity)">
		<Error Text="Test Path '%(TestFoldersItem.Identity)' does not exists." Condition="!Exists(%(TestFoldersItem.Identity)) AND $([System.String]::IsNullOrEmpty('%(TestFoldersItem.Identity)')) == 'false'" />
	</Target>

	<Target Name="_CheckGhostSupportFolders" Outputs="%(GhostSupportFoldersItem.Identity)">
		<Error Text="Ghost Support Path '%(GhostSupportFoldersItem.Identity)' does not exists." Condition="!Exists(%(GhostSupportFoldersItem.Identity)) AND $([System.String]::IsNullOrEmpty('%(GhostSupportFoldersItem.Identity)')) == 'false'" />
	</Target>

	<Target Name="_CheckNativeSupportFolders" Outputs="%(NativeSupportFoldersItem.Identity)">
		<Error Text="Native Support Path '%(NativeSupportFoldersItem.Identity)' does not exists." Condition="!Exists(%(NativeSupportFoldersItem.Identity)) AND $([System.String]::IsNullOrEmpty('%(NativeSupportFoldersItem.Identity)')) == 'false'" />
	</Target>

	<Target Name="_CheckSupportFolders" Outputs="%(SupportFoldersItem.Identity)" Condition=" '$(_SupportFolders)' != '' ">
		<Error Text="Support Path '%(SupportFoldersItem.Identity)' does not exists." Condition="!Exists(%(SupportFoldersItem.Identity)) AND $([System.String]::IsNullOrEmpty('%(SupportFoldersItem.Identity)')) == 'false'" />
	</Target>

	<Target Name="_CheckSourceFolders" Outputs="%(SourceFoldersItem.Identity)" Condition=" '$(_SourceFolders)' != '' ">
		<Error Text="Source Path '%(SourceFoldersItem.Identity)' does not exists." Condition="!Exists(%(SourceFoldersItem.Identity)) AND $([System.String]::IsNullOrEmpty('%(SourceFoldersItem.Identity)')) == 'false'" />
	</Target>

	<Target Name="_CheckIncludeFolders" Outputs="%(IncludeFoldersItem.Identity)" Condition=" '$(_IncludeFolders)' != '' ">
		<Error Text="Include Path '%(IncludeFoldersItem.Identity)' does not exists." Condition="!Exists(%(IncludeFoldersItem.Identity)) AND $([System.String]::IsNullOrEmpty('%(IncludeFoldersItem.Identity)')) == 'false'" />
	</Target>

	<Target Name="_CheckGhostFolders" Outputs="%(GhostSupportFoldersItem.Identity)" Condition=" '$(_GhostSupportFolders)' != '' ">
		<Error Text="Ghost Support Path '%(GhostSupportFoldersItem.Identity)' does not exists." Condition="!Exists(%(GhostSupportFoldersItem.Identity)) AND $([System.String]::IsNullOrEmpty('%(GhostSupportFoldersItem.Identity)')) == 'false'" />
	</Target>

	<Target Name="_CheckGhostSourceFolders" Outputs="%(GhostSourceFoldersItem.Identity)" Condition=" '$(_GhostSourceFolders)' != '' ">
		<Error Text="Ghost Source Path '%(GhostSourceFoldersItem.Identity)' does not exists." Condition="!Exists(%(GhostSourceFoldersItem.Identity)) AND $([System.String]::IsNullOrEmpty('%(GhostSourceFoldersItem.Identity)')) == 'false'" />
	</Target>

	<Target Name="_CheckNativeSourceFolders" Outputs="%(NativeSourceFoldersItem.Identity)" Condition=" '$(_NativeSourceFolders)' != '' ">
		<Error Text="Ghost Source Path '%(NativeSourceFoldersItem.Identity)' does not exists." Condition="!Exists(%(NativeSourceFoldersItem.Identity)) AND $([System.String]::IsNullOrEmpty('%(NativeSourceFoldersItem.Identity)')) == 'false'" />
	</Target>

	

	<!-- Creates a list of all the include paths into $(_AllNativeIncludedPaths) -->
	<Target Name="_CreateIncludePathList">
		<PropertyGroup>

			<!-- Folder preference order:
						- Test Folder
						- Native Support Folder
						- Builder provided Native Support Folder
						- Common Support Folder
						- Builder provided Common Support Folder
						- Native Source Folder
						- Source Folders
						- Include Folders
			-->
			<_AllNativeIncludedPaths>$(_TestFolders);</_AllNativeIncludedPaths>
			<_AllNativeIncludedPaths>$(_AllNativeIncludedPaths);$(_NativeSupportFolders);</_AllNativeIncludedPaths>
			<_AllNativeIncludedPaths>$(_AllNativeIncludedPaths);$(_DefaultBuilderNativeSupportFolders);</_AllNativeIncludedPaths>
			<_AllNativeIncludedPaths>$(_AllNativeIncludedPaths);$(_SupportFolders);</_AllNativeIncludedPaths>
			<_AllNativeIncludedPaths>$(_AllNativeIncludedPaths);$(DefaultBuilderSupportFolders);</_AllNativeIncludedPaths>
			<_AllNativeIncludedPaths>$(_AllNativeIncludedPaths);$(_NativeSourceFolders);</_AllNativeIncludedPaths>
			<_AllNativeIncludedPaths>$(_AllNativeIncludedPaths);$(_SourceFolders);</_AllNativeIncludedPaths>
			<_AllNativeIncludedPaths>$(_AllNativeIncludedPaths);$(_IncludeFolders);</_AllNativeIncludedPaths>
			<_AllNativeIncludedPaths>$(_AllNativeIncludedPaths.Trim(';'))</_AllNativeIncludedPaths>
			<_AllNativeIncludedPaths>$(_AllNativeIncludedPaths);</_AllNativeIncludedPaths>
			<_AllNativeIncludedPaths>$(_AllNativeIncludedPaths.Replace(";;", ";"))</_AllNativeIncludedPaths>
			<_AllNativeIncludedPaths>$(_AllNativeIncludedPaths.Replace(";", "\;"))</_AllNativeIncludedPaths>
			<_AllNativeIncludedPaths>$(_AllNativeIncludedPaths.Replace("\\", "\"))</_AllNativeIncludedPaths>
			<_AllNativeIncludedPaths>$(_AllNativeIncludedPaths.Replace(";\;", ";"))</_AllNativeIncludedPaths>

			<_AllGhostIncludedPaths>$(_TestFolders);</_AllGhostIncludedPaths>
			<_AllGhostIncludedPaths>$(_AllGhostIncludedPaths);$(_GhostSupportFolders);</_AllGhostIncludedPaths>
			<_AllGhostIncludedPaths>$(_AllGhostIncludedPaths);$(DefaultBuilderGhostSupportFolders);</_AllGhostIncludedPaths>
      <_AllGhostIncludedPaths>$(_AllGhostIncludedPaths);$(DefaultBuilderGhostSupportFolders)\$(_NativeToolChain)_default_stubs;</_AllGhostIncludedPaths>
			<_AllGhostIncludedPaths>$(_AllGhostIncludedPaths);$(_SupportFolders);</_AllGhostIncludedPaths>
			<_AllGhostIncludedPaths>$(_AllGhostIncludedPaths);$(DefaultBuilderSupportFolders);</_AllGhostIncludedPaths>
			<_AllGhostIncludedPaths>$(_AllGhostIncludedPaths);$(_GhostSourceFolders);</_AllGhostIncludedPaths>
			<_AllGhostIncludedPaths>$(_AllGhostIncludedPaths);$(_SourceFolders);</_AllGhostIncludedPaths>
			<_AllGhostIncludedPaths>$(_AllGhostIncludedPaths);$(_IncludeFolders);</_AllGhostIncludedPaths>
			<_AllGhostIncludedPaths>$(_AllGhostIncludedPaths.Trim(';'))</_AllGhostIncludedPaths>
			<_AllGhostIncludedPaths>$(_AllGhostIncludedPaths);</_AllGhostIncludedPaths>
			<_AllGhostIncludedPaths>$(_AllGhostIncludedPaths.Replace(";;", ";"))</_AllGhostIncludedPaths>
			<_AllGhostIncludedPaths>$(_AllGhostIncludedPaths.Replace(";", "\;"))</_AllGhostIncludedPaths>
			<_AllGhostIncludedPaths>$(_AllGhostIncludedPaths.Replace("\\", "\"))</_AllGhostIncludedPaths>
			<_AllGhostIncludedPaths>$(_AllGhostIncludedPaths.Replace(";\;", ";"))</_AllGhostIncludedPaths>
		</PropertyGroup>

		<RelativeToAbsolutePathsTask PathsToCheck="$(_AllNativeIncludedPaths)" Root="$(ProjectRoot)">
			<Output PropertyName="_AllNativeIncludedPaths" TaskParameter="ConvertedPaths" />
		</RelativeToAbsolutePathsTask>

		<RelativeToAbsolutePathsTask PathsToCheck="$(_AllGhostIncludedPaths)" Root="$(ProjectRoot)">
			<Output PropertyName="_AllGhostIncludedPaths" TaskParameter="ConvertedPaths" />
		</RelativeToAbsolutePathsTask>
		
		<Message Text="_AllNativeIncludedPaths = $(_AllNativeIncludedPaths)" Importance="low" />
		<Message Text="_AllGhostIncludedPaths = $(_AllGhostIncludedPaths)" Importance="low" />

	</Target>

	<!-- Setups the Artifact folder for the given variant -->
	<Target Name="_CreateArtifactFolderForThisVariant">
		<MakeDir Directories="$(VariantArtificatFolderRoot)" />
	</Target>

	<!-- Setups the Bin folder for the given variant -->
	<Target Name="_CreateBinFolderForThisVariant">
		<MakeDir Directories="$(VariantBinFolderRoot)" />
	</Target>



	<Target Name="_CreateTestFileList" Outputs="%(TestFoldersItem.Identity)">
		<ItemGroup>
			<TestFiles Include="%(TestFoldersItem.Identity)\$(TestFilePrefix)*.c" Condition="Exists(%(TestFoldersItem.Identity))">
				<Root>%(TestFoldersItem.Identity)</Root>
				<RelativeNamespace></RelativeNamespace>
				<ArtifactFolder></ArtifactFolder>
				<BinFolder></BinFolder>
			</TestFiles>
		</ItemGroup>
	</Target>
	
	

	<Target Name="_FindRelativeNamespaceForEachTest" Outputs="%(TestFiles.Identity)">
		<FindRelativeNamespaceTask TestFile="%(TestFiles.Identity)" Root="@(TestFoldersItem)">
			<Output PropertyName="_TempRelativeNamespace" TaskParameter="RelativeNamespace" />
		</FindRelativeNamespaceTask>
		<!--<MakeDir Directories="$(VariantArtificatFolderRoot)\$(RelativeNamespaceDir)%(TestFiles.Filename)" />-->

		<ItemGroup>
			<TestFiles Condition="'%(TestFiles.Identity)' == '%(Identity)'" >
				<RelativeNamespace>$(_TempRelativeNamespace)</RelativeNamespace>
			</TestFiles>
		</ItemGroup>
		
		<PropertyGroup>
			<_TempRelativeNamespace></_TempRelativeNamespace>
		</PropertyGroup>
	</Target>


  <Target Name="_FillTestProperties" Outputs="%(TestFiles.Identity)">
    <PropertyGroup>
      <_ArtifactFolderTemp>$(VariantArtificatFolderRoot)\%(TestFiles.RelativeNamespace)\%(TestFiles.Filename)</_ArtifactFolderTemp>
    </PropertyGroup>

    <ItemGroup>
      <TestFiles Condition="'%(TestFiles.Identity)' == '%(Identity)'" >
        <ArtifactFolder>$(_ArtifactFolderTemp)</ArtifactFolder>
      </TestFiles>
    </ItemGroup>

    <PropertyGroup>
      <_BinFolderTemp>$(VariantBinFolderRoot)\%(TestFiles.RelativeNamespace)\%(TestFiles.Filename)</_BinFolderTemp>
    </PropertyGroup>

    <ItemGroup>
      <TestFiles Condition="'%(TestFiles.Identity)' == '%(Identity)'" >
        <BinFolder>$(_BinFolderTemp)</BinFolder>
      </TestFiles>
    </ItemGroup>
  </Target>











	<!-- ========================================
			'CleanAll' private helper targets 
	========================================= -->
	
	<Target Name="_SanityCheck_CleanAll" DependsOnTargets="_SanityCheck_VariantProperties">
	</Target>

	<Target Name="_DeleteArtifactAndBinFolders">
		<ItemGroup>
			<BinDirsToRemove Include="$([System.IO.Directory]::GetDirectories('$(VariantArtificatFolderRoot)'))" Condition ="Exists($(VariantArtificatFolderRoot))"/>
			<ArtifactDirsToRemove Include="$([System.IO.Directory]::GetDirectories('$(VariantBinFolderRoot)'))" Condition ="Exists($(VariantArtificatFolderRoot))"/>
		</ItemGroup>
		<RemoveDir Directories="@(BinDirsToRemove)" />
		<RemoveDir Directories="@(ArtifactDirsToRemove)" />

		<Message Text="Deleted: %(BinDirsToRemove.Identity)" Importance="high" />
		<Message Text="Deleted: %(ArtifactDirsToRemove.Identity)" Importance="high" />
	</Target>








	<!-- ========================================
			'Clean' private helper targets 
	========================================= -->
	
	<Target Name="_SanityCheck_CleanSingle" DependsOnTargets="_SanityCheck_VariantProperties">

	</Target>

	<Target Name="_DeleteArtifactAndBinFoldersForSingleTest" Outputs="%(TestFiles.Identity)">

		<PropertyGroup>
			<!-- <GhostBinDirToRemove>%(TestFiles.BinFolder)</GhostBinDirToRemove> -->
			<GhostArtifactDirToRemove>%(TestFiles.ArtifactFolder)\ghost</GhostArtifactDirToRemove>
			<!-- <NativeBinDirToRemove>%(TestFiles.BinFolder)</NativeBinDirToRemove> -->
			<NativeArtifactDirToRemove>%(TestFiles.ArtifactFolder)\$(_NativeToolChain)</NativeArtifactDirToRemove>
		</PropertyGroup>

		<!-- <RemoveDir Directories="$(GhostBinDirToRemove)" /> -->
		<RemoveDir Directories="$(GhostArtifactDirToRemove)" Condition=" '$(BuildGhostAsWell)' == 'true' " />
		<!-- <RemoveDir Directories="$(NativeBinDirToRemove)" /> -->
		<RemoveDir Directories="$(NativeArtifactDirToRemove)" Condition=" '$(BuildNativeAsWell)' == 'true' " />
		
		<!-- <Message Text="Deleted: $(GhostBinDirToRemove)" Importance="high" /> -->
		<Message Text="Deleted: $(GhostArtifactDirToRemove)" Importance="high" Condition=" '$(BuildGhostAsWell)' == 'true' " />
		<!-- <Message Text="Deleted: $(NativeBinDirToRemove)" Importance="high" /> -->
		<Message Text="Deleted: $(NativeArtifactDirToRemove)" Importance="high" Condition=" '$(BuildNativeAsWell)' == 'true' " />

	</Target>
	
	











	<!-- ========================================
			'Build' private helper targets 
	========================================= -->
	
	<Target Name="_SanityCheck_SingleTest" DependsOnTargets="_SanityCheck_BuildAllTests" >
	</Target>

  <Target Name="_FilterTestFileList">
    <FilterFilesListTask Files="@(TestFiles)" Folders="@(TestFoldersItem)" Glob="$(PassedGlob)" Root="$(ProjectRoot)">
      <Output TaskParameter="FilteredFiles" ItemName="_FilteredFilesItems" />
    </FilterFilesListTask>

    <ItemGroup>
      <TestFiles Remove="%(TestFiles.Identity)" />
      <TestFiles Include="@(_FilteredFilesItems)" />
    </ItemGroup>

    <Message Text="Found File: %(TestFiles.Identity)" />
  </Target>
  
	<Target Name="_FindNativeMain">
		<FindFileTask FileToFind="nativemain.c" PathsToSearch="@(_NativeAllIncludedPathItem)">
			<Output TaskParameter="FoundFileFullPath" PropertyName="_NativeMain" />
		</FindFileTask>
	</Target>









	<!-- ========================================
			'BuildAllTests' private helper targets 
	========================================= -->
	
	<Target Name="_SanityCheck_BuildAllTests" DependsOnTargets="_SanityCheck_VariantProperties;_SanityCheck_BuildRelatedProperties">
	</Target>
	
	<!-- Create artifact folders for each Test -->
	<Target Name="_CreateArtifactFolderForEachTestFile" Outputs="%(TestFiles.Identity)" DependsOnTargets="">
		<MakeDir Directories="%(TestFiles.ArtifactFolder)" />
	</Target>

	<!-- Create bin folders for each Test -->
	<Target Name="_CreateBinFolderForEachTestFile" Outputs="%(TestFiles.Identity)">
    <MakeDir Directories="%(TestFiles.BinFolder)" />
	</Target>


	<!-- Tests whether source and test file lists contain some items -->
	<Target Name="_TestIfNoTestsFound">
		<Error Text="No test Files found" Condition=" !Exists(%(TestFiles.Identity)) " />
	</Target>

	<Target Name="_TestIfNativeMainNotFound">
		<Error Text="NativeMain ('$(_NativeMain)') file does not exists" Condition="!Exists($(_NativeMain)) AND '$(BuildNativeAsWell.ToLower())' == 'true'" />
	</Target>

	<Target Name="_AppendVariantSwitchToDefines">
		<PropertyGroup>
			<Defines>$(_VariantSwitch);$(Defines)</Defines>
			<Defines>$(Defines.Trim(';'))</Defines>
		</PropertyGroup>
	</Target>

	<!-- Builds all the Tests included in @(TestFiles) -->
	<Target Name="_BuildTests" DependsOnTargets="_AppendVariantSwitchToDefines">
		
    <MSBuild Projects="$(TargetsToolPath)\tests.builder"
						 Properties="TestFile = %(TestFiles.Identity); TestFileArtifactFolder = %(TestFiles.ArtifactFolder)\; 
													 TestPropertyFile = %(TestFiles.ArtifactFolder)\%(TestFiles.Filename).properties; 
													 TestFileBinFolder = %(TestFiles.BinFolder)\;
													 NativeIncludedPaths = $(_AllNativeIncludedPaths); GhostIncludedPaths = $(_AllGhostIncludedPaths); 
													 BuildNativeAlso = $(BuildNativeAsWell); BuildGhostAlso = $(BuildGhostAsWell);
													 NativeMainFile = $(_NativeMain); NativeProcessor = $(NativeCPU);  
													 NativeToolChainID = $(_NativeToolChain); _ProjectFile = $(ProjectFile); 
													 _Defines = $(Defines); _ToolChainPath = $(ToolChainPath);
													 _ToolChainTimeoutPeriod = $(ToolChainTimeoutPeriod);
													 __VariantName = $(_VariantName); _DefaultPropertyFile = $(DefaultPropertyFile) "
						 Targets="TestBuildTestFile" />
	</Target>


</Project>
