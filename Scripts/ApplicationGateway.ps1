#Variable declaration
$location = "eastus2" #Target Location for Application Gateway and other resources
$resourceGroupName = "rg-east-Prod-IAUCDR" #Target Resource group name for application gateway
$TargetAppGatewayName = "appgw-iauc-emco-dev-eastus-01"
$virtualNetwork = "vnet-east-IAUCDR" #Virtual Network Name used for application gateway
$subnetName = "subnet-vms" #Subnet name for application gateway IP Configuration and private IP Configuration
$gatewayIPConfigurationName = "TestGatewayIPConfiguration" #Gateway IP Configuration Name
$publicIPAddressName = "TestPublicIPAddress" #Public IP Address Name for application gateway
$publicFrontEndIPConfigName = "TestPublicIPAddressConfiguration" #Public IP Front End configuration Name for application gateway
$privateFrontEndIPConfigName = "TestPrivateIPAddressConfiguration" #Private IP Front End configuration Name for application gateway
$privateIPAddress = "10.2.1.25" #Private IP Address front End application gateway
$frontEndPortName = "TestFrontEndPort" #Prefix for Front End Port Name

#Collections for Application Gateway
$GatewayFrontEndIPConfigurations = @();
$frontEndPorts = @();
$HttpListenerCollection = @();
$HealthProbeCollection = @();
$BackendAddressPoolCollection = @();
$HttpSettingCollection = @();
$RoutingRuleCollection = @();
$FrontEndPortCollection = @(80,81);

#Login to Azure Account Using Service Principal
$TenantId = "b7f604a0-00a9-4188-9248-42f3a5aac2e9" #Tenant Id of Azure Portal
$ApplicationId = "6976ba2d-f77b-46bf-9ca9-05f24d34a0f1" #Client ID of Service Principal
$Secret = "v-PZuWu9~.y8x8gM7JDDbJc~AMKs11fI.d" #Secret Id of Service Principal used as password

$AzCredential = New-Object -TypeName System.Management.Automation.PSCredential($ApplicationId, (ConvertTo-SecureString $Secret –ASPlainText –Force))

Connect-AzAccount -ServicePrincipal -Credential $AzCredential -Tenant $TenantId

Write-Host "Process Started at: "
Get-Date -Format "dddd MM/dd/yyyy HH:mm K"

#Select SKU for V2
#Name values: Standard_Small, Standard_Medium, Standard_Large, WAF_Medium, WAF_Large, Standard_v2, WAF_v2
#Tier values: Standard, WAF, Standard_v2, WAF_v2
$sku = New-AzApplicationGatewaySku -Name Standard_v2 -Tier Standard_v2 -Capacity 2

# Create new public IP Address
$publicIP = New-AzPublicIpAddress -ResourceGroupName $resourceGroupName -Location $location -Name $publicIPAddressName -AllocationMethod Static -Sku Standard

#create new Public FrontEnd IP Configuration
$publicIPConfiguration = New-AzApplicationGatewayFrontendIPConfig -Name  $publicFrontEndIPConfigName -PublicIPAddress $publicIP

#Add public IP Front End Configration to Array
$GatewayFrontEndIPConfigurations += $publicIPConfiguration;

#Get virtual Network
$vnet = Get-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Name $virtualNetwork
#Get subnet
$subnet = Get-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet

#create new Private frontEndIP configuration
$privateIPConfiguration = New-AzApplicationGatewayFrontendIPConfig -Name $privateFrontEndIPConfigName -Subnet $subnet -PrivateIPAddress $privateIPAddress

#Add Private IP Front End Configration to Array
$GatewayFrontEndIPConfigurations += $privateIPConfiguration;

#create Application Gateway IP Configuration
$GatewayIPconfiguration = New-AzApplicationGatewayIPConfiguration -Name $gatewayIPConfigurationName -Subnet $subnet

#create frontEnd Ports
foreach ($port in $FrontEndPortCollection) {
    $frontEndPorts = [Array]$frontEndPorts + (New-AzApplicationGatewayFrontendPort -Name $frontEndPortName'-01' -Port $port) #different for each FrontEnd Port
}

#Get all the replicated VMs from Target Resource Group
$AllVMS = Get-azVM -resourcegroupname $resourceGroupName
$i = 0;
#Create all required resources listener, httpsettings, healthprobes, routingrule and backendaddresspool for Application Gateway
foreach( $vm in $AllVMS){

    #Get IP Address and Name fo Replicated VM
    $Profile =$VM.NetworkProfile.NetworkInterfaces.Id.Split("/") | Select-Object -Last 1
    $IPConfig = Get-AzNetworkInterface -Name $Profile
    $IPAddress = $IPConfig.IpConfigurations.PrivateIpAddress   
    $VMName =  $vm.Name;

    #Create HTTPListener
    $NewHttpListener = $null;
    $NewHttpListener = New-AzApplicationGatewayHttpListener -Name $VMName"-HttpListener" -Protocol "Http" -FrontendIpConfiguration $privateIPConfiguration -FrontendPort $FrontEndPortCollection[i]          
    $i = $i + 1;   
    #Add Listener to Collection
    $HttpListenerCollection += $NewHttpListener
    
    #add health probe
    $NewProb = New-AzApplicationGatewayProbeConfig -Name $VMName"-HealthProbe" -Protocol Http -HostName "127.0.0.1" -Path "/api/cphs/actuator/health" -Interval 30 -Timeout 30 -UnhealthyThreshold 3
    #Add Health Probe to Collection
    $HealthProbeCollection = [Array]$HealthProbeCollection + $NewProb;

    #add backendaddresspool
    $NewBackendAddressPool = New-AzApplicationGatewayBackendAddressPool -Name $VMName"-BackendPool" -BackendIPAddresses $IPAddress
    #Add Backend address Pool to collection
    $BackendAddressPoolCollection += $NewBackendAddressPool

    #add HTTPSetting
    $NewHttpSetting = New-AzApplicationGatewayBackendHttpSettings -Name  $VMName"-Setting" -Port 8080 -Protocol "HTTP" -CookieBasedAffinity "Enabled" -AffinityCookieName "ApplicationGatewayAffinity" -RequestTimeout 20 -Probe $NewProb
    #Add HTTPSetting to Collection
    $HttpSettingCollection = [Array]$HttpSettingCollection + $NewHttpSetting

    #add HTTP Routing Rule
    $NewRoutingRule = New-AzApplicationGatewayRequestRoutingRule -Name $VMName"-Rule" -RuleType Basic -BackendHttpSettings $NewHttpSetting -HttpListener $NewHttpListener -BackendAddressPool $NewBackendAddressPool
    #add HTTP Routing Rule to Collection
    $RoutingRuleCollection += $NewRoutingRule
}

#Note the starting time
write-host 'Starting to create Application Gateway at: '
Get-Date -Format "dddd MM/dd/yyyy HH:mm K"
#Create new Application Gateway by adding all the created resources collections
New-AzApplicationGateway -Name $TargetAppGatewayName -ResourceGroupName $resourceGroupName -Location $location -Sku $sku -GatewayIPConfigurations $GatewayIPconfiguration -FrontendIPConfigurations $GatewayFrontEndIPConfigurations -FrontendPorts $frontEndPorts -BackendAddressPools $BackendAddressPoolCollection -BackendHttpSettingsCollection $HttpSettingCollection -HttpListeners $HttpListenerCollection -RequestRoutingRules $RoutingRuleCollection -Probes $HealthProbeCollection

#Note the completing time
write-host 'Application Gateway created at: ' 
Get-Date -Format "dddd MM/dd/yyyy HH:mm K"
