#Colby Austin
#This script will auto generate the list of users in AD groups and sort
#   them out by who needs to review them.
#All you need to do is email the folders to their respective users and
#   for their response
#
#
#8/23/2021
#   -created starting checks and prompts
#   -Created config file for US
#   -completed prechecks and loop structure for reading the config files
#
#8/24/2021
#   -Finishing contents of loop to connect to domains and generate the list
#   -Finish config file for all regions
#
#
#
#
##########################################################################
Import-Module activedirectory

if ($error -ne $null){
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show("The ActiveDirectory Module for Windows PowerShell is not installed.`n`nThis is installed as part of the Remote Server Administration Tools KB. Please refer to the notes for further details.`n`nClick OK to exit...","AD PowerShell Module Not Installed",0,"error") ; exit
}

###PreChecks                                               add a line below for each conf file for audits
New-Item -ItemType Directory -Force -Path C:\AD_Audit_logs\Global

Clear-Host
###Print options                                          add a line below for each conf file for audits
Write-Host "Audits:"
Write-Host "1. Global"

$audit = Read-Host "enter the number of the region, that you want to audit."

if ($audit -is [int]){
    Write-Host "Please Enter a number corresponding to the region, not a letter or symbol"
    exit
}

if (-not(($audit -gt 0) -and ($audit -lt 8))){
    Write-Host 'Please use a number corresponding to the region. ie. 1 through 7'
    exit
}

$confirmation = Read-Host "Do you want to audit the $audit ? y or n"
if ($confirmation -eq "n"){
    Write-Host "Please Restart script and select the audit"
    exit
}

### Sets domain and psdrivename for each audit, depending on how the domain is set up you may not need the psdrivename
### add a new line for each audit with the correct info corresponding to the number assigned to it above
switch($region) {
    "1"  {$config = "Global.conf";      $setdomain = ;         $psdrivename = "corp";        break}

# Switch to correct AD
Get-ADDomain -server $setdomain
$date = Get-Date -format "dd-MM-yyyy"
$file = Get-Content -Path $config
New-Item -ItemType directory -Path \Audit_files

#This loops through each line in the config file
ForEach ($line in $file){
    $line = $line -split','
    $output_path = "Audit_" + $date + "\" + $line[0]
    New-Item -ItemType directory -Path $output_path

#Loops through all of the Groups on the current line and generates a csv file and stores it in the corresponding folder. Groups are sorted by who is to review them.
    $Groups = $line[1]
    $Groups = $Groups -split':'
    Write-Host "current group list is $Groups"
    ForEach ($group in $Groups){
        $fullname =  $output_path + "\" + $group + ".csv"
        New-Item -ItemType file -Path $fullname
        Get-ADGroupMember -identity $group -recursive | Select-Object samaccountname |
        ForEach-Object {Get-ADUser -Filter "samaccountname -eq '$($_.samaccountname)'" -Properties DisplayName, SamAccountName, Title, Description, lastlogondate, whencreated, enabled
        } | Select-Object DisplayName, SamAccountName, Title, Description, lastlogondate, whencreated, enabled | Export-Csv -Path $fullname
    }
}

Write-Host -Object ('All done! press anything to close' -f [System.Console]::ReadKey().Key.ToString());
