
installOutline() {
    # Get config path
    outlineAssetsPath=$(getInstallScriptFilePath)/assets/outline/
    tempPath=$(getOutlineDataPath)

    # copy new compose file
    cp $outlineAssetsPath/outline-compose-template.yml $tempPath/outline-compose.yml
    containerOutlineName=outline-data-wiki-$(echo $RANDOM | md5sum | head -c 8; echo;)
    containerRedisName=outline-data-redis-$(echo $RANDOM | md5sum | head -c 8; echo;)

    # copy new env file
    cp $outlineAssetsPath/outline-template.env $tempPath/outline.env

    # Update compose file
    sed -i "s/_REPLACE_OUTLINE_CONTAINER_NAME_HERE_/$containerOutlineName/g" $tempPath/outline-compose.yml
    sed -i "s/_REPLACE_REDIS_CONTAINER_NAME_HERE_/$containerRedisName/g" $tempPath/outline-compose.yml
    sed -i "s/_REPLACE_OUTLINE_PORT_HERE_/$1/g" $tempPath/outline-compose.yml

    # Generate secrets
    outlineSecretKey="$(echo $RANDOM | md5sum | head -c 32)$(echo $RANDOM | md5sum | head -c 32)"
    outlineUtilsSecret="$(echo $RANDOM | md5sum | head -c 32)$(echo $RANDOM | md5sum | head -c 32)"

    # Update env file
    outlineURL=$2
    ssoURL=${13}
    minioBucketURL=$9
    sed -i "s/_REPLACE_OUTLINE_SECRET_KEY_HERE_/$outlineSecretKey/g" $tempPath/outline.env
    sed -i "s/_REPLACE_OUTLINE_UTILS_SECRET_HERE_/$outlineUtilsSecret/g" $tempPath/outline.env
    sed -i "s/_REPLACE_OUTLINE_URL_HERE_/${outlineURL//\//\\/}/g" $tempPath/outline.env

    sed -i "s/_REPLACE_OUTLINE_SQL_USER_HERE_/$5/g" $tempPath/outline.env
    sed -i "s/_REPLACE_OUTLINE_SQL_PASSWORD_HERE_/$6/g" $tempPath/outline.env
    sed -i "s/_REPLACE_OUTLINE_SQL_URL_HERE_/$3/g" $tempPath/outline.env
    sed -i "s/_REPLACE_OUTLINE_SQL_PORT_HERE_/$4/g" $tempPath/outline.env

    sed -i "s/_REPLACE_OUTLINE_MINIO_ACCESS_KEY_HERE_/$7/g" $tempPath/outline.env
    sed -i "s/_REPLACE_OUTLINE_MINIO_SECRET_KEY_HERE_/$8/g" $tempPath/outline.env
    sed -i "s/_REPLACE_OUTLINE_MINIO_BUCKET_URL_HERE_/${minioBucketURL//\//\\/}/g" $tempPath/outline.env
    sed -i "s/_REPLACE_OUTLINE_MINIO_BUCKET_NAME_HERE_/${10}/g" $tempPath/outline.env

    sed -i "s/_REPLACE_OUTLINE_OIDC_CLIENT_ID_HERE_/${11}/g" $tempPath/outline.env
    sed -i "s/_REPLACE_OUTLINE_OIDC_CLIENT_SECRET_HERE_/${12}/g" $tempPath/outline.env
    sed -i "s/_REPLACE_OUTLINE_SSO_URL_HERE_/${ssoURL//\//\\/}/g" $tempPath/outline.env
    sed -i "s/_REPLACE_OUTLINE_SSO_REALM_HERE_/${14}/g" $tempPath/outline.env
    sed -i "s/_REPLACE_OUTLINE_SSO_DISPLAY_NAME_HERE_/${15}/g" $tempPath/outline.env

    # Docker-compose
    docker-compose -f $tempPath/outline-compose.yml up -d
}