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
	Set-DnsClientServerAddress -InterfaceAlias "Ethernet 3" -ServerAddresses ("1.1.1.2")
	Add-DnsClientDohServerAddress 1.1.1.2 `https://security.cloudflare-dns.com/dns-query ` -AutoUpgrade $True
	$guid = (Get-NetAdapter -Name "Ethernet 3").InterfaceGuid
	New-Item -Path "HKLM:\System\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\${guid}\DohInterfaceSettings\Doh\1.1.1.2" -Force
	Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\${guid}\DohInterfaceSettings\Doh\1.1.1.2" -Name "DohFlags" -Value "1" -Force
}

function resetDoH {
	Set-DnsClientServerAddress -InterfaceAlias "Ethernet 3" -ServerAddresses ("10.0.2.3")
	Remove-DnsClientDohServerAddress 1.1.1.2
	$guid = (Get-NetAdapter -Name "Ethernet 3").InterfaceGuid
	Remove-Item -Path "HKLM:\System\CurrentControlSet\Services\Dnscache\InterfaceSpecificParameters\${guid}" -Force
	Remove-ItemProperty -Path "HKLM:SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" -Name "EnableAutoDoH"
}

function enableHTTPBlock {
	if(Get-NetFirewallRule -DisplayName HTTP-Outbound){
		Set-NetFirewallRule -DisplayName 'HTTP-Outbound' -Direction Outbound -Action Block -Protocol TCP -RemotePort 80
	}else{
		New-NetFirewallRule -DisplayName 'HTTP-Outbound' -Direction Outbound -Action Block -Protocol TCP -RemotePort 80
	}
}

function disableHTTPBlock {
	Set-NetFirewallRule -DisplayName 'HTTP-Outbound' -Direction Outbound -Action Allow -Protocol TCP -RemotePort 80
}

function testHTTPBlock {
	Test-NetConnection -ComputerName "www.google.com" -InformationLevel "Detailed" -Port 80
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
	"blockHTTP" {
        # Call the enableHTTPBlock function
        enableHTTPBlock
    }
	"resetHTTP" {
        # Call the disableHTTPBlock function
        disableHTTPBlock
    }"testHTTP" {
        # Call the testHTTPBlock function
        testHTTPBlock
    }
    default {
        Write-Output "Invalid argument provided. Use: DoH-test, DoH-enable, setupQuadDoH, resetDoH, blockHTTP, resetHTTP, testHTTP."
    }
}

#testDNSBlock
