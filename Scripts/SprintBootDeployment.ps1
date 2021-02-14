#Get all the replicated VMs from Target Resource Group
$AllVMS = Get-azVM -resourcegroupname $resourceGroupName
#Create all required resources listener, httpsettings, healthprobes, routingrule and backendaddresspool for Application Gateway
foreach( $vm in $AllVMS){

    #Get IP Address and Name fo Replicated VM
    $Profile =$VM.NetworkProfile.NetworkInterfaces.Id.Split("/") | Select-Object -Last 1
    $IPConfig = Get-AzNetworkInterface -Name $Profile
    $IPAddress = $IPConfig.IpConfigurations.PrivateIpAddress   
    $VMName =  $vm.Name;
    write-host $VMName
}
