#Obtengo los xmls necesarios
xmlBaseRequest='<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"> <env:Body> <dp:request xmlns:dp="http://www.datapower.com/schemas/management" domain="BDV_MOVIL">OPERATION_REQUEST</dp:request> </env:Body> </env:Envelope>'
xmlImportOperationRequest='<dp:do-import source-type="ZIP" overwrite-files="true" overwrite-objects="true"> <dp:input-file>BASE64_FILE</dp:input-file> </dp:do-import>'
echo "Downloaded artifact path:"
cd /tmp/BDV_DATAPOWER
pwd
echo -e "\nFile list:"
ls
base64File=$(cat 'BDV_MOVIL_qa1.zip' | openssl base64)
#Reemplazo en el xml base la opearacion a realizar
xmlImportOperationRequest=$(echo ${xmlImportOperationRequest//BASE64_FILE/$base64File})
xmlImportRequest=$(echo ${xmlBaseRequest//OPERATION_REQUEST/$xmlImportOperationRequest})

echo -e "\nFormated Request: \n$xmlImportRequest"
echo "$xmlImportRequest" >"xmlImportRequest.xml"

#credential datapowers user
userName=$(ectool getFullCredential "/projects/Utilities/credentials/DataPowerCredentialInt" --value userName)
password=$(ectool getFullCredential "/projects/Utilities/credentials/DataPowerCredentialInt" --value password)
#para ver mas al ejecutar el curl -v --trace-ascii /dev/stdout)
echo -e "\nRunning request: \n"
response=$(curl --insecure --data-binary @xmlImportRequest.xml -u $userName:$password https://192.168.113.21:5550/service/mgmt/current)
echo -e "\nResponse Data Power: \n$response"

echo -e "\nResponse save CloudBess property:"
ectool setProperty "/myParent/XmlImportResponse" "$(echo $response)"

#check if contains error
export IFS="|"
errors="env:Client|Authentication failure|error-log|<dp:result>ERROR</dp:result>"
#validamos que no esta vacia
if [[ -z $response ]]; then
  echo "ERROR: Nose obtuvo una respuesta"
  exit 1
fi
#validamos la lista de posibles errores
for error in $errors; do
  if [[ $response =~ "$error" ]]; then
    echo "ERROR: response string contains $error"
    exit 1
  fi
done
