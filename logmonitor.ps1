####################################START SCRIPT###############################
param([switch]$ShowEvents = $false,[switch]$NoEmail = $false,[switch]$useinstanceid = $false) 
 
 
$log = "Security" 
$hist_file = $log + "_loghist.xml" 
$seed_depth = 100
 
#run interval in minutes - set to zero for runonce, "C" for 0 delay continuous loop. 
$run_interval = 5 
 
$EmailFrom = "SecurityLogMonitor@company.com" 
$EmailTo = "SecurityAlerts@company.com" 
$EmailTo2 = �L1ITHelpdesk@company.com"
$EmailSubject = "SecurityAlert"   
   
$SMTPServer = "server.mail.com" 
$SMTPAuthUsername = "username" 
$SMTPAuthPassword = "password" 
 
$computers = @(get-content F:\output\monitored_computers.txt) 
$event_list = @{} 
Import-Csv "F:\output\alert_events.csv" |% {$event_list[$_.source + '#' + $_.id] = 1} 
 
 
#see if we have a history file to use, if not create an empty $histlog 
if (Test-Path $hist_file){$loghist = Import-Clixml $hist_file} 
 else {$loghist = @{}} 
 
 
$timer = [System.Diagnostics.Stopwatch]::StartNew() 
 
function send_email { 
$mailmessage = New-Object system.net.mail.mailmessage  
$mailmessage.from = ($emailfrom)  
$mailmessage.To.add($emailto) 
$mailmessage.To.Add($EmailTo2)
$mailmessage.Subject = $emailsubject 
$mailmessage.Body = $emailbody 
$mailmessage.IsBodyHTML = $true 
$SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 25)   
$SMTPClient.Credentials = New-Object System.Net.NetworkCredential("$SMTPAuthUsername", "$SMTPAuthPassword")  
$SMTPClient.Send($mailmessage) 
} 
#START OF RUN PASS 
$run_pass = { 
 
$EmailBody = "Log monitor found monitored events. `n" 
 
$computers |%{ 
$timer.reset() 
$timer.start() 
 
Write-Host "Started processing $($_)" 
 
#Get the index number of the last log entry 
$index = (Get-EventLog -ComputerName $_ -LogName $log -newest 1).index 
 
#if we have a history entry calculate number of events to retrieve 
#   if we don't have an event history, use the $seed_depth to do initial seeding 
if ($loghist[$_]){$n = $index - $loghist[$_]} 
 else {$n = $seed_depth} 
  
if ($n -lt 0){ 
 Write-Host "Log index changed since last run. The log may have been cleared. Re-seeding index." 
 $events_found = $true 
 $EmailBody += "`n Possible Log Reset $($_)`nEvent Index reset detected by Log Monitor`n" | ConvertTo-Html 
 $n = $seed_depth 
 } 
  
Write-Host "Processing $($n) events." 
 
#get the log entries 
 
if ($useinstanceid){ 
$log_hits = Get-EventLog -ComputerName $_ -LogName $log -Newest $n | 
? {$event_list[$_.source + "#" + $_.instanceid]} 
} 
 
else {$log_hits = Get-EventLog -ComputerName $_ -LogName $log -Newest $n | 
? {$event_list[$_.source + "#" + $_.eventid]} 
} 
 
#save the current index to $loghist for the next pass 
$loghist[$_] = $index 
 
#report number of alert events found and how long it took to do it 
if ($log_hits){ 
 $events_found = $true 
 $hits = $log_hits.count 
 $EmailBody += "`n Alert Events on server $($_)`n" 
 $log_hits |%{ 
  $emailbody += "<br><br>" 
  $emailbody += $_ | select MachineName,EventID,Message | ConvertTo-Html  
 $emailbody += "<br><br>" 
 } 
 } 
 else {$hits = 0} 
$duration = ($timer.elapsed).totalseconds 
write-host "Found $($hits) alert events in $($duration) seconds." 
"-"*60 
" " 
if ($ShowEvents){$log_hits | fl | Out-String |? {$_}} 
} 
 
#save the history file to disk for next script run  
$loghist | export-clixml $hist_file 
 
#Send email if there were any monitored events found 
if ($events_found -and -not $NoEmail){send_email} 
 
} 
#END OF RUN PASS 
 
Write-Host "`n$("*"*60)" 
Write-Host "Log monitor started at $(get-date)" 
Write-Host "$("*"*60)`n" 
 
#run the first pass 
$start_pass = Get-Date 
&$run_pass 
 
#if $run_interval is set, calculate how long to sleep before the next pass 
while ($run_interval -gt 0){ 
if ($run_interval -eq "C"){&$run_pass} 
 else{ 
 $last_run = (Get-Date) - $start_pass 
 $sleep_time = ([TimeSpan]::FromMinutes($run_interval) - $last_run).totalseconds 
 Write-Host "`n$("*"*10) Sleeping for $($sleep_time) seconds `n" 
  
#sleep, and then start the next pass 
 Start-Sleep -seconds $sleep_time 
 $start_pass = Get-Date  
 &$run_pass 
 } 
 }

###########################################END SCRIPT##################################
