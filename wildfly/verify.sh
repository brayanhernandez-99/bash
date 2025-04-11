#!/bin/bash
#################################################################
#																#
#	@description: Script para realizar un validar el artefacto  #
#   desplegado en un grupo de instancias en WildFly. 		    #
#																#
#	@author: 	bhernandez								       	#
#	@since: 	Nov 23, 2023									#
#	@version: 	1.0												#
#																#
#################################################################

#   Environment Variables.
PORT="$[WildFly_Port]"
VERSION="$[WildFly_Version]"
CONTROLLER="$[WildFly_Controller]"
GROUP="$[WildFly_ServerGroup]"
ARTIFACT_NAME="$[WildFly_ArtifactName]"
USER=$(ectool getFullCredential '/projects/$[/myPipelineRuntime/ProjectName]/credentials/$[/myPipelineRuntime/WildFly_Credentials]' --value userName)
PASSWORD=$(ectool getFullCredential '/projects/$[/myPipelineRuntime/ProjectName]/credentials/$[/myPipelineRuntime/WildFly_Credentials]' --value password)

#   Function to execute a command.
executeCommand(){
    command=$1 && message=$2
    if [[ $message ]]; then 
        echo "Executing command: executing command '/opt/wildfly/$VERSION/bin/jboss-cli.sh' --timeout=30000 -c --controller=$CONTROLLER:$PORT --user=$USER --password=*** --command='$command'"
    fi

    RESPONSE=$(/opt/wildfly/$VERSION/bin/jboss-cli.sh --timeout=30000 -c --controller=$CONTROLLER:$PORT --user=$USER --password=$PASSWORD --command="$command")
    if [[ $? -ne 0 ]]; then
        echo -e "\n»»» ERROR: executing command"
        echo "Command: '/opt/wildfly/$VERSION/bin/jboss-cli.sh' --timeout=30000 -c --controller=$CONTROLLER:$PORT --user=$USER --password=*** --command='$command'"
        echo "ERROR: $RESPONSE"
        exit 99
    fi
}

#   function to validate the deployment of an artifact on the server.
executeValidateDeployment(){
    host=$1 && server=$2         
    for i in {1..5}; do
        executeCommand "/host=$host/server=$server/deployment=$ARTIFACT_NAME:read-resource(include-runtime=true)"true
        status_deployment=$(echo "$RESPONSE" | grep -oE '"status" => "\w*"')

        if [[ $(echo "$status_deployment" | grep -o "OK") == "OK" ]]; then
            printInfoServer "$host" "$server" "$status_deployment"
        else
            if [[ $i -eq 5 ]]; then
                echo -e "\n»»» ERROR: validating response"
                echo "$server: ERROR verifying status deployment"
                printInfoServer "$host" "$server" "$status_deployment"
                exit 99
            fi
        fi
    done

}

#   Function to print information about status deployment of server.
printInfoServer(){
    host=$1 && server=$2 && status=$3
    echo "»»» $server: deployment status..."
    echo "{"
    echo -e "\t\"host\" => \"$host\""
    echo -e "\t\"group\" => \"$GROUP\""
    echo -e "\t\"server\" => \"$server\""
    echo -e "\t\"deployment\" => \"$ARTIFACT_NAME\""
    echo -e "\t$status"
    echo "}"
}



executeCommand "ls /host" true
HOSTS=$(echo "$RESPONSE" | grep -ioE '\S*HC\S*')

for host in ${HOSTS}; do
    echo -e "\n--------------------------------------------------"
    echo "»»» HOST: $host"
    executeCommand "ls /host=$host/server"
    SERVERS=$RESPONSE

    for server in ${SERVERS}; do
        echo "»»» $server: validating the group..."
        executeCommand "/host=$host/server-config=$server:read-resource(include-runtime=true)"
        group=$(echo "$RESPONSE" | grep -o "$GROUP")

        if [[ "$group" == "$GROUP" ]]; then
            echo "»»» $server: validating status deployment..."
            executeCommand "/host=$host/server=$server/deployment=$ARTIFACT_NAME:read-resource(include-runtime=true)"
            status_deployment=$(echo "$RESPONSE" | grep -oE '"status" => "\w*"')

            if [[ $(echo "$status_deployment" | grep -o "OK") == "OK" ]]; then
                printInfoServer "$host" "$server" "$status_deployment"
            else
                executeValidateDeployment "$host" "$server"
            fi
        fi
    done
done
