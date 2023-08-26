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

testDNSBlock