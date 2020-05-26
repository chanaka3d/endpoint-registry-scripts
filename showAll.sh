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
echo "==============================================================="


registries=$(curl -k -H "Authorization: Bearer $accessToken" -H "Content-Type: application/json" -X GET "https://localhost:9443/api/am/endpoint-registry/v1/registries" -H "accept: application/json")
echo $registries
echo "==============================================================="

 for row in $(echo "${registries}" | jq -r '.[] | @base64'); do
    _jq() {
     echo ${row} | base64 --decode | jq -r ${1}
    }

   id=$(_jq '.id')
   echo "==== Registry Entries for === $id"
   entries=$(curl -k -H "Authorization: Bearer $accessToken" -H "Content-Type: application/json" "https://localhost:9443/api/am/endpoint-registry/v1/registries/$id/entries"  | jq -r '.')
   echo $entries

done


# for i in {1..2}
#     do
#         regId=$(curl -k -H "Authorization: Bearer $accessToken" -H "Content-Type: application/json" -X POST --data-binary '{"name":"WSO2 Dev Registry'$i'","type":"WSO2","mode":"READONLY"}' https://localhost:9443/api/am/endpoint-registry/v1/registries  | jq -r '.id')
#         echo "==============================================================="
#         echo $regId
#     done
#curl -k -H "Authorization: Bearer 24b0a3ae-1d15-31b7-bbc1-673d682c3944" -H "Content-Type: application/json" -X GET "https://localhost:9443/api/am/endpoint-registry/v1/registries" -H "accept: application/json"


