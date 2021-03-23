[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    $PAT,
    [Parameter(Mandatory=$true)]
    $Account,
    [Parameter(Mandatory=$true)]
    $Project,
    [switch]$Test
)

$Token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($PAT)"))
$Header = @{"Authorization" = "Basic "+$Token; "content-type" = "application/json"}
$DevOpsUrl = "https://dev.azure.com/$Account/$Project"

$APIUrlFolders = "$DevOpsURL/_apis/build/folders/?api-version=6.0-preview.2"
$APIUrlDefinitions = "$DevOpsURL/_apis/build/definitions/?api-version=6.0"
$Folders = (Invoke-WebRequest -Uri $APIUrlFolders -Headers $Header -Method GET).content | ConvertFrom-Json
$Definitions = (Invoke-WebRequest -Uri $APIUrlDefinitions -Headers $Header -Method GET).content | ConvertFrom-Json 

foreach($pipeline in ($Definitions.value | Where-Object {$_.path -eq '\'})) {
    $TargetRootFolder = $Folders.value | Where-Object {($pipeline.name -like  "$($_.Path.TrimStart('\'))*")-and ($_.Path -ne '\')}
    $TargetFolder = ''
    if ($TargetRootFolder) {
        if ($pipeline.name.EndsWith(' Master')) {
            $TargetFolder = "$($TargetRootFolder.Path)\Master"
        } elseif ($pipeline.name.EndsWith(' Release')) {
            $TargetFolder = "$($TargetRootFolder.Path)\Release"
        } else {
            $TargetFolder = "$($TargetRootFolder.Path)"
        }
        if ($TargetFolder -ne $pipeline.folder) {
            Write-Host "$($pipeline.name) -> $($TargetFolder)"
            if (-not $Test) {
                $APIDefinitionUpdateUrl = $pipeline.url+'&api-version=6.0'
                $Definition = Invoke-RestMethod -Uri "$DevOpsURL/_apis/build/definitions/$($pipeline.id)?api-version=6.0" -Method GET -Headers $Header
                $Definition.path = $TargetFolder
                $Result = Invoke-WebRequest -Uri $APIDefinitionUpdateUrl -Headers $Header -Method PUT -Body ($Definition|ConvertTo-json -Depth 10)
                #Write-Host "$Result"
            }
        }
    } else {
        Write-Host "$($pipeline.name) -> ???"
    }
}