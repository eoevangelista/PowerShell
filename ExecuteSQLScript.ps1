<# 
This script executes the "test.sql" with SQL commands in Oracle databases, using a list (BANCOS.TXT) in txt file, converted to an array, and iterate through an array of values.
It also generates a log (spool.log) about the start date,  SQLs output, and the end date. 
#>

# Password Required
$pwd = Read-Host -Prompt 'Senha do SYS' -AsSecureString

# Test if password was write
If ($pwd.Length -eq 0){
   Write-Host "Senha nula, saindo do script." -ForegroundColor Cyan -BackgroundColor Black
   Continue;
} 
 
# Get the start date and time of the process.
$StartDate = Get-Date  

Write-Output "Início: $StartDate" > .\spool.log

# It reads BANCOS.TXT and "feeds" the $arrayFromFile with the values.
[string[]]$arrayFromFile = Get-Content -Path .\BANCOS.TXT

# Struct the command for execution in a loop.
$commando =  $arrayFromFile | ForEach-Object {"echo '@test.sql' |SQLPLUS sys/$pwd@$PSItem as sysdba"}
 
# Iterates through each value in the array.
For ($i = 0; $i -lt $commando.count) {
    echo $arrayFromFile[$i]  >> .\spool.log     
    Invoke-Expression $commando[$i]  >> .\spool.log    
	[Environment]::NewLine >> .\spool.log   
    $i++
} 

# Get the final date and time of the process.
$EndDate = Get-Date 
Write-Output "Início: $EndDate" > .\spool.log
