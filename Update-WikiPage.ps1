param(
    [parameter(Mandatory=$true)]
    $Account,
    [parameter(Mandatory=$true)]
    $ProjectName,
    [parameter(Mandatory=$true)]
    $PAT,
    [parameter(Mandatory=$true)]
    $Path,
    [parameter(Mandatory=$true)]
    $WikiId,
    [parameter(Mandatory=$true)]
    $Content
)

$ContentFilename = Join-Path $env:TEMP 'wiki.txt'
Set-Content -Value (@{"content"=($Content | Out-String)} | ConvertTo-Json)  -Path $ContentFilename
Invoke-VSTeamRequest -version 5.1 -method put -Url "$($info.Account)/$ProjectName/_apis/wiki/wikis/$($WikiId)/pages?path=$($Path)&api-version=5.1" -ContentType 'application/json' -InFile $ContentFilename
remove-item -Path $ContentFilename -Force