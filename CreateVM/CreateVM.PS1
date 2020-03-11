# Create variables to store the location and resource group names.
$location = "EastUS"
$ResourceGroupName = "myResourceGroup"

New-AzureRmResourceGroup `
  -Name $ResourceGroupName `
  -Location $location

# Create variables to store the storage account name and the storage account SKU information
$StorageAccountName = "saforcreatevm"
$SkuName = "Standard_LRS"

# Create a new storage account
$StorageAccount = New-AzureRMStorageAccount `
  -Location $location `
  -ResourceGroupName $ResourceGroupName `
  -Type $SkuName `
  -Name $StorageAccountName

Set-AzureRmCurrentStorageAccount `
  -StorageAccountName $storageAccountName `
  -ResourceGroupName $resourceGroupName

# Create a subnet configuration
$subnetConfig = New-AzureRmVirtualNetworkSubnetConfig `
  -Name mysubnetforvm `
  -AddressPrefix 192.168.1.0/24

# Create a virtual network
$vnet = New-AzureRmVirtualNetwork `
  -ResourceGroupName $ResourceGroupName `
  -Location $location `
  -Name rgvnetvm `
  -AddressPrefix 192.168.0.0/16 `
  -Subnet $subnetConfig

# Create a public IP address and specify a DNS name
$pip = New-AzureRmPublicIpAddress `
  -ResourceGroupName $ResourceGroupName `
  -Location $location `
  -AllocationMethod Static `
  -IdleTimeoutInMinutes 4 `
  -Name "mypublicdns$(Get-Random)"

# Create an inbound network security group rule for port 3389
$nsgRuleRDP = New-AzureRmNetworkSecurityRuleConfig `
  -Name myNetworkSecurityGroupRuleRDP `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 1000 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 3389 `
  -Access Allow

# Create an inbound network security group rule for port 80
$nsgRuleWeb = New-AzureRmNetworkSecurityRuleConfig `
  -Name myNetworkSecurityGroupRuleWWW `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 1001 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 80 `
  -Access Allow

# Create a network security group
$nsg = New-AzureRmNetworkSecurityGroup `
  -ResourceGroupName $ResourceGroupName `
  -Location $location `
  -Name myNetworkSecurityGroup `
  -SecurityRules $nsgRuleRDP,$nsgRuleWeb

# Create a virtual network card and associate it with public IP address and NSG
$nic = New-AzureRmNetworkInterface `
  -Name myNic `
  -ResourceGroupName $ResourceGroupName `
  -Location $location `
  -SubnetId $vnet.Subnets[0].Id `
  -PublicIpAddressId $pip.Id `
  -NetworkSecurityGroupId $nsg.Id

# Define a credential object to store the username and password for the VM
$UserName='demouser'
$Password='Password@123'| ConvertTo-SecureString -Force -AsPlainText
$Credential=New-Object PSCredential($UserName,$Password)

# Create the VM configuration object
$VmName = "VMWinlatest"
$VmSize = "Standard_A1"
$VirtualMachine = New-AzureRmVMConfig `
  -VMName $VmName `
  -VMSize $VmSize

$VirtualMachine = Set-AzureRmVMOperatingSystem `
  -VM $VirtualMachine `
  -Windows `
  -ComputerName "MainComputer" `
  -Credential $Credential -ProvisionVMAgent

$VirtualMachine = Set-AzureRmVMSourceImage `
  -VM $VirtualMachine `
  -PublisherName "MicrosoftWindowsServer" `
  -Offer "WindowsServer" `
  -Skus "2016-Datacenter" `
  -Version "latest"

# Sets the operating system disk properties on a VM.
$VirtualMachine = Set-AzureRmVMOSDisk `
  -VM $VirtualMachine `
  -CreateOption FromImage | `
  Set-AzureRmVMBootDiagnostics -ResourceGroupName $ResourceGroupName `
  -StorageAccountName $StorageAccountName -Enable |`
  Add-AzureRmVMNetworkInterface -Id $nic.Id


# Create the VM.
New-AzureRmVM `
  -ResourceGroupName $ResourceGroupName `
  -Location $location `
  -VM $VirtualMachine

  Get-AzureRmPublicIpAddress `
  -ResourceGroupName $ResourceGroupName | Select IpAddress

$lbPip = New-AzPublicIpAddress -Name "LB-IP" `
  -ResourceGroupName $ResourceGroupName `
  -Location $location `
  -AllocationMethod "Static"

  $frontendIp = New-AzLoadBalancerFrontendIpConfig -Name "FIP-LB" `
  -PublicIpAddressId $lbPip
$probe = New-AzLoadBalancerProbeConfig -Name "Probe-443" `
  -Protocol Tcp `
  -Port 443 `
  -IntervalInSeconds 20 `
  -ProbeCount 2
$lbrule = New-AzLoadBalancerRuleConfig -Name "Rule-LB" `
  -Protocol Tcp `
  -FrontendPort 443 `
  -FrontendIpConfiguration $frontendIp `
  -BackendPort 443 `
  -BackendAddressPool $pip `
  -Probe $probe

  New-AzLoadBalancer -Name "LB-AzIP" `
                   -ResourceGroupName $resourceGroupName `
                   -Location $location `
                   -FrontendIpConfiguration $frontendIp `
                   -BackendAddressPool $pip `
                   -LoadBalancingRule $lbrule `
                   -Probe $probe


  
  

  mstsc /v:publicIpAddress

  Install-WindowsFeature -name Web-Server -IncludeManagementTools
  # Enable .NET 4.5
# Install ASP.NET
Install-WindowsFeature NET-Framework-45-ASPNET; 
Install-WindowsFeature Web-Asp-Net45
# Remove Default web site and creat new site and assign
Remove-WebSite -Name 'Default Web Site'
md c:/website
New-Website -Name 'nerddinner' -Port 80 -PhysicalPath 'c:\website' -ApplicationPool 'DefaultAppPool'
Import-Module WebAdministration
Set-ItemProperty 'IIS:\AppPools\DefaultAppPool' -Name 'processModel.loadUserProfile' -Value 'True'
Set-ItemProperty 'IIS:\AppPools\DefaultAppPool' -Name 'processModel.setProfileEnvironment' -Value 'True'
Set-ItemProperty 'IIS:\AppPools\DefaultAppPool' -Name 'processModel.identityType' -Value 0

