[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 1200743406|Bags

$ticketAvailabilityScrapperLogFile = '.\TicketAvailabilityScrapper.log'
$lastKnownAvailibilityFile = '.\LastKnownAvailability.txt'
$botTokenFile = '.\TelegramBotToken.txt'
$chatIDsFile = '.\chatIDs.txt'
$scrapeSiteURL = 'https://tabletop.events/conventions/dragonsteel-2024/badgetypes/general-admission-badge6'

function Write-My-Log
{
    param
    (
        [string]$NewLogLine
    )

    $timestamp = Get-Date -UFormat "%d/%m/%Y %R"
    # Add-Content -Path $ticketAvailabilityScrapperLogFile -Value "$timestamp :: :: :: $LogLine"
    Write-Output "$timestamp :: :: :: $($NewLogLine)"
}

Write-My-Log "Making call to $scrapeSiteURL"
$HTML = Invoke-WebRequest -Uri $scrapeSiteURL
$result = $HTML.ParsedHtml.getElementsByTagName("div") | Where-Object {$_.textContent.StartsWith("Availability:")} | Select-Object -Property textContent

$oldResult = Get-Content -Path $lastKnownAvailibilityFile

if($oldResult -eq $result.textContent)
{
    Write-My-Log "No change in availability since the last check"
    Return
}

Write-My-Log "Availability changed since the last check"
Write-My-Log "$($result.textContent)"

$result.textContent | Out-File $lastKnownAvailibilityFile

$botToken = Get-Content -Path $botTokenFile

foreach($IDNamePair in Get-Content -Path $chatIDsFile)
{
    $IDNamePairArray = $IDNamePair.Split('|')
    Write-My-Log "Sending message to user [$($IDNamePairArray[1])]"
    $messageText = "Pssst. Hey $($IDNamePairArray[1]).%0AJust wanted to let you know that the ticket availability just changed.%0A%0A$($result.textContent)%0A%0AHere's the link:$($scrapeSiteURL)";
    $url = "https://api.telegram.org/bot$botToken/sendMessage?chat_id=$($IDNamePairArray[0])&text=$messageText"
    Invoke-RestMethod -Uri $url -Method Post
}

# $chatID = "6657933554" 
# $messageText = "Hello.%0AJust wanted to let you know that the ticket availability just changed.%0A$($result.textContent)%0A%0AHere's the link:$($scrapeSiteURL)";


# $url = "https://api.telegram.org/bot$botToken/sendMessage?chat_id=$chatID&text=$messageText"

 