pipeline{
    agent any
    stages{
        //failpast true - stop execution if any stage got failed
         parallel {
            stage('Start IAUC ASR Plan'){
                steps{                    
                    sh 'az login --service-principal -u ae850628-c022-4fef-9eb2-159a8ad5f743 -p JvFEy~r8Bvp3wG-DT5~Qg956t9hC49bZ7. -t 1bfc3093-d35c-42eb-8df1-47a59e098146'
                    sh '$ASRRecoveryPlanIAUC = Get-AzRecoveryServicesAsrRecoveryPlan -Name IAUC-Dev-DR-Plan'                    
                    sh 'Start-AzRecoveryServicesAsrTestFailoverJob -RecoveryPlan $ASRRecoveryPlanIAUC -Direction PrimaryToRecovery'                    
                }
            }
            stage('Start EMCO ASR Plan'){
                steps{                    
                    sh 'az login --service-principal -u ae850628-c022-4fef-9eb2-159a8ad5f743 -p JvFEy~r8Bvp3wG-DT5~Qg956t9hC49bZ7. -t 1bfc3093-d35c-42eb-8df1-47a59e098146'
                    sh '$ASRRecoveryPlanEMCO = Get-AzRecoveryServicesAsrRecoveryPlan -Name DR-Plan-forEmco'                    
                    sh 'Start-AzRecoveryServicesAsrTestFailoverJob -RecoveryPlan $ASRRecoveryPlanEMCO -Direction PrimaryToRecovery'
                }
            }
             stage('Geo-replication'){
                steps{
                    sh './Scripts/Failover.sh'
                }
            }
         }
        //we can create application gateway parralelly, but need to add temp httplistener to do so
        stage('Create Application Gateway for IAUC and EMCO'){
            steps{
                sh './Scripts/ApplicationGateway.ps1'
            }
        }
        stage('Deploy Spring Boot East Profile'){
            steps{
                sh './Scripts/SprintBootDeployment.sh'
            }
        }
    }
}
