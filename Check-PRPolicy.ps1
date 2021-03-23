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

$PolicyID = '0609b952-1397-4640-95ec-e00a01b2c241' #constant for Build policy

Write-Host "Getting build definitions (pipelines)"
$APIUrlDefinitions = "$DevOpsUrl/_apis/build/definitions/?api-version=6.0"
$Definitions = (Invoke-WebRequest -Uri $APIUrlDefinitions -Headers $Header -Method GET).content | ConvertFrom-Json 

Write-Host "Getting repositories"
$APIUrlRepo = "$DevOpsUrl/_apis/git/repositories?api-version=6.0"
$Repos = (Invoke-WebRequest -Uri $APIUrlRepo -Headers $Header -Method GET).content | ConvertFrom-Json 

foreach($Repo in $Repos.value) {
  Write-Host "Checking $($Repo.name)"
  $APIUrlConfig = "$DevOpsUrl/_apis/git/policy/configurations?repositoryId=$($Repo.id)&refName=refs/heads/master&api-version=6.1-preview.1"
  $Configs =(Invoke-WebRequest -Uri $APIUrlConfig -Headers $Header -Method GET).content | ConvertFrom-Json 
  if ($Configs.value | Where-Object {$_.type.id -eq "$PolicyID"}) {
    Write-Host "Build policy exists"
  } else {
    $APIUrlPolicy = "$DevOpsUrl/_apis/policy/configurations?api-version=6.0"
    $Definition = $Definitions.value | Where-Object {$_.name -eq $Repo.name}
    if ($Definition) {
      Write-Host "Definition found: $($Definition.name) $($Definition.id)"
      $Body=@{
        "isEnabled"= $true;
        "isBlocking"= $true;
        "type" = @{
          "id"="$PolicyID"
        }
        "settings"= @{
          "buildDefinitionId"= $Definition.id;
          "queueOnSourceUpdateOnly"= $true;
          "manualQueueOnly"= $false;
          "displayName"= "$($Definition.name) PR";
          "validDuration"= 0.0;
          "scope"= @(
            @{
              "refName"= "refs/heads/master";
              "matchKind"= "Exact";
              "repositoryId"= "$($Repo.id)"
            }
          )
        }
      }
      if (-not $Test) {
        Write-Host "Creating policy..."
        $Result = Invoke-WebRequest -Uri $APIUrlPolicy -Headers $Header -Method POST -Body ($Body|convertto-json -Depth 10)
      }
    } else {
      Write-Host "Definition with name $($Repo.name) not found"
    }
  }
}