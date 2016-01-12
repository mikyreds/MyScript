Param(
[Parameter(Mandatory=$true,Position=1)]
[string[]]$InputFile,

[switch]$realDelete
)



if (!(Test-Path $InputFile))
{
	Write-Host "File non trovato"
	exit
}

$filePhysicalPath1 = "C:\MyScript\"
$filePhysicalPath2 = "C:\MyScript2\"



$FoundSpot = 0
$wipeFile = $InputFile

$Date3 = Get-Date -UFormat "%d%m%Y"

$wipeFileOutput = ".\BikeChannel_WipeList_$Date3.txt"

while (Test-Path $wipeFileOutput)
{
		$fileCounter++
		$wipeFileOutput = ".\BikeChannel_WipeList_$Date3-$fileCounter.txt"
}

#$header = "Advertiser","Product","Duration","IndustryCode","HouseNumber","CopyDubbed","ApprovedStatus","ReceivedDate","Approver","StartDate","EndDate","LastUsed","CopyCode"
$records = import-csv $wipeFile -Delimiter ";"
$righe = ($records).length



ForEach ($record in $records)
{
	$Clock = $($record."Industry Code")
	$trafficIDClock = ($Clock)-replace "/","-"
	
	$Videofile = "$filePhysicalPath1$trafficIDClock.mxf"
	$Videofile2 = "$filePhysicalPath2$trafficIDClock.mxf"
	
	if (Test-Path $Videofile)
	{
		if ($realDelete) { Remove-Item -path $Videofile }
		else { Rename-Item -path $Videofile -newname "$filePhysicalPath1$trafficIDClock.todelete"}
		$FoundSpot++
		Add-Content $wipeFileOutput $Videofile' has been removed/renamed'
	}
	elseif (Test-Path $Videofile2)
	{	
		if ($realDelete) { Remove-Item -path $Videofile2 }
		else { Rename-Item -path $Videofile2 -newname "$filePhysicalPath2$trafficIDClock.todelete"}
		$FoundSpot++
		Add-Content $wipeFileOutput "$Videofile2 has been removed/renamed"
	}
	else
	{
		#Write-Host $trafficIDClock $record.Product "not present in our system"
	}
}

Write-Host
Write-Host
Write-Host "-------------------------------------"
Write-Host ""
Write-Host $righe "records found in wipe file"
Write-Host ""
Write-Host "Found" $FoundSpot "files"

if($FoundSpot)
{
	Write-Host "File" $wipeFileOutput "has been created"

	Add-Content $wipeFileOutput ""
	Add-Content $wipeFileOutput "-------------------------------------"
	Add-Content $wipeFileOutput "$righe records found in wipe file"
	Add-Content $wipeFileOutput "Found $FoundSpot files"
}
else
{
	Write-Host "No file has been created"
}