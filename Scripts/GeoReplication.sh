_AZURE_LOGIN () {
    az login
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
        fi
      done
    fi
	
	if [[ "${shouldBreak}" == "true" ]]; then
      break
    fi

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

SUBSCRIPTION_NAME="a8e7f59d-5877-4efb-843b-f1a909b1c137"
TENANT="b7f604a0-00a9-4188-9248-42f3a5aac2e9"

PRIMARY_LOCATION="westus"
SECONDARY_LOCATION="eastus"

WEST_RESOURCE_GROUP="dr-rg"
EAST_RESOURCE_GROUP="dr-rg"

IAUCSTORAGEACCOUNT="drcncnp"
#declare -a StroageAccounts=("drospkecomnpst01" "drtangerinefilestorage")

MONGO_DATABASE_ACCOUNT_NAME_IAUC="dr-mongodb-iaucccmsperf"

EVENT_HUB_INBOUND_NAME_IAUC = "dr-eventhub-iaucinbound-west"
EVENT_HUB_OUTBOUND_NAME_IAUC = "dr-eventhub-iaucoutbound-west"

SERVICE_BUS_NAME_IAUC = "dr-iauc-az-perf-west"

########################################
#_AZURE_LOGIN
_SET_SUBSCRIPTION_RESOURCE

#execute parallelly with multi-threading 
_IAUC_STORAGE_ACCOUNT_FAILOVER & _IAUC_COSMOS_FAILOVER_TO_SECONDARY_REGION & _IAUC_EVENT_HUB_FAILOVER & _IAUC_SERVICE_HUB_FAILOVER;

_SET_STORAGE_ACCOUNT_SKU

echo 'Failover completed: ' $(date '+%d/%m/%Y %H:%M:%S')
