pipeline{
    agent any
    stages{
        //failpast true - stop execution if any stage got failed
         parallel {
            stage('Start IAUC ASR Plan'){
                steps{                    
                    sh 'az login --service-principal -u ae850628-c022-4fef-9eb2-159a8ad5f743 -p JvFEy~r8Bvp3wG-DT5~Qg956t9hC49bZ7. -t 1bfc3093-d35c-42eb-8df1-47a59e098146'
                    sh '$ASRRecoveryPlanIAUC = Get-AzRecoveryServicesAsrRecoveryPlan -Name iaus-recovery-plan'                    
                    sh 'Start-AzRecoveryServicesAsrTestFailoverJob -RecoveryPlan $ASRRecoveryPlanIAUC -Direction PrimaryToRecovery'                    
                }
            }
             stage('Geo-replication'){
                steps{
                    sh './Scripts/GeoReplication.sh'
                }
            }
         }    
    }
}
