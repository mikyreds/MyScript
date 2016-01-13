Param(
[Parameter(Mandatory=$true,Position=1)]
[string[]]$InputFile,

[switch]$newLogs
)


#define logs format version
[bool]$oldLogs = $true
if($newLogs){$oldLogs = $false}


if (!(Test-Path $InputFile))
{
Write-Host "File non trovato"
exit
}

$FoundRecords = 0
$FoundSpot = 0

$AsRunFile = $InputFile

$Date = Get-Date -UFormat "%Y%m%d%H%M%S"
$Date2 = Get-Date -UFormat "%H%M%S"
$Date3 = Get-Date -UFormat "%d%m%Y"

$AsRunFileOutput = ".\BikeChannel_ASRun_$Date3.txt"

while (Test-Path $AsRunFileOutput)
{
		$fileCounter++
		$AsRunFileOutput = ".\BikeChannel_ASRun_$Date3-$fileCounter.txt"
}

if($oldLogs)
{
	$header = "Time","Date","XXX","Title","YYY","Duration","ZZZ","ClockID"
	$records = import-csv -Delimiter "`t" -Header $header $AsRunFile
}
else
{
		$header = "Date","Time","Type","START","GUID","Title","XXX","ClockID","YYY","Duration","DurationSeconds","ZZZ"
		$records = import-csv -Header $header $AsRunFile
}

$righe = ($records).length

#WriteHeader
$myDate = $records[0].Date
$myNewDate = ($myDate)-replace "/",""
#$myNewDatdTrimmed = $myNewDate.remove(4,2)
$myNewDateDD = $myNewDate.substring(2,2)
$myNewDateMM = $myNewDate.substring(0,2)
$myNewDateYY = $myNewDate.substring(6,2)	
	
Add-Content $AsRunFileOutput $Date2'00SMSPOSTED 001 '
#Add-Content $Asfile $Date2'01BIKE'$myNewDatdTrimmed
Add-Content $AsRunFileOutput $Date2'01BIKE'$myNewDateDD$myNewDateMM$myNewDateYY

Write-Host ''

ForEach ($record in $records)
{
	
	if ($oldLogs -or ($record.START -eq "START"))
	{
		$FoundRecords++
		$clock = $record.ClockID
		$myTitle = $record.Title

		$myTime = $record.Time
	
		$myTime = $myTime -replace "^00:","24:"
		$myTime = $myTime -replace "^01:","25:"
		$myTime = $myTime -replace "^02:","26:"
		$myTime = $myTime -replace "^03:","27:"
		$myTime = $myTime -replace "^04:","28:"
		$myTime = $myTime -replace "^05:","29:"
	
	
		if($oldLogs)
		{
			$myDuration = $record.Duration
			$myMinutes = $myDuration.substring(3,2)
			$mySeconds = $myDuration.substring(6,2)
			
			#$myNewTS = [timespan]::Parse($myDuration)
			#$myDuration = $myNewTS.TotalSeconds
			
			$myDuration = ($mySeconds -as[int]) + (($myMinutes -as[int])*60)
			if($myDuration -ge 999) {$myDuration = 999}
			
			$myStringDuration = $myDuration -as[string]
			$myStringDuration = $myStringDuration.PadLeft(3,'0')
		}
		else
		{
				$myDuration = $record.DurationSeconds
		}
		
		if($clock)
		{
			$FoundSpot++
			$myNewTime = $myTime -replace ':',''
			$myNewTime = $myNewTime.Substring(0,6)
			
			$myClock = $clock -replace '-','/'
	
			Write-Host $myClock "Spot aired at" $myTime "with total secod duration of" $myStringDuration
			Add-Content $AsRunFileOutput $myNewTime'03    0000000000000'$myStringDuration$myClock
		}
	}
}


#Write footer
$StringFoundRecords = $FoundSpot.ToString("000000")
$myTempString = '99999998'
Add-Content $AsRunFileOutput $myTempString$StringFoundRecords

$FoundSpot = ($FoundSpot + 2)
$myTempString = '99999999'
$StringFoundRecords = $FoundSpot.ToString("000000")
Add-Content $AsRunFileOutput $myTempString$StringFoundRecords


#------------- Report -------------#
Write-Host ''
Write-Host 'AsRun file contains:' $righe 'rows'
Write-Host $FoundRecords 'usefull record found'
Write-Host ($FoundSpot - 2) 'spot record found'
Write-Host ''
Write-Host 'AsRun log created' $AsRunFileOutput

if($newLogs)
{
	Write-Host "Using New AsRun log Cinegy format (version 10.x)"
}
else
{
	Write-Host "Using Old AsRun log Cinegy format (version 9.x)"
}