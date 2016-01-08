Param(
[Parameter(Mandatory=$true,Position=1)]
[string[]]$InputFile,

[switch]$noFile
)

$filePhysicalPath1 = "C:\MyScript\"
$filePhysicalPath2 = "C:\MyScript2\"


#define if missing file should be created
[bool]$writeFile = $true
if($noFile){$writeFile = $false}




if (!(Test-Path $InputFile))
{
	Write-Host "File non trovato"
	exit
}

$FoundFiles = 0
$FilesInSecondPath = 0
$MissingFiles = 0
$fileCounter = 0

$Date = Get-Date -UFormat "%Y%m%d%H%M%S"
$Date2 = Get-Date -UFormat "%d%m%Y"

#$Pullfile = "C:\MXF\pull-list.csv"
$Pullfile = $InputFile

if($writeFile)
{
	$workingPath = Get-Location
	$Missingfile = $workingPath.ToString() + "\BikeChannel_missing_$Date2.csv"

	while (Test-Path $Missingfile)
	{
			$fileCounter++
			#$Missingfile = "C:\MyScript\BikeChannel_missing_$Date2-$fileCounter.csv"
			$Missingfile = $workingPath.ToString() + "\BikeChannel_missing_$Date2-$fileCounter.csv"
	}
	$writer = [system.io.file]::CreateText($Missingfile)
	$writer.NewLine = "`n"
}


$records = import-csv $Pullfile

$righe = ($records).length

ForEach ($record in $records)
{
	$Clock = $($record."Clock Number")
	$Name = $($record."Product Name")
	$txDate = $($record."Break Date")

	$trafficIDClock = ($Clock)-replace "/","-"
	
	$Videofile = "$filePhysicalPath1$trafficIDClock.*"
	$Videofile2 = "$filePhysicalPath2$trafficIDClock.*"
	#$FileExist = Test-Path $Videofile
	
	if (Test-Path $Videofile)
	{
		Write-Host $trafficIDClock "Found in" $filePhysicalPath1
		$FoundFiles++
	}
	elseif (Test-Path $Videofile2)
	{
		Write-Host $trafficIDClock "Found in" $filePhysicalPath2
		$FoundFiles++
		$FilesInSecondPath++
	}
	else
	{
  	$myTxDate = Get-Date $txDate -Format "dd/MM/yyyy"
  	#Write-Host $trafficIDClock","$Name","$myTxDate
  	Write-Host $trafficIDClock","$Name" is missing and will go on air" $myTxDate
  	$myString = "$Clock,$Name,$myTxDate"
		#Add-content $Missingfile $myString -nonewline
		$MissingFiles++

		if($writeFile)
		{
			$writer.WriteLine($myString)
		}
	}
}

if($writeFile) {$writer.Close()}

Write-Host
Write-Host
Write-Host "-------------------------------------"
Write-Host $righe "Records analyzed"
Write-Host "Found" $FoundFiles "files"
Write-Host $MissingFiles "files are missing!!!"
Write-Host $FilesInSecondPath "are in secondary path only!!!"
if ($MissingFiles -eq 0)
{
	Write-Host "ALL FILES ARE PRESENT!!!!"
	Write-Host "NO missing list file is created !!!"
}
else
{
	
	if($writeFile){Write-Host "Generated missing list file" $Missingfile}
	else {Write-Host "Missing list file NOT generated"}
}

Write-Host "-------------------------------------"