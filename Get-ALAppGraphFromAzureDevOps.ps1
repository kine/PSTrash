param(
    [parameter(Mandatory=$true)]
    $Account,
    [parameter(Mandatory=$true)]
    $ProjectName,
    [parameter(Mandatory=$true)]
    $PAT,
    $AppJsonPath='MainApp',
    $IncludeMicrosoft
)
import-module vsteam

set-vsteamaccount -Account $Account -PersonalAccessToken $PAT
$repos = Get-VSTeamGitRepository -ProjectName $ProjectName
$info = Get-VSTeamInfo

Write-Host "digraph G {"
Write-Host "    rankdir=""LR"""
foreach($repo in $repos) {
    $appJson=Invoke-VSTeamRequest -version 5.1 -method get -Url "$($info.Account)/$ProjectName/_apis/git/repositories/$($repo.Name)/items?path=$($AppJsonPath)/app.json" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    foreach($dep in $appJson.dependencies) {
        if ($IncludeMicrosoft -or ($dep.publisher -ne 'Microsoft')) {
            Write-Host "    ""$($dep.name)""->""$($appJson.name)"""
        }
    }
}
Write-Host "}"