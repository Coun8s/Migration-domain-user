# Migrate User
$ScanUser = 'olduser'
$LoadCompName = 'new-pc-name'

# Admins users
$ScanDom = 'old-domain.local'
$ScanDomAdm = 'admin-old-domain'
$ScanDomAdmPass = 'pass-old-domain'
$LoadDom = 'new-domain.local'
$LoadDomAdm = 'admin-new-domain'
$LoadDomAdmPass = 'pass-new-domain'

# Create folders
New-Item -ItemType Directory -Force -Path C:\Migration\USMT
New-Item -ItemType Directory -Force -Path C:\Migration\MIG
New-Item -ItemType Directory -Force -Path C:\Migration\tmp

## Download Windows USMT ##

################################################ if use proxy #################################################
### Proxy ###                                                                                       #
#                                                                                                             #
#$ProxyIP = '1.2.3.4'                                                                                    #
#$ProxyPort = '3128'                                                                                          #
#$ProxyUser = 'proxy-user'                                                                                           #
#$ProxyDomain = 'old-domain.local'                                                                                 #
#$ProxyPass = 'proxy-pass'                                                                                 #
#                                                                                                             #
#netsh winhttp set proxy "${ProxyIP}:$ProxyPort"                                                              #                                     
#$CredentialsProxy = New-Object System.Net.NetworkCredential("$ProxyUser", "$ProxyPass", "$ProxyDomain")      #
#$WebClient.Proxy.Credentials=$CredentialsProxy                                                               #
###############################################################################################################

$WebClient = New-Object System.Net.WebClient
$download_url = "https://go.microsoft.com/fwlink/?linkid=2086042"
$local_path = "C:\Migration\tmp\adksetup.exe" 
$WebClient.DownloadFile($download_url, $local_path)

## Install Windows USMT ##
Start-Process -Wait -FilePath "C:\Migration\tmp\adksetup.exe" -ArgumentList "/quiet", "/installpath C:\Migration\USMT", "/features OptionId.UserStateMigrationTool", "/norestart" -PassThru

## Create profile migration ##
$OSVersion = (get-itemproperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName).ProductName
if ($OSVersion -like "Windows 7*") {
    $targetwindows = "/targetwindows7"
} elseif ($OSVersion -like "Windows 8*") {
    $targetwindows = "/targetwindows8"
} else {
    $targetwindows = $null
}

$OSbit = (Get-WmiObject Win32_Processor).DataWidth
if ($OSbit -like "64") {
    cd 'C:\Migration\USMT\Assessment and Deployment Kit\User State Migration Tool\amd64'
    .\scanstate.exe C:\Migration\MIG\ /o /i:MigApp.xml /i:MigUser.xml /ue:*\* /ui:*\${ScanUser} $targetwindows /v:13 /l:C:\Migration\MIG\scanstate.log

} else {
    cd 'C:\Migration\USMT\Assessment and Deployment Kit\User State Migration Tool\x86'
    .\scanstate.exe C:\Migration\MIG\ /o /i:MigApp.xml /i:MigUser.xml /ue:*\* /ui:*\${ScanUser} $targetwindows /v:13 /l:C:\Migration\MIG\scanstate.log
}

$securePassSortpc = ConvertTo-SecureString "$ScanDomAdmPass" -AsPlainText -Force
$credSortpc = New-Object System.Management.Automation.PSCredential ("$ScanDom\$ScanDomAdm", $securePassSortpc)

$securePassRtrs = ConvertTo-SecureString "$LoadDomAdmPass" -AsPlainText -Force
$credRtrs = New-Object System.Management.Automation.PSCredential ("$LoadDom\$LoadDomAdm", $securePassRtrs)


$system=Get-WmiObject -Class Win32_ComputerSystem
$system.Rename($LoadCompName);
if ((gwmi win32_computersystem).partofdomain -eq $true) {
    Remove-Computer -Credential $credSortpc -Force; Add-Computer -domainname $LoadDom -Credential $credRtrs
} else {
    Add-Computer -DomainName $LoadDom -Credential $credRtrs
}

# Adding a task to the scheduler 
schtasks /create /tn "Migration_USERS" /xml "C:\Migration\Scripts\Migration_USER.xml"

# PC restart
Restart-Computer