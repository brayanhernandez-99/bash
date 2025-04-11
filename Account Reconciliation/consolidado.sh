#!/bin/bash
## vars
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[1;33m"
NC="\e[0m"
ACCOUNT_DIR="/opt/rundeck_files/Account_Reconciliation"
ACCOUNT_NAME="account_reconciliation.csv"

echo -e "$YELLOW ########### >>>> Ordenando listados usuarios. <<<<< ########### $NC"
cd $ACCOUNT_DIR
for i in $(ls -C1 account_reconciliation-*.csv); do
    HOST=$(echo "$i" | awk -F'-' '{print $2}' | awk -F'.' '{print $1}')
    awk -v host="$HOST" '{print $1, ",", host}' $i | sort >$ACCOUNT_DIR/ordenado_$i # | sort | uniq >

    FILE="$ACCOUNT_DIR/ordenado_$i"
    if [[ -f "$FILE" ]] && [[ -s "$FILE" ]]; then
        echo -e ">>>> ordenado_$i <<<<<"
    else
        echo -e "\n $RED >>>> ordenado_$i <<<<< $NC"
        exit 99
    fi
done

cat $ACCOUNT_DIR/ordenado_account_reconciliation-*.csv >$ACCOUNT_DIR/$ACCOUNT_NAME
FILE="$ACCOUNT_DIR/$ACCOUNT_NAME"
if [[ -f "$FILE" ]] && [[ -s "$FILE" ]]; then
    echo -e "$GREEN ########### >>>> Consolidado exitoso. <<<<< ########### $NC"
else
    echo -e "\n $RED ########### >>>> Error consolidando. <<<<< ########### $NC"
    exit 99
fi

FILES="$(ls $ACCOUNT_DIR/*_reconciliation-*.csv) 2>/dev/null)"
if [[ -z "$FILES" ]]; then
    echo -e "\n $RED ########### >>>> Error eliminando $ACCOUNT_DIR/*_reconciliation-*.csv <<<<< ########### $NC"
    exit 99
else
    rm -f $FILES
fi
