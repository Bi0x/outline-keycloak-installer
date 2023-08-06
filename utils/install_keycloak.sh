installKeyCloak() {
    # Enable HTTPs
    if [[ $2 == "https" ]]; then
        printRed "TODO: KeyCloak HTTPs support"
    fi
    if [[ $1 == "dev-mode" ]]; then
        printGreen "> Installing Keycloak container..."
        # Get config path
        keycloakAssetsPath=$(getInstallScriptFilePath)/assets/keycloak/
        tempPath=$(getOutlineDataPath)
        # mv new compose file
        cp $keycloakAssetsPath/keycloak-compose-template.yml $tempPath/keycloak-compose.yml
        containerName=outline-data-keycloak-$(echo $RANDOM | md5sum | head -c 8; echo;)
        # Update compose variables
        sed -i "s/_REPLACE_KEYCLOAK_CONTAINER_NAME_HERE_/$containerName/g" $tempPath/keycloak-compose.yml
        sed -i "s/_REPLACE_KEYCLOAK_ADMIN_NAME_HERE_/$3/g" $tempPath/keycloak-compose.yml
        sed -i "s/_REPLACE_KEYCLOAK_ADMIN_PASSWORD_HERE_/$4/g" $tempPath/keycloak-compose.yml
        sed -i "s/_REPLACE_KEYCLOAK_HTTP_PORT_HERE_/$5/g" $tempPath/keycloak-compose.yml
        sed -i "s/_REPLACE_KEYCLOAK_HTTPS_PORT_HERE_/$6/g" $tempPath/keycloak-compose.yml
        # Docker-compose
        docker-compose -f $tempPath/keycloak-compose.yml up -d
        # Keycloak up.
        keycloakWaitCount=100
        for i in $(seq $keycloakWaitCount); do
            printRaw "  Waiting for Keycloak initialization..."
            keycloakStatusCode=$(curl --write-out '%{http_code}' --silent --output /dev/null http://127.0.0.1:$5)
            if [[ "$keycloakStatusCode" -eq 200 ]] ; then
                printGreen "> Keycloak container install successfully!"
                break
            fi
            sleep 3
        done
    fi
}

configureKeycloak() {
    baseKeycloakUrl="127.0.0.1:$3"

    # Step 1: Get access token from keycloak
    keycloakAccessToken=$(curl -s -k -X $'POST' \
    -H $'Content-type: application/x-www-form-urlencoded' \
    --data-binary $"username=$1&password=$2&grant_type=password&client_id=admin-cli" \
    $"http://$baseKeycloakUrl/realms/master/protocol/openid-connect/token" | jq --raw-output '."access_token"')

    # Step 2: Create outline realm with random name
    outlineRealmName="outline_realm_$(echo $RANDOM | md5sum | head -c 8; echo;)"
    createRealmResponseCode=$(curl -s --write-out '%{http_code}' --silent --output /dev/null -k -X $'POST' \
    -H $"authorization: Bearer $keycloakAccessToken" \
    -H $'content-type: application/json' \
    --data-binary $"{\"realm\":\"$outlineRealmName\",\"enabled\":true}" \
    $"http://$baseKeycloakUrl/admin/realms")
    # If not 201 Created, create failed.
    if [[ "$createRealmResponseCode" -ne 201 ]] ; then
        printRed "> Keycloak Outline realm create with name $outlineRealmName failed! Stop..."
        exit 1
    fi

    # Step 3: Create outline realm client
    outlineRealmClientName="outline_realm_client_$(echo $RANDOM | md5sum | head -c 8; echo;)"
    createClientResponseCode=$(curl -s --write-out '%{http_code}' --silent --output /dev/null -k -X $'POST' \
    -H $"authorization: Bearer $keycloakAccessToken" \
    -H $'content-type: application/json' \
    --data-binary $"{\"protocol\":\"openid-connect\",\"clientId\":\"$outlineRealmClientName\",\"name\":\"$outlineRealmClientName\",\"description\":\"\",\"publicClient\":false,\"authorizationServicesEnabled\":false,\"serviceAccountsEnabled\":false,\"implicitFlowEnabled\":false,\"directAccessGrantsEnabled\":true,\"standardFlowEnabled\":true,\"frontchannelLogout\":true,\"attributes\":{\"saml_idp_initiated_sso_url_name\":\"\",\"oauth2.device.authorization.grant.enabled\":false,\"oidc.ciba.grant.enabled\":false,\"post.logout.redirect.uris\":\"$4/*\"},\"alwaysDisplayInConsole\":false,\"rootUrl\":\"$4\",\"baseUrl\":\"$4\",\"redirectUris\":[\"$4/*\"],\"webOrigins\":[\"$4\"]}" \
    $"http://$baseKeycloakUrl/admin/realms/$outlineRealmName/clients")
    # If not 201 Created, create failed.
    if [[ "$createClientResponseCode" -ne 201 ]] ; then
        printRed "> Keycloak Outline client create with name $outlineRealmClientName failed! Stop..."
        exit 1
    fi

    # Step 4: Get outline client ID.
    clientID=$(curl -s -k \
    -H $"authorization: Bearer $keycloakAccessToken" \
    $"http://$baseKeycloakUrl/admin/realms/$outlineRealmName/clients?first=0&max=100" | \
    jq --raw-output ".[] | select(.name == \"$outlineRealmClientName\") | .id")

    # Step 5: Get outline client secret.
    clientSecretKey=$(curl -s -k \
    -H $"authorization: Bearer $keycloakAccessToken" \
    $"http://$baseKeycloakUrl/admin/realms/$outlineRealmName/clients/$clientID/client-secret" | \
    jq --raw-output '."value"')

    # Step 6: Create same user in outline realm
    curl -s -k -X $'POST' \
    -H $"authorization: Bearer $keycloakAccessToken" \
    -H $'content-type: application/json' \
    --data-binary $"{\"username\":\"$1\",\"email\":\"admin@admin.com\",\"firstName\":\"$1\",\"lastName\":\"$1\",\"requiredActions\":[],\"emailVerified\":true,\"groups\":[],\"enabled\":true}" \
    $"http://$baseKeycloakUrl/admin/realms/$outlineRealmName/users"

    # Step 7: Get uuid
    adminUUID=$(curl -s -k -X $'GET' \
    -H $"authorization: Bearer $keycloakAccessToken" \
    $"http://$baseKeycloakUrl/admin/realms/$outlineRealmName/ui-ext/brute-force-user?briefRepresentation=true&first=0&max=11" | \
    jq --raw-output ".[] | select(.username == \"$1\") | .id")


    # Step 8: Set user password
    curl -s -k -X $'PUT' \
    -H $"authorization: Bearer $keycloakAccessToken" \
    -H $'content-type: application/json' \
    --data-binary $"{\"temporary\":false,\"type\":\"password\",\"value\":\"$2\"}" \
    $"http://$baseKeycloakUrl/admin/realms/$outlineRealmName/users/$adminUUID/reset-password"

    echo "{\"id\":\"$outlineRealmClientName\",\"key\":\"$clientSecretKey\",\"realm\":\"$outlineRealmName\"}"
}
