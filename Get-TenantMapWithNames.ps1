# Description: Get the tenant names for the tenant ids in the input file and add primary domain names to them
# Input: AppInsights AppId and API Key to run this KQL query:
# traces
# | extend aadTenantId = tostring(customDimensions.aadTenantId)
# | where strlen( aadTenantId) == 36
# | distinct aadTenantId,''
# Parameters: AADAppid, AADAppSecret, AADMyTenantId - these are the app id and secret for the app registered in the tenant which will be used to authorize Graph API calls
# Output: A json with the tenant primary domain names added to the customerName column and exported as json map for usage in PowerBI Business Central Telemetry apps

param(
    $AppInsightsAppId,
    $AppInsightsAPIKey,
    $AADAppid,
    $AADAppSecret,
    $AADMyTenantId
)

function Get-OAuthToken {
    param(
        $TenantId,
        $AppId,
        $AppSecret,
        $scope
    )

    $BasicToken = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("${AppId}:${AppSecret}"))
    $header_token = @{"Content-Type" = "application/x-www-form-urlencoded" ; "authorization" = "basic $BasicToken" }
    $TokenUrl = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
    $body = @{
        grant_type = "client_credentials"; scope = $scope;
        client_secret = $AADAppSecret; client_id = $AADAppId
    }

    $response = Invoke-RestMethod -Method Post -Uri $TokenUrl -Body $body -Headers $header_token
    return $response
}

Write-Host "Getting tenants from telemetry"
$tenants = .\Get-TelemetryData.ps1 -appid $AppInsightsAppId -apikey $AppInsightsAPIKey -kqlquery "traces | extend aadTenantId = tostring(customDimensions.aadTenantId) | where strlen( aadTenantId) == 36 | distinct aadTenantId,''"
$tenants
Write-Host "Getting OAuth2 token for Graph API"
$response = Get-OAuthToken -AppId $AADAppId -AppSecret $AADAppSecret -TenantId $AADMyTenantId -scope "https://graph.microsoft.com/.default"
$token = $response.access_token;

$map = @()
foreach ($tenant in $tenants) {
    Write-Host "Ckecking $($tenant.aadTenantId)" -ForegroundColor green
    $tenantInfo = .\Get-TenantIdInfo.ps1 -TenantId $tenant.aadTenantId -token $token
    Write-Host "Domain: $($tenantInfo.defaultDomainName) DisplayName: $($tenantInfo.displayName)"
    $NewMap = New-Object -TypeName PSObject
    $NewMap | Add-Member -MemberType NoteProperty -Name 'AAD tenant id' -Value $tenant.aadTenantId
    $NewMap | Add-Member -MemberType NoteProperty -Name 'Domain' -Value $tenantInfo.defaultDomainName
    $map += $NewMap
   
}

$Mapping = @{"map" = $map }

Write-Host "Exporting map to $outputfile"

$mapdata = $Mapping | ConvertTo-Json -Depth 3 -Compress
$mapdata
