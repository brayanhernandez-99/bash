#!/bin/bash
#################################################################
#																#
#	@description: Script para realizar deploy controlado de un  #
#	grupo de instancias en WildFly. 							#
#																#
#	@author: 	bhernandez								       	#
#	@since: 	Nov 21, 2023									#
#	@version: 	1.0												#
#																#
#################################################################

#   Environment Variables.
PORT="$[WildFly_Port]"
VERSION="$[WildFly_Version]"
GROUP="$[WildFly_ServerGroup]"
CONTROLLER="$[WildFly_Controller]"
ARTIFACT_PATH="$[ArtifactPath]"
RUNTIME_NAME="$[WildFly_RuntimeName]"
ARTIFACT_NAME="$[WildFly_ArtifactName]"
USER=$(ectool getFullCredential "/projects/$[/myPipelineRuntime/ProjectName]/credentials/$[/myPipelineRuntime/WildFly_Credentials]" --value userName)
PASSWORD=$(ectool getFullCredential "/projects/$[/myPipelineRuntime/ProjectName]/credentials/$[/myPipelineRuntime/WildFly_Credentials]" --value password)

#   Function to execute a command.
executeCommand(){
    command=$1
    echo "Executing command: executing command '/opt/wildfly/$VERSION/bin/jboss-cli.sh' --timeout=30000 -c --controller=$CONTROLLER:$PORT --user=$USER --password=*** --command='$command'"
    RESPONSE=$(/opt/wildfly/$VERSION/bin/jboss-cli.sh --timeout=30000 -c --controller=$CONTROLLER:$PORT --user=$USER --password=$PASSWORD --command="$command")
    if [[ $? -ne 0 ]]; then
        echo -e "\n»»» ERROR: executing command"
        echo "ERROR: $RESPONSE"
        exit 99
    fi
}



executeCommand "ls /deployment"
DEPLOYMENTS=$RESPONSE

if [[ $(echo "$DEPLOYMENTS" | grep -o "$ARTIFACT_NAME") == "$ARTIFACT_NAME" ]]; then
    echo -e "\n»»» ERROR: validating response"
    echo "ERROR: artifact $ARTIFACT_NAME, It's already deployed..."
    exit 99
else
    echo -e "\n»»» WARNING: deployment artifact $ARTIFACT_NAME of group $GROUP"
    executeCommand "deploy $ARTIFACT_PATH/$ARTIFACT_NAME --server-groups=$GROUP --name=$ARTIFACT_NAME --runtime-name=$RUNTIME_NAME"
    executeCommand "ls /deployment"
    DEPLOYMENTS=$RESPONSE
    
    if [[ $(echo "$DEPLOYMENTS" | grep -o "$ARTIFACT_NAME") == "$ARTIFACT_NAME" ]]; then 
        echo -e "\n»»» SUCCESS: artifact $ARTIFACT_NAME deployed successfully"
    else
        echo -e "\n»»» ERROR: validating response"
        echo "ERROR: artifact $ARTIFACT_NAME, It was not possible execute deploy"
        exit 99
    fi
fi
