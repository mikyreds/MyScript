Param(
[Parameter(Mandatory=$true,Position=1)]
[string[]]$InputFile,

[switch]$newLogs,
[switch]$barbFile
)


#define logs format version
[bool]$oldLogs = $true
if($newLogs){$oldLogs = $false}


if (!(Test-Path $InputFile))
{
Write-Host "File non trovato"
exit
}



$promoCodes = "^Ident|^Promo|^Billboard|^Spot|^Coming up|^Tra poco|^Jingle|^Bumper|^Tonight|^Continuity|^Album|^Rapha|^Pillole"


$errorClocks = @()
$FoundRecords = 0
$FoundSpot = 0


#BARB Variables
$barbStationCode = "05183"
$barbCompany = "Bike      "
$barbRecords = 0
$barbSpan = "0"

$AsRunFile = $InputFile

$Date = Get-Date -UFormat "%Y%m%d%H%M%S"
$Date2 = Get-Date -UFormat "%H%M%S"
$Date3 = Get-Date -UFormat "%d%m%Y"
$Date4 = Get-Date -UFormat  "%Y%m%d"



$AsRunFileOutput = ".\BikeChannel_ASRun_$Date3.txt"


while (Test-Path $AsRunFileOutput)
{
		$fileCounter++
		$AsRunFileOutput = ".\BikeChannel_ASRun_$Date3-$fileCounter.txt"
}

#
#while (Test-Path $barbFileOutput)
#{
#		$fileCounter++
#		$barbFileOutput = ".\$barbStationCode$Date4-$fileCounter.prg"
#}

if($oldLogs)
{
	$header = "Time","Date","XXX","Title","YYY","Duration","Variance","ClockID"
	$records = import-csv -Delimiter "`t" -Header $header $AsRunFile
}
else
{
		$header = "Date","Time","Type","START","GUID","Title","XXX","ClockID","YYY","Duration","DurationSeconds","ZZZ"
		$records = import-csv -Header $header $AsRunFile | Where-Object {$_.Type -eq "VIDEO"}
}

$righe = ($records).length

#WriteHeader
$myDate = $records[0].Date
#date is 01/12/2016 now

$myNewDate = ($myDate)-replace "/",""

#$myNewDatdTrimmed = $myNewDate.remove(4,2)
$myNewDateDD = $myNewDate.substring(2,2)
$myNewDateMM = $myNewDate.substring(0,2)
$myNewDateYY = $myNewDate.substring(6,2)	
$myNewDateYYYY = $myNewDate.substring(4,4)

$barbDate = "$myNewDateYYYY$myNewDateMM$myNewDateDD"

#Write Sky Asrun format	header
Add-Content $AsRunFileOutput $Date2'00SMSPOSTED 001 '
#Add-Content $Asfile $Date2'01BIKE'$myNewDatdTrimmed
Add-Content $AsRunFileOutput $Date2'01BIKE'$myNewDateDD$myNewDateMM$myNewDateYY

#Write BARB Asrun format	header
if ($barbFile)
{
	
	$workingPath = Get-Location
	$barbFileName = "\$barbStationCode$barbDate.prg"
	$barbFileOutput = $workingPath.ToString() + $barbFileName
	#$barbFileOutput = ".\$barbStationCode$barbDate.prg"
	
	if (Test-Path $barbFileOutput)
	{
		Remove-Item $barbFileOutput
	}
	
	$writer = [system.io.file]::CreateText($barbFileOutput)
	$writer.NewLine = "`n"
	
#	Write-Host $barbFileName
	#$stringFile = $barbFileName.ToString()
	$stringFile2 =  $barbFileName.substring(1,17)
		
	$barbHeader = "01Transmissn$barbCompany" + "0500$barbDate$Date4$Date2" + "$stringFile2" + "V03.09"
	$barbHeader = $barbHeader.PadRight(500,' ')
	
	$writer.WriteLine($barbHeader)
	#Add-Content $barbFileOutput $barbHeader
	
}


Write-Host ''



