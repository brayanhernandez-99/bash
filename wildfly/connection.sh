#!/bin/bash
################################################################
#                                                              # 
#	@description: Script para realizar validacion de conexion  #
#   con el DC de WildFly.                                      #
#								                               #
#	@author: 	bhernandez		                               #
#	@since: 	Nov 15, 2023				                   #
#	@version: 	1.0					                           #
#							                                   #
################################################################

# Environment Variables.
PORT="$[WildFly_Port]"
VERSION="$[WildFly_Version]"
CONTROLLER="$[WildFly_Controller]"
USER=$(ectool getFullCredential "/projects/$[/myPipelineRuntime/ProjectName]/credentials/$[/myPipelineRuntime/WildFly_Credentials]" --value userName)
PASSWORD=$(ectool getFullCredential "/projects/$[/myPipelineRuntime/ProjectName]/credentials/$[/myPipelineRuntime/WildFly_Credentials]" --value password)

    
#   Function to print information about connection.
printInfoConnection(){
    version=$1 && controller=$2 && port=$3
    echo "{"
    echo -e "\t\"credentials\" => \"/projects/$[/myPipelineRuntime/ProjectName]/credentials/$[/myPipelineRuntime/WildFly_Credentials]\""
    echo -e "\t\"version\" => \"$version\""
    echo -e "\t\"controller\" => \"$controller\""
    echo -e "\t\"port\" => \"$port\""
    echo "}"
}


echo "»»» INFO: validating connection..."
echo "Executing command '/opt/wildfly/$VERSION/bin/jboss-cli.sh' --timeout=30000 -c --controller=$CONTROLLER:$PORT --user=$USER --password=*** --command=''"
CONNECTION=$(/opt/wildfly/$VERSION/bin/jboss-cli.sh --timeout=30000 -c --controller=$CONTROLLER:$PORT --user=$USER --password=$PASSWORD --command='')

if [[ $? -eq 0 ]]; then
    echo -e "\n»»» SUCCESS: connection successful..."
    printInfoConnection "$VERSION" "$CONTROLLER" "$PORT" 
else
    echo -e "\n»»» ERROR: connection rejected..."
    echo $CONNECTION
    printInfoConnection "$VERSION" "$CONTROLLER" "$PORT" 
    exit 99
fi 
