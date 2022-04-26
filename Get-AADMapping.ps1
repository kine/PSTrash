# Scripts could be used to get AAD mapping json for PowerBI app https://github.com/microsoft/BCTech/blob/master/samples/AppInsights/PowerBI/Reports/AppSource/README.md#power-bi-prerequisites
# Just download CSV with the customers from your Microsoft Partner Center and use it as input into this script. Output is minified json you can use in the settings of the PowerBI App

param(
    [Parameter(Mandatory=$true)]
    $CsvFile
)

$Customers = Import-Csv -Path $CsvFile -Delimiter ','

$map = @()
foreach($Customer in $Customers) {
    $NewMap = New-Object -TypeName PSObject
    $NewMap | Add-Member -MemberType NoteProperty -Name 'AAD tenant id' -Value $Customer.'Microsoft ID'
    $NewMap | Add-Member -MemberType NoteProperty -Name 'Domain' -Value $Customer.'Primary domain name'
    $map += $NewMap
}
$Mapping=@{"map"=$map}

$Mapping | ConvertTo-Json -Depth 3 -Compress