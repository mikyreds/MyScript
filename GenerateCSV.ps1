Param([string[]]$InputFile)

if (!(Test-Path $InputFile))
{
	Write-Host "File non trovato"
	exit
}

$Date = Get-Date -UFormat "%Y%m%d%H%M%S"

$FoundRecords = 0

$SpotFile = $InputFile
$CSVfile = ".\CSV_Playlist_$Date.csv"

$lines = Get-Content $SpotFile

$myStartTime = [datetime]"00:00:00"

foreach($line in $lines)
{

	
	if($line -match "3BIKE1*")
	{
		$FoundRecords++
		
		$myHH = $line.substring(12,2)
		$mymm = $line.substring(14,2)
		$mySS = $line.substring(16,2)
		$myTime = $line.substring(12,6)
		
		$mySpotID = $line.substring(130,15)
		$myLenght = $line.substring(103,3)
		$myTitle = $line.substring(68,35)
		$myTitle = $myTitle.Trim()
		
		$SpotDate = $line.substring(6,6)
		
		if($myHH -eq '24') {$myHH = '00'}
		if($myHH -eq '25') {$myHH = '01'}
		if($myHH -eq '26') {$myHH = '02'}
		if($myHH -eq '27') {$myHH = '03'}
		if($myHH -eq '28') {$myHH = '04'}
		if($myHH -eq '29') {$myHH = '05'}
		
		#$myTime = [datetime]($myHH':'$mymm':'$mySS)
		$myTime = $myTime -replace "^24", "00" 
		$myTime = $myTime -replace "^25", "01"
		$myTime = $myTime -replace "^26", "02"
		$myTime = $myTime -replace "^27", "03"
		$myTime = $myTime -replace "^28", "04"
		$myTime = $myTime -replace "^29", "05"
		
		$myTime = $myTime.Insert(2,':')
		$myTime = $myTime.Insert(5,':')
		
		$trafficIDClock = ($mySpotID)-replace "/","-"
		
		#calculate lenght form seconds
		$ts = [timespan]::fromseconds($myLenght)
		$ts_string = $ts.ToString("hh\:mm\:ss")
		
		
		#Add-Content $CSVfile $myHH';'$myMM';'$mySS';00,00;00;'$myLenght';00,C,'$trafficIDClock','$myTitle
		
		if([System.Math]::Abs($([datetime]$myTime - [datetime]$myStartTime).TotalSeconds) -gt 120)
		{
			Add-Content $CSVfile $myTime';00,'$ts_string';00,C,'$trafficIDClock','$myTitle		
		}
		else
		{
			Add-Content $CSVfile $myTime';00,'$ts_string';00,,'$trafficIDClock','$myTitle
		}
		
		#Add-Content $CSVfile $myTime';00,'$ts_string';00,C,'$trafficIDClock','$myTitle
		#Add-Content $CSVfile $myHH';'$myMM';'$mySS';00,'$ts_string';00,C,'$trafficIDClock','$myTitle
		#Write-Host $myHH';'$myMM';'$mySS';00,00;00;'$myLenght';00,,'$trafficIDClock','$myTitle
		$myStartTime = $myTime
	}
}

Write-Host
Write-Host
Write-Host "-------------------------------------"
Write-Host $FoundRecords "Records analyzed"
Write-Host "Generated CSV play-list file" $CSVfile
Write-Host "-------------------------------------"