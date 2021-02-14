_AZURE_LOGIN () {
   az login --service-principal -u ae850628-c022-4fef-9eb2-159a8ad5f743 -p JvFEy~r8Bvp3wG-DT5~Qg956t9hC49bZ7. -t 1bfc3093-d35c-42eb-8df1-47a59e098146
}

_SET_SUBSCRIPTION_RESOURCE () {
	az account set -s $SUBSCRIPTION_NAME
}

_IAUC_STORAGE_ACCOUNT_FAILOVER () {
    echo 'IAUC - Storage account failover is initiated..' $(date '+%d/%m/%Y %H:%M:%S')

    az storage account failover --name $IAUCSTORAGEACCOUNT --no-wait --yes

    echo 'IAUC - Storage account failover is completed successfully..' $(date '+%d/%m/%Y %H:%M:%S')
}

_IAUC_COSMOS_FAILOVER_TO_SECONDARY_REGION () {
    echo 'IAUC - Failingover to secondary region..' $(date '+%d/%m/%Y %H:%M:%S')
    
    az cosmosdb failover-priority-change --failover-policies ${SECONDARY_LOCATION}=0 ${PRIMARY_LOCATION}=1 --name ${MONGO_DATABASE_ACCOUNT_NAME_IAUC} --resource-group ${WEST_RESOURCE_GROUP}

    echo 'IAUC - Failedover to secondary region..' $(date '+%d/%m/%Y %H:%M:%S')
}

_IAUC_EVENT_HUB_FAILOVER () {
    echo 'IAUC - Event HUB failover is initiated..' $(date '+%d/%m/%Y %H:%M:%S')

    az eventhubs georecovery-alias fail-over --namespace-name ${EVENT_HUB_INBOUND_NAME_IAUC} --resource-group ${WEST_RESOURCE_GROUP}
    az eventhubs georecovery-alias fail-over --namespace-name ${EVENT_HUB_OUTBOUND_NAME_IAUC} --resource-group ${WEST_RESOURCE_GROUP}

    echo 'IAUC - Event HUB failover is completed successfully..' $(date '+%d/%m/%Y %H:%M:%S')
}

_IAUC_SERVICE_HUB_FAILOVER () {
    echo 'IAUC - Service HUB failover is initiated..' $(date '+%d/%m/%Y %H:%M:%S')

    az servicebus georecovery-alias fail-over --resource-group ${WEST_RESOURCE_GROUP} --namespace-name ${SERVICE_BUS_NAME_IAUC}

    echo 'IAUC - Service HUB failover is completed successfully..' $(date '+%d/%m/%Y %H:%M:%S')
}


_SET_STORAGE_ACCOUNT_SKU () {
echo 'Storage Account failing over..' $(date '+%d/%m/%Y %H:%M:%S')
while true
do
  for val in "${StroageAccounts[@]}"; do
    echo "Checking the Storage Account: $val"
	
	temp=("${StroageAccounts[@]}")
    shouldBreak=false
	
	status=$(az storage account show -n $val --query failoverInProgress)

	if [ ! $status ]; then
	  echo "Storage Account: $val is failed over" 
	  
	  count=${#StroageAccounts[@]}

      for ((i=0;i<count;i++)); 
      do
        if [[ "${StroageAccounts[i]}" == $val ]]; then
          az storage account update --name $val --resource-group $WEST_RESOURCE_GROUP --sku Standard_RAGRS
          echo "Configured Standard_RAGRS for : $val}"
          unset temp[$i]
          shouldBreak=true
          break        
      done
   
	
	if [[ "${shouldBreak}" == "true" ]]; then
      break
   

  done
  
  StroageAccounts=("${temp[@]}")
	
  if [ ${#StroageAccounts[@]} -eq 0 ]; then
    echo "All the Stroage Accounts are Failedover"
    break
  else
    echo "Wait for the Failover to compelte"
    sleep 2m
  fi

done
echo 'Storage Account failed over..' $(date '+%d/%m/%Y %H:%M:%S')
}


########################################

echo 'Starting failover shared services: ' $(date '+%d/%m/%Y %H:%M:%S')

SUBSCRIPTION_NAME="b12e79a2-e576-4f06-86a1-0d854e9ca00e" #Azure Subscription 1 LXRInfotech
TENANT="1bfc3093-d35c-42eb-8df1-47a59e098146" #tenant ID

PRIMARY_LOCATION="westus"
SECONDARY_LOCATION="eastus2"

WEST_RESOURCE_GROUP="rg-east-Prod-IAUCDR"
EAST_RESOURCE_GROUP="rg-east-Prod-IAUCDR"

IAUCSTORAGEACCOUNT="le6csgasriaucpasrcache"

MONGO_DATABASE_ACCOUNT_NAME_IAUC="dr-mongodb-iaucccmsperf"

########################################
_AZURE_LOGIN
_SET_SUBSCRIPTION_RESOURCE

#execute parallelly with multi-threading 
_IAUC_STORAGE_ACCOUNT_FAILOVER & _IAUC_COSMOS_FAILOVER_TO_SECONDARY_REGION;

_SET_STORAGE_ACCOUNT_SKU

echo 'Failover completed: ' $(date '+%d/%m/%Y %H:%M:%S')
