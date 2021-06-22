$LoadUser = 'newuser'
$ScanUser = 'olduser'
$ScanDom = 'old-domain'
$LoadDom = 'new-domain'

$OSbit = (Get-WmiObject Win32_Processor).DataWidth

# Migration in new user
if ($OSbit -like "64") {
    cd 'C:\Migration\USMT\Assessment and Deployment Kit\User State Migration Tool\amd64'
    .\loadstate.exe C:\Migration\MIG\ /i:MigApp.xml /i:MigUser.xml /md:*:$LoadDom /ue:* /ui:$ScanUser /mu:$ScanDom\${ScanUser}:$LoadDom\$LoadUser /v:13 /l:C:\Migration\MIG\loadstate.log
    

} else {
    cd 'C:\Migration\USMT\Assessment and Deployment Kit\User State Migration Tool\x86'
    .\loadstate.exe C:\Migration\MIG\ /i:MigApp.xml /i:MigUser.xml /md:*:$LoadDom /ue:* /ui:$ScanUser /mu:$ScanDom\${ScanUser}:$LoadDom\$LoadUser /v:13 /l:C:\Migration\MIG\loadstate.log
}

# Delete a task to the scheduler
schtasks /delete /tn Migration_USERS /f

# Restart PC
Restart-Computer