
##############################Start Script #########################################
#  Example:
#  ChangeLA -strComputer mweeks -username mweeks -add
#  ChangeLA -strComputer mweeks -username mweeks -remove
#  changeLA -strComputer mweeks
 
Function ChangeLA([string]$strComputer, [switch]$add, [switch]$remove, [string]$username)
{
    $DOMAIN = $env:USERDNSDOMAIN
    if ($strComputer -eq "")
    {
        "Please specify a computername, IP or system name with ps:> changeLA -strComputer test-lt"
        break
    }
 
    $computer = [ADSI]("WinNT://" + $strComputer + ",computer")
    #$computer.name 
				
    #$strComputer				
 
    $Group = $computer.psbase.children.find("administrators")
    #$Group.name 
 
    # This will list what’s currently in Administrator Group so you can verify the result
    function ListAdministrators	{$members= $Group.psbase.invoke("Members") | %{$_.GetType().InvokeMember("Name", ‘GetProperty’, $null, $_, $null)} 
    $members}
 
    "Current Administrators on $strComputer"
    ListAdministrators
    "`n"
    if ($username -eq "")
    {
        out-null
    }
    else
    {
        if ($remove -ne $false)
        {
            $Group.Remove("WinNT://" + $domain + "/" + $username)
            "Administrators after script:"
            ListAdministrators
            "`n"
        }
 
        elseif ($add -ne $false)
        {
            $Group.add("WinNT://" + $domain + "/" + $username)
            "Administrators after script:"
            ListAdministrators
            "`n"
        }   
        else
        {
            "what do you want me to do? please specify with changeLA -strComputer test-lt -username test -add"
        } 
 
    }
    $username = ""
    $strComputer = ""
    $add = $false
    $remove = $false
} 
 
##############################End Script #########################################
