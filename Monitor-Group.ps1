##############################Start Script #########################################
function ADMonitor ($interim,$group) {
    if ((Get-PSSnapin | where {$_.name -like "*quest*"}) -eq $null)
    {
        add-PSSnapin quest.activeroles.admanagement
    }
    if ((Get-QADGroup $group) -ne $null)
    {
        while (1)
        {
            $current = "c:\output\$group-new.txt"
            $compare = "c:\output\$group-old.txt"
 
            Get-QADGroupMember $group | select -ExpandProperty name | out-file $current
            if (Test-Path $compare)
            {
                $findings = Compare-Object (Get-Content $compare) (Get-Content $current)
                if ($findings -ne $null)
                {
                    Send-MailMessage -SmtpServer $server `
                     -To mikey@company.com `
                     -from ADMonitor@company.com `
                     -Subject "Group Changed!" `
                     -Body $findings
                }
                Move-Item $current $compare
            }
            else
            {
                Move-Item $current $compare -force
                Send-MailMessage -SmtpServer $server `
                -To mikey@company.com `
                -from ADMonitor@company.com `
                -Subject "Monitoring started for $group" 
            }
    
            Sleep $interim
        }
    }
    else
    {
        exit
    }
}
 
 
 
##############################END SCRIPT #########################################