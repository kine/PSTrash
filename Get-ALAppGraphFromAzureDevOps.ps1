param(
    [parameter(Mandatory=$true)]
    $Account,
    [parameter(Mandatory=$true)]
    $ProjectName,
    [parameter(Mandatory=$true)]
    $PAT,
    $AppJsonPath='MainApp',
    [switch]$Mermaid,
    [switch]$IncludeMicrosoft
)
import-module vsteam

set-vsteamaccount -Account $Account -PersonalAccessToken $PAT
$repos = Get-VSTeamGitRepository -ProjectName $ProjectName
$info = Get-VSTeamInfo

if ($Mermaid) {
    Write-Host "::: mermaid"
    Write-Host "graph LR"
} else {
    Write-Host "digraph G {"
    Write-Host "    rankdir=""LR"""
}
foreach($repo in ($repos | Sort-Object -Property name)) {
    $appJson=Invoke-VSTeamRequest -version 5.1 -method get -Url "$($info.Account)/$ProjectName/_apis/git/repositories/$($repo.Name)/items?path=$($AppJsonPath)/app.json" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    if ($appJson) {
        if ($Mermaid) {
            Write-Host "$($appJson.name -replace ' ','')[$($appJson.name)];"
            Write-Host "click $($appJson.name -replace ' ','') ""$($repo.RemoteUrl -replace '//.*@','//')"";"
        } else {
            Write-Host "    ""$($appJson.name)"""
        }
        foreach($dep in $appJson.dependencies) {
            if ($IncludeMicrosoft -or ($dep.publisher -ne 'Microsoft')) {
                if ($Mermaid) {
                    Write-Host "$($appJson.name -replace ' ','')-->$($dep.name -replace ' ','');"
                } else {
                    Write-Host "    ""$($appJson.name)""->""$($dep.name)"""
                }
            }
        }
    }
}
if ($Mermaid) {
    Write-Host ":::"
} else {
    Write-Host "}"
}