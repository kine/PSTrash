# Script will go through all repositories in the Azure DevOps (Filter can limit which one) and if the FileName file exists, go through all FileFilter files
# and if found line with
# [Test]
# and next two lines is not including [TestPermissions...]
# it will insert line with
#    [TestPermissions(TestPermissions::Disabled)]
# All is done over master branch and pushed back with [Skip CI] to not trigger build (to prevent overflooding the pipelines)
param(
    $PAT = '',
    $Filter = '',
    $Account,
    $ProjectName,
    $FileName = '/TestApp/App.json',
    $FileFilter = '/TestApp/*.al',
    $RootRepoPath = 'c:\git\_update'
    )


if (-not $PAT) {
    $PAT = Read-Host -Prompt "Enter PAT"
}

if (-not $Filter) {
    $Filter = Read-Host -Prompt "Enter Repository Filter (like PTE*)"
}

function UpdateApp
{
    param(
        $RepoName,
        $Template
    )

    $RepoURL = "https://$($Account).visualstudio.com/$($ProjectName)/_git/" + [uri]::EscapeDataString($RepoName)
    #region Clone repo locally and modify it, push back
    #region Local repo settings

    $RepoPath = Join-Path $RootRepoPath $RepoName
    if (Test-Path -Path $RepoPath) {
        Write-Host "Removing existing $RepoPath"
        Remove-Item -Path $RepoPath -Recurse -Force
    }
    #endregion

    #region clone and checkout branch
    Push-Location
    write-host "Doing: git clone -q $RepoURL '$RepoPath'"
    git clone -q "$RepoURL" "$RepoPath"


    Set-Location $RepoPath
    Write-Host "Checkout master" -ForegroundColor Green
    git checkout master -q 2>&1  
    #endregion

    #region Update all test functions
    $TestAppPath = (Join-Path $RepoPath $FileFilter)
    $AlFiles = Get-ChildItem -Path $TestAppPath -Recurse
    foreach ($ALFile in $AlFiles) {
        Write-Host "Solving $($ALFile.FullName)" -ForegroundColor Green
        git checkout HEAD -- $ALFile.FullName
        $Content = get-content -Path $ALFile.FullName
        $NewContent = @()
        0..($Content.Count-1) | ForEach-Object {
            if (($Content[$_] -match ' +\[Test\]') -and ($Content[$_+1] -notmatch ' *\[TestPermissions\(.+\)\]') -and ($Content[$_+2] -notmatch ' *\[TestPermissions\(.+\)\]')) {
                $NewContent += $Content[$_]
                $NewContent += "    [TestPermissions(TestPermissions::Disabled)]"
            } else {
                $NewContent += $Content[$_]
            }
        }
        $NewContent | set-content -Path $ALFile.FullName -Force

    }
    #endregion

    git add -A 2>&1
    git commit -m "Add TestPermissions attribute [Skip CI]" 2>&1
    Write-Host "Pushing the repo back" -ForegroundColor Green
    git push 2>&1 | Out-null

    Pop-Location
    #endregion

}
import-module vsteam


set-vsteamaccount -Account $Account -PersonalAccessToken $PAT
$repos = Get-VSTeamGitRepository -ProjectName $ProjectName | Sort-Object -Property name | where-object {($_.name -ne 'MSDyn365BC_AppTemplate') -and ($_.name -like $Filter)}
$info = Get-VSTeamInfo

foreach($repo in $repos) {

    Write-Verbose "$($repo.Name)"
    $FileContent=Invoke-VSTeamRequest -version 5.1 -method get -Url "$($info.Account)/$ProjectName/_apis/git/repositories/$($repo.Name)/items?path=$FileName" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    if ($FileContent) {
        #$AppJson = $FileContent | convertfrom-json
        #if (-not $FileContent.applicationInsightsConnectionString) {
            Write-Host "$($repo.Name) - To update ($($FileContent.application))"
            UpdateApp -Repo "$($repo.Name)" -Template $Branch
        #} else {
        #    Write-Host "$($repo.Name) - Ok"
        #}
    }
}