#ForEach ($record in $records)
for ($i=0 ; $i -lt $righe ; $i++)
{
	
	if ($oldLogs -or ($records[$i].START -eq "START"))
	{
		$FoundRecords++
		$clock = $records[$i].ClockID
		$myTitle = $records[$i].Title

		$myTime = $records[$i].Time
		
		$myTime = $myTime.Substring(0,8)
		if($clock) {$myClock = $clock -replace '-','/'}
					
		if($oldLogs)#calculate durations on OLD logs
		{
			if ($records[$i].Variance)#check if there was some problem with on-air
			{
				$myDuration = $records[$i].Variance
				if($clock) {$errorClocks += $myClock}
			}else
			{
				$myDuration = $records[$i].Duration
			}
			
			
			
			$myMinutes = $myDuration.substring(3,2)
			$mySeconds = $myDuration.substring(6,2)
			
			#$myNewTS = [timespan]::Parse($myDuration)
			#$myDuration = $myNewTS.TotalSeconds
			
			$myDuration2 = ($mySeconds -as[int]) + (($myMinutes -as[int])*60)
			#if($myDuration -ge 999) {$myDuration = 999}
			
			$myStringDuration = $myDuration2 -as[string]
			$myStringDuration = $myStringDuration.PadLeft(3,'0')
		}
		else #calculate durations on NEW logs
		{
				$myDuration = $records[$i].DurationSeconds
				
				if(($records[$i + 1].START -eq "STOP") -and ($records[$i + 1].DurationSeconds -ne $myDuration))
				{
					if($clock) {$errorClocks += $myClock}
					$myDuration = $records[$i + 1].DurationSeconds
				}
				
				$myStringDuration = $myDuration # -as[string]
				$myStringDuration = $myStringDuration -replace ".{3}$"	
				$myStringDuration = $myStringDuration.PadLeft(3,'0')
		}
		

		
		#calculate endtime
		if ($oldLogs) #oldlog case
		{
			if($i -eq ($righe - 1)) #calculate endtime summing duration to start time 
			{
				$temp = [datetime]$myTime
				$endTime = $temp.AddSeconds($myDuration2)
				$endTimeString = $endTime.ToString()
				$endTimeString = $endTimeString.Substring(11,8)
			}
			else #calculate endtime looking starttime of following line
			{
				$endTime = $records[$i + 1].Time
				$endTimeString = $EndTime.Substring(0,8)
			}	
		}
		else #newlog case
		{
			if($i -eq ($righe - 1))
			{
				$temp = [datetime]$myTime
				$endTime = $temp.AddSeconds($myDuration2)
				$endTimeString = $endTime.ToString()
				$endTimeString = $endTimeString.Substring(11,8)
			}
			else #not at end of file
			{
				if($records[$i + 1].START -eq "STOP") #check if following line is a stop
				{
					$endTimeString = $records[$i + 1].Time
					$endTimeString = $endTimeString.Substring(0,8)
				}
				else
				{
					$temp = [datetime]$myTime
					$endTime = $temp.AddSeconds($myDuration2)
					$endTimeString = $endTime.ToString()
					$endTimeString = $endTimeString.Substring(11,8)
				}
			}	
		}
		
		$myTime = $myTime -replace "^00:","24:"
		$myTime = $myTime -replace "^01:","25:"
		$myTime = $myTime -replace "^02:","26:"
		$myTime = $myTime -replace "^03:","27:"
		$myTime = $myTime -replace "^04:","28:"
		$myTime = $myTime -replace "^05:","29:"
		
		$endTimeString = $endTimeString -replace "^00:","24:"
		$endTimeString = $endTimeString -replace "^01:","25:"
		$endTimeString = $endTimeString -replace "^02:","26:"
		$endTimeString = $endTimeString -replace "^03:","27:"
		$endTimeString = $endTimeString -replace "^04:","28:"
		$endTimeString = $endTimeString -replace "^05:","29:"
		
		$myNewTime = $myTime -replace ':',''
		$newEndTime = $endTimeString -replace ':',''
		
		if($clock)
		{
			$FoundSpot++	
			
			Write-Host $myClock "Spot aired at" $myTime "with total secod duration of" $myStringDuration
			Add-Content $AsRunFileOutput $myNewTime'03    0000000000000'$myStringDuration$myClock
		}
		elseif($barbFile)#if not a clockID see if it's suitable for BARB logging
		{
			#if Barb file has to be created then check if the title is a promo code or not
			if($myTitle -notmatch $promoCodes)
			{
				#check if the day span
				if (($myNewTime -match "^28|^29") -and ($newEndTime -match "^05|^06"))
				{
					$barbSpan = "1"
					$newEndTime = "295959"
				}
				else {$barbSpan = "0"}
				$barbRecords++
				if($myTitle.Lenght -gt 40){$myTitle = $myTitle.Substring(0,40)} #trim titles longer than 40 char
					

					
				$myPad = ""
				$myPad = $myPad.PadRight(84,' ')
				$barbLine = "02$barbDate"+ "$barbStationCode" + "0000000000" + "$myNewTime" + "$newEndTime" + "$barbSpan" + "               " + "PG" + "$myPad" + "$myTitle"
				$barbLine = $barbLine.PadRight(500,' ')
				$writer.WriteLine($barbLine)
				#Add-Content $barbFileOutput $barbLine
			}
			
		}
	}
}


#Write footer
$FoundSpot = ($FoundSpot + 2) #include header
$StringFoundRecords = $FoundSpot.ToString("000000")
$myTempString = '99999998'
Add-Content $AsRunFileOutput $myTempString$StringFoundRecords

$FoundSpot = ($FoundSpot + 2) #include footer
$myTempString = '99999999'
$StringFoundRecords = $FoundSpot.ToString("000000")
Add-Content $AsRunFileOutput $myTempString$StringFoundRecords

#Write barb footer
if($barbFile)
{
	$myPad = ""
	$myPad = $myPad.PadRight(491,' ')
	$barbRecords++ #to include the header
	$barbRecordsString = $barbRecords.ToString()
	$barbRecordsString = $barbRecordsString.PadLeft(7," ")
	$barbLine = "99" + "$barbRecordsString" + "$myPad"
	$writer.WriteLine($barbLine)
	#Add-Content $barbFileOutput $barbLine
}
#------------- Report -------------#
Write-Host ''
Write-Host 'AsRun file contains:' $righe 'rows'
Write-Host $FoundRecords 'usefull record found'
Write-Host ($FoundSpot - 4) 'spot record found'
Write-Host ''
Write-Host 'AsRun log created' $AsRunFileOutput

if($barbFile)
{
	$writer.Close()
	Write-Host ''
	Write-Host ($barbRecords -1) 'usefull BARB record found'
	Write-Host 'BARB log created' $barbFileOutput
	Write-Host ''

#(Get-Content  $barbFileOutput) | ForEach-Object { $_ -replace "\u000D","" } >  $barbFileOutput
}



if($errorClocks)
{
	Write-Host ""
	Write-Host "Following clocks have variance errors"
	Write-Host $errorClocks
	Write-Host ""
}

if($newLogs)
{
	Write-Host "Using New AsRun log Cinegy format (version 10.x)"
}
else
{
	Write-Host "Using Old AsRun log Cinegy format (version 9.x)"
}