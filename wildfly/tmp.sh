#!/bin/bash
#################################################################
#																#
#	@description: Script para realizar un borrado controlado de #
#	data, tmp a un grupo de instancias en WildFly. 				#
#																#
#	@author: 	bhernandez								       	#
#	@since: 	Feb 1, 2024		    					    	#
#	@version: 	1.0												#
#																#
#################################################################

#   Environment Variables.
PORT="$[WildFly_Port]"
VERSION="$[WildFly_Version]"
GROUP="$[WildFly_ServerGroup]"
CONTROLLER="$[WildFly_Controller]"
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

#   Function to execute a stop of server.
executeStopServer(){
    host=$1 && server=$2
    echo "»»» $server: WARNING turning off..."
    executeCommand "/host=$host/server=$server:stop(blocking=true,suspend-timeout=300)"
    executeCommand "/host=$host/server-config=$server:read-resource(include-runtime=true)"
    status=$(echo "$RESPONSE" | grep -oE '"status" => "\w*"')

    if [[ $(echo "$status" | grep -o "STARTED") == "STARTED" ]]; then
        echo "»»» $server: WARNING killing process..."
        for i in {1..4}; do
            executeCommand "/host=$host/server=$server:kill()" true
            executeCommand "/host=$host/server-config=$server:read-resource(include-runtime=true)"
            status=$(echo "$RESPONSE" | grep -oE '"status" => "\w*"')

            if [[ $(echo "$status" | grep -o "STARTED") == "STARTED" ]]; then
                if [[ $i -eq 4 ]]; then
                    echo -e "\n»»» ERROR: validating response"
                    echo "$server: ERROR executing killing process in server."
                    exit 99
                fi
            else
                break
            fi
        done
    fi
    printInfoServer "$host" "$server" "$status" 
}

#   Function to delete files of server.
executeDeleteFilesServer(){
    host=$1 && server=$2 
    echo "»»» $server: deleting..."
    echo "{"
    echo -e "\t\"data\" => \"$(ls -AR /opt/wildfly/$VERSION/$host/servers/$server/data | wc -l)\""
    echo -e "\t\"tmp\" => \"$(ls -AR /opt/wildfly/$VERSION/$host/servers/$server/tmp | wc -l)\""    
        for dir in data tmp; do 
            if [[ $(rm -rf /opt/wildfly/$VERSION/$host/servers/$server/$dir/*) -eq 0 ]]; then
                echo -e "\t»»» SUCCESS: delete files in /opt/wildfly/$VERSION/$host/servers/$server/$dir/*"
            else
                echo -e "\n\t»»» ERROR: delete files in /opt/wildfly/$VERSION/$host/servers/$server/$dir/*"
                exit 99
            fi
        done 
    echo "}"
}

#   Function to print information about status of server.
printInfoServer(){
    host=$1 && server=$2 && status=$3
    echo "»»» $server: shutdown..."
    echo "{"
    echo -e "\t\"host\" => \"$host\""
    echo -e "\t\"group\" => \"$GROUP\""
    echo -e "\t\"server\" => \"$server\""
    echo -e "\t$status"
    echo "}"
}



echo "»»» WARNING: deleting files of group $GROUP"
executeCommand "ls /host" true
HOSTS=$(echo "$RESPONSE" | grep -ioE '\S*HC\S*')

for host in ${HOSTS}; do
    echo -e "\n--------------------------------------------------"
    echo "»»» HC: $host"
    executeCommand "ls /host=$host/server"
    SERVERS=$RESPONSE

    for server in ${SERVERS}; do
        echo "»»» $server: validating the group..."
        executeCommand "/host=$host/server-config=$server:read-resource(include-runtime=true)"
        status=$(echo "$RESPONSE" | grep -oE '"status" => "\w*"')
        group=$(echo "$RESPONSE" | grep -o "$GROUP")
		
        if [[ "$group" == "$GROUP" ]]; then
            if [[ $(echo "$status" | grep -o "STARTED") == "STARTED" ]]; then
                executeStopServer "$host" "$server"
                executeDeleteFilesServer "$host" "$server"
            else
                executeDeleteFilesServer "$host" "$server"
            fi
        fi
    done
done
