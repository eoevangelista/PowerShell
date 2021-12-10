# Function that executes remote backup in SQL Server instances. 

Function GetStatusCode
{ 
	Param([int] $StatusCode)  
	switch($StatusCode)
	{
		0 		{"Success"}
		11001   {"Buffer Too Small"}
		11002   {"Destination Net Unreachable"}
		11003   {"Destination Host Unreachable"}
		11004   {"Destination Protocol Unreachable"}
		11005   {"Destination Port Unreachable"}
		11006   {"No Resources"}
		11007   {"Bad Option"}
		11008   {"Hardware Error"}
		11009   {"Packet Too Big"}
		11010   {"Request Timed Out"}
		11011   {"Bad Request"}
		11012   {"Bad Route"}
		11013   {"TimeToLive Expired Transit"}
		11014   {"TimeToLive Expired Reassembly"}
		11015   {"Parameter Problem"}
		11016   {"Source Quench"}
		11017   {"Option Too Big"}
		11018   {"Bad Destination"}
		11032   {"Negotiating IPSEC"}
		11050   {"General Failure"}
		default {"Failed"}
	}
}

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO")| out-null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended")| out-null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Management.Smo.Server")| out-null

$OutputFile = "C:\Scripts\Output.htm"
$ServerList = Get-Content "C:\Scripts\ServerList.txt"


$dt = get-date -format yyyyMMdd
$Result = @()
Foreach($ServerName in $ServerList)
{
	$pingStatus = Get-WmiObject -Query "Select * from win32_PingStatus where Address='$ServerName'"
	
	if($pingStatus.StatusCode -eq 0)
		{
		
			 $date = Invoke-Sqlcmd -Query "select top 1 1 from msdb.dbo.backupset where database_name='DATABASE' and type='D' and dateadd(dd,-7,getdate())<backup_finish_date order by backup_finish_date desc;" -serverinstance $ServerName -Database msdb;  
			
			if (!$date)
				{
					$file = '\\' + $ServerName + '\C$\DATABASE_backup_'+$dt+'.bak'
					
					$command = 'BACKUP DATABASE [DATABASE] TO  DISK = N'''+$file+''' WITH NOFORMAT, INIT, SKIP, NOREWIND, NOUNLOAD,  STATS = 10'
					Invoke-Sqlcmd -Query $command -serverinstance $ServerName -Database DATABASE -querytimeout 0;  
					Invoke-Command -ComputerName $ServerName  -FilePath c:\scripts\action.ps1 -argumentlist $ServerName, $dt			
				}

		}
	
    $Result += New-Object PSObject -Property @{
	  ServerName = $ServerName
		IPV4Address = $pingStatus.IPV4Address
		Status = GetStatusCode( $pingStatus.StatusCode )
 
	}

}

$jobs = Foreach($ServerName in $ServerList) 
{
    #Write-Host "Starting copy job for $serverName"
    Start-Job -Name "$ServerName" -ArgumentList $ServerName -ScriptBlock {
      param($ServerName)

      if (Test-Connection -ComputerName $ServerName -Count 1 -Quiet)
      {
		$fileZip = ' DATABASE_backup_*.zip'
		$source = '"\\' + $ServerName + '\C$\\"'
		$destination = '\\STORAGE\SQLServer\' + $ServerName +'\\'
		$parameter = ' /R:0 /mov'
		$command2 =  'robocopy '+ $source + $destination  + $fileZip + $parameter
		Invoke-Expression $command2 
      }
   }
   
   
   
}

#$jobs | Receive-Job

if($Result -ne $null)
{
	$HTML = '<style type="text/css">
	#Header{font-family:"Trebuchet MS", Arial, Helvetica, sans-serif;width:100%;border-collapse:collapse;}
	#Header td, #Header th {font-size:14px;border:1px solid #98bf21;padding:3px 7px 2px 7px;}
	#Header th {font-size:14px;text-align:left;padding-top:5px;padding-bottom:4px;background-color:#A7C942;color:#fff;}
	#Header tr.alt td {color:#000;background-color:#EAF2D3;}
	</Style>'

    $HTML += "<HTML><BODY><Table border=1 cellpadding=0 cellspacing=0 id=Header>
		<TR>
			<TH><B>Servidor</B></TH>
			<TH><B>EderecoIP</B></TD>
			<TH><B>Status</B></TH>
		</TR>"
    Foreach($Entry in $Result)
    {
        if($Entry.Status -ne "Ativo")
		{
			$HTML += "<TR bgColor=white>"
		}
		else
		{
			$HTML += "<TR>"
		}
		$HTML += "
						<TD>$($Entry.ServerName)</TD>
						<TD>$($Entry.IPV4Address)</TD>
						<TD>$($Entry.Status)</TD>
					</TR>"
    }
    $HTML += "</Table></BODY></HTML>"
	$HTML | Out-File $OutputFile
}

$jobs | Wait-Job
