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
    Write-Output "::: mermaid"
    Write-Output "graph LR"
} else {
    Write-Output "digraph G {"
    Write-Output "    rankdir=""LR"""
}
foreach($repo in ($repos | Sort-Object -Property name)) {
    $appJson=Invoke-VSTeamRequest -version 5.1 -method get -Url "$($info.Account)/$ProjectName/_apis/git/repositories/$($repo.Name)/items?path=$($AppJsonPath)/app.json" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    if ($appJson) {
        if ($Mermaid) {
            Write-Output "$($appJson.name -replace ' ','')[$($appJson.name)];"
            Write-Output "click $($appJson.name -replace ' ','') ""$($repo.RemoteUrl -replace '//.*@','//')"";"
        } else {
            Write-Output "    ""$($appJson.name)"""
        }
        foreach($dep in $appJson.dependencies) {
            if ($IncludeMicrosoft -or ($dep.publisher -ne 'Microsoft')) {
                if ($Mermaid) {
                    Write-Output "$($dep.name -replace ' ','')-->$($appJson.name -replace ' ','');"
                } else {
                    Write-Output "    ""$($appJson.name)""->""$($dep.name)"""
                }
            }
        }
    }
}
if ($Mermaid) {
    Write-Output ":::"
} else {
    Write-Output "}"
}