##############################START SCRIPT #########################################
if ((Get-PSSnapin | where {$_.name -like "*quest*"}) -eq $null)
{
    add-PSSnapin quest.activeroles.admanagement
}
# update server list from domain controller
    $newList = "F:\AD-Computers\Servers-new.txt"
    $oldList = "F:\AD-Computers\Servers.txt"
    
    get-qadcomputer -SizeLimit 0 `
        | select -expandproperty name `
	    | out-file $newList
    if ((Test-Path $oldList) -eq $False)
    {
        Move-Item $newList $oldList
    }
    else
    { 
        $Change = Compare-Object (Get-Content $oldList) (Get-Content $newList)
 
        if ($Change)
        {
            Send-MailMessage `
            -SmtpServer $SERVER `
            -to mikey@company.com `
            -from ADMonitor@q2ebanking.com `
            -Subject "System change on domain" -Body $Change
            
            move-item $newlist $oldList
        }
     }
#function to acquire local admins:
function listlocal-remote ($strComputer,$localgroup)
{
    $computer = [ADSI]("WinNT://" + $strComputer + ",computer")
    $Group = $computer.psbase.children.find($localgroup)
   
    # This will list what’s currently in Administrator Group so you can verify the result
    function ListUsers{
        $members= $Group.psbase.invoke("Members") `
            | %{$_.GetType().InvokeMember("Name", ‘GetProperty’, $null, $_, $null)} 
        $members
    }
 
    "Users in the $localgroup Group on $StrComputer"   
    ListUsers
    ""
}
 
#Alright - let's get some local admins
    $servers = Get-Content $oldList
    foreach ($server in $servers)
    {
        $newAdmins = "F:\AD-Computers\LAs\$server-localadmins-new.txt"
        $oldAdmins = "F:\AD-Computers\LAs\$server-localadmins.txt"
        
                
        listlocal-remote -strComputer $server -localgroup Administrators | out-file $newAdmins
                       
        if ((test-path $oldAdmins) -eq $false)
        {
            Move-Item $newAdmins $oldAdmins     
        }
        elseif ((Test-Path $newAdmins) -eq $false)
        {
            Out-Null
        }
        else
        {
            $LAChange = Compare-Object -old $oldAdmins -new $newAdmins -msg $server
            if ($LAChange)
            {
                Send-MailMessage `
                    -SmtpServer $server `
                    -to mikey@company.com `
                    -from LAMonitor@company.com `
                    -Subject "Local Administrators account changed on $server" -Body $LAChange
                  
            }
            Move-Item $newAdmins $oldAdmins           
        }
    }
##############################END SCRIPT ########################################
