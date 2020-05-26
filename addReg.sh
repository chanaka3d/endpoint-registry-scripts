#!/bin/bash

# get the URL of the current Astronomy Picture of the Day (APOD)
clientId=$(curl -k -X POST -H "Authorization: Basic YWRtaW46YWRtaW4=" -H "Content-Type: application/json" -d @payload.json https://localhost:9443/client-registration/v0.16/register | jq -r '.clientId')
clientSecret=$(curl -k -X POST -H "Authorization: Basic YWRtaW46YWRtaW4=" -H "Content-Type: application/json" -d @payload.json https://localhost:9443/client-registration/v0.16/register | jq -r '.clientSecret')
# get just the image name from the URL
echo $clientId
echo $clientSecret

encoded=$(echo -n $clientId:$clientSecret|openssl enc -base64 | tr -d '\n')
## I am not sure why i am doing the following but there are two suffix and prefix strings added after encoding.
## So I am removing them.
defectSufix="Cg=="
defectPrefix="LW4g"
encoded=${encoded#"$defectPrefix"}
encoded=${encoded%"$defectSufix"}
echo $encoded

# get access token
accessToken=$(curl -k -d "grant_type=password&username=admin&password=admin&scope=registry:write registry:view registry:entry_view registry:entry_write" -H "Authorization: Basic $encoded" https://localhost:9443/oauth2/token | jq -r '.access_token')

echo "======= access token =========="
echo $accessToken


function getServiceType()
{

    # array with domains
    TYPES=("REST" "GraphQL")

    # seed random generator
    RANDOM=$$$(date +%s)

    # pick a random entry from the domain list to check against
    RANDOM_SERVICE_TYPE=${TYPES[$RANDOM % ${#TYPES[@]}]}

}



array=( WSO2 K8S )
for i in "${array[@]}"
do
	regId=$(curl -k -H "Authorization: Bearer $accessToken" -H "Content-Type: application/json" -X POST --data-binary '{"name":"'$i'","type":"WSO2","mode":"READONLY"}' https://localhost:9443/api/am/endpoint-registry/v1/registries  | jq -r '.id')
    echo "==============================================================="
    echo $regId
    echo "================= Adding registry entries for $i ======================"
    for j in {1..2}
    do
        getServiceType
        echo $RANDOM_SERVICE_TYPE
        entryId=$(curl -k -X POST "https://localhost:9443/api/am/endpoint-registry/v1/registries/$regId/entry" -H "Authorization: Bearer $accessToken" -H "accept: application/json" -H "Content-Type: multipart/form-data" -F 'registryEntry={ "entryName": "Pizzashack-Endpoint'$j'", "productionServiceUrl": "http://localhost/pizzashack", "sandboxServiceUrl": "http://localhost/pizzashack", "serviceCategory": "UTILITY", "serviceType": "'$RANDOM_SERVICE_TYPE'", "definitionType": "OAS", "metadata": "{ \"mutualTLS\" : true }" };type=application/json'  | jq -r '.id')
        echo "=======================Add Registry entry ID========================================"
        echo $entryId
        echo "===================================================================================="
    done
done


# for i in {1..2}
#     do
#         regId=$(curl -k -H "Authorization: Bearer $accessToken" -H "Content-Type: application/json" -X POST --data-binary '{"name":"WSO2 Dev Registry'$i'","type":"WSO2","mode":"READONLY"}' https://localhost:9443/api/am/endpoint-registry/v1/registries  | jq -r '.id')
#         echo "==============================================================="
#         echo $regId
#     done
#curl -k -H "Authorization: Bearer 24b0a3ae-1d15-31b7-bbc1-673d682c3944" -H "Content-Type: application/json" -X GET "https://localhost:9443/api/am/endpoint-registry/v1/registries" -H "accept: application/json"


