<#
.SYNOPSIS
    Create new pipeline definition based on YAML file
.DESCRIPTION
    Create new pipeline definition based on YAML file
.EXAMPLE
    PS C:\> $repo = Get-VSTeamGitRepository -Name reponame -ProjectName myproject
    PS C:\> . .\New-ALBuildDefinition.ps1 -Account myaccount -ProjectName myproject -PAT mypat -Repository $repo -YAMLFile ".azuredevops/azure-pipelines.yml" -PipelineName PipelineName -Path "Tests"
.INPUTS
    Inputs (if any)
.OUTPUTS
    The pipeline definition
.NOTES
    Repository parameter should be result of Get-VSTeamGitRepository call
#>
param(
    [parameter(Mandatory=$true)]
    $Account,
    [parameter(Mandatory=$true)]
    $ProjectName,
    [parameter(Mandatory=$true)]
    $PAT,
    $Repository,
    $YAMLFile,
    $PipelineName,
    $Path
)
import-module vsteam

set-vsteamaccount -Account $Account -PersonalAccessToken $PAT

$json = @{
    "process" = @{
        "yamlFilename" = "$YAMLFile";
        "type" = 2
    }; 
    "repository" = @{
        "defaultBranch" = "$($Repository.DefaultBranch)";
        "id" = "$($Repository.ID)";
        "type" = "TfsGit"
    };
    "name"="$PipelineName";
    "path"="$Path";
    "queue"=@{};
    "triggers"=@(
        @{
            "batchChanges" = "false";
            "triggerType" = "continuousIntegration";
            "settingsSourceType" = 2;
            "maxConcurrentBuildsPerBranch" =1

        }
    )
}

$bodyFileName = (Join-Path $env:TEMP 'build.json')
$json | ConvertTo-Json | set-content -Path $bodyFileName

Add-VSTeamBuildDefinition -InFile $bodyFileName -ProjectName $ProjectName

Remove-Item -Path $bodyFileName -Force
