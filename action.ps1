	Param(
			[string] $ServerName,
			[string] $dt 
			)  
		
		$srcdir = '\\' + $ServerName + '\C$\DATABASE_backup_' + $dt  + '.bak' 
		$zipFilename = 'DATABASE_backup_' + $dt  + '.zip' 
		$zipFilepath = '\\'+ $ServerName + '\C$\'
		$zipFile = "$zipFilepath$zipFilename"

		#Prepare zip file
		if(-not (test-path($zipFile))) {
			set-content $zipFile ("PK" + [char]5 + [char]6 + ("$([char]0)" * 18))
			(dir $zipFile).IsReadOnly = $false  
		}

		$shellApplication = new-object -com shell.application
		$zipPackage = $shellApplication.NameSpace($zipFile)
		$files = Get-ChildItem -Path $srcdir | where{! $_.PSIsContainer}

		foreach($file in $files) { 
			$zipPackage.CopyHere($file.FullName)
			while($zipPackage.Items().Item($file.name) -eq $null){
				Start-sleep -seconds 1
			}
		}
		
		If (Test-Path $zipFile)
			{
				Remove-Item $srcdir
			}			
