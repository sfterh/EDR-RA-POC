pipeline{
    agent any
    stages{        
        stage('Start IAUC ASR Plan'){
            steps{          
                bat 'write-host hello'
                bat 'az login --service-principal -u ae850628-c022-4fef-9eb2-159a8ad5f743 -p JvFEy~r8Bvp3wG-DT5~Qg956t9hC49bZ7. -t 1bfc3093-d35c-42eb-8df1-47a59e098146'
                bat '$ASRRecoveryPlanIAUC = Get-AzRecoveryServicesAsrRecoveryPlan -Name iaus-recovery-plan'                    
                bat 'Start-AzRecoveryServicesAsrTestFailoverJob -RecoveryPlan $ASRRecoveryPlanIAUC -Direction PrimaryToRecovery'                    
            }
        }
        stage('Geo-replication'){
            steps{
                sh './Scripts/GeoReplication.sh'
            }
        }
    }
}
