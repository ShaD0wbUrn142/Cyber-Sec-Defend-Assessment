$arg=$args[0]
if($arg){
	write-host $arg
}else{
	write-host "No args given"
}

function testDNSBlock {
    $nic = Get-NetAdapter | Where-Object { $_.Name -eq 'Ethernet 3' }
    if ($nic) {
        $dnsServer = Get-DnsClientServerAddress -InterfaceIndex $nic.InterfaceIndex | Select-Object -ExpandProperty ServerAddresses
        Write-Output "DNS Server of Ethernet 3 NIC: $dnsServer"
        $ipAddress = Resolve-DnsName -Name "malware.testcategory.com" | Select-Object -ExpandProperty IPAddress
        if ($ipAddress -ne '0.0.0.0') {
            Write-Output "The host is not using DNS filtering."	
        }
    } else {
        Write-Output "Ethernet 3 NIC not found."
    }
}

function enableDoH {
	Set-ItemProperty -Path "HKLM:SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" -Name "EnableAutoDoH" -Value "2"
	echo "rebooting in 5 seconds, press ctrl+c to cancel"
	Start-Sleep -Milliseconds 5000
	Restart-Computer
}

function setupQuadDoH {

}

function resetDoH {
	$networkInterface = Get-NetAdapter | Where-Object { $_.InterfaceAlias -eq 'Ethernet 3' }
	Set-DnsClientServerAddress -InterfaceIndex $adapterIndex -ServerAddresses "10.0.2.3"
}

switch ($arg) {
    "DoH-test" {
        # Call the testDNSBlock function
        testDNSBlock
    }
    "DoH-enable" {
        # Call the enableDoH function
        enableDoH
    }
    "setupQuadDoH" {
        # Call the setupQuadDoH function
        setupQuadDoH
    }
	"resetDoH" {
        # Call the resetDoH function
        resetDoH
    }
    default {
        Write-Output "Invalid argument provided. Use: DoH-test, DoH-enable, setupQuadDoH, resetDoH."
    }
}

#testDNSBlock
