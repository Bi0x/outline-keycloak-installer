
installMinIO() {
    # Get config path
    minioAssetsPath=$(getInstallScriptFilePath)/assets/minio/
    tempPath=$(getOutlineDataPath)

    # copy new compose file
    cp $minioAssetsPath/minio-compose-template.yml $tempPath/minio-compose.yml
    containerName=outline-data-minio-$(echo $RANDOM | md5sum | head -c 8; echo;)

    # Generate username and password
    minioUsername=outline_minio_user_$(echo $RANDOM | md5sum | head -c 8; echo;)
    minioPassword=$(echo $RANDOM | md5sum | head -c 32; echo;)

    # Update env
    sed -i "s/_REPLACE_MINIO_CONTAINER_NAME_HERE_/$containerName/g" $tempPath/minio-compose.yml
    sed -i "s/_REPLACE_MINIO_BUCKET_PORT_HERE_/$1/g" $tempPath/minio-compose.yml
    sed -i "s/_REPLACE_MINIO_ADMIN_PORT_HERE_/$2/g" $tempPath/minio-compose.yml
    sed -i "s/_REPLACE_MINIO_ROOT_USER_HERE_/$minioUsername/g" $tempPath/minio-compose.yml
    sed -i "s/_REPLACE_MINIO_ROOT_PASSWORD_HERE_/$minioPassword/g" $tempPath/minio-compose.yml

    # Docker-compose
    docker-compose -f $tempPath/minio-compose.yml up -d
    # Wait 10 seconds for initialization.
    sleep 10

    # return user and pass
    echo "{\"user\":\"$minioUsername\",\"pass\":\"$minioPassword\"}"
}

configureMinIO() {
    baseMinIOUrl="127.0.0.1:$3"

    # Step 1: Login
    loginCookie=$(curl -s -k -X $'POST' -c - \
    -H $'Content-Type: application/json' \
    --data-binary $"{\"accessKey\":\"$1\",\"secretKey\":\"$2\"}" \
    $"http://$baseMinIOUrl/api/v1/login")

    # Step 2: Create bucket
    bucketName=outline-bucket-$(echo $RANDOM | md5sum | head -c 8; echo;)
    createBucketRes=$(curl -s -k --cookie <(echo "$loginCookie") -X $'POST'\
    -H $'Content-Type: application/json' \
    --data-binary $"{\"name\":\"$bucketName\",\"versioning\":false,\"locking\":false}" \
    $"http://$baseMinIOUrl/api/v1/buckets")

    # Step 3: Create access rules
    step3Res=$(curl -s -k --cookie <(echo "$loginCookie") -X $'PUT' \
    -H $'Content-Type: application/json' \
    --data-binary $'{\"prefix\":\"/avatar\",\"access\":\"readonly\"}' \
    $"http://$baseMinIOUrl/api/v1/bucket/outline-files/access-rules")

    step4Res=$(curl -s -k --cookie <(echo "$loginCookie") -X $'PUT' \
    -H $'Content-Type: application/json' \
    --data-binary $'{\"prefix\":\"/public\",\"access\":\"readonly\"}' \
    $"http://$baseMinIOUrl/api/v1/bucket/outline-files/access-rules")

    # Step 4: Create bucket user
    outlineBucketUsername=outline-bucket-user-$(echo $RANDOM | md5sum | head -c 8; echo;)
    outlineBucketUserSecret=$(echo $RANDOM | md5sum | head -c 32; echo;)
    createUserRes=$(curl -s --cookie <(echo "$loginCookie") -k -X $'POST' \
    -H $'Content-Type: application/json' \
    --data-binary $"{\"accessKey\":\"$outlineBucketUsername\",\"secretKey\":\"$outlineBucketUserSecret\",\"groups\":[],\"policies\":[\"readwrite\"]}" \
    $"http://$baseMinIOUrl/api/v1/users")

    # Step5: Create secret key access
    usernameBase64=$(echo "$outlineBucketUsername" | base64)
    userAccessKey=$(echo $RANDOM | md5sum | head -c 16; echo;)
    userSecretKey=$(echo $RANDOM | md5sum | head -c 32; echo;)
    createKeyAccessRes=$(curl -s -k --cookie <(echo "$loginCookie") -X $'POST' \
    -H $'Content-Type: application/json' \
    --data-binary $"{\"policy\":\"\",\"accessKey\":\"$userAccessKey\",\"secretKey\":\"$userSecretKey\"}" \
    $"http://$baseMinIOUrl/api/v1/user/$usernameBase64/service-account-credentials")

    echo "{\"accessKey\":\"$userAccessKey\",\"secretKey\":\"$userSecretKey\",\"user\":\"$outlineBucketUsername\",\"pass\":\"$outlineBucketUserSecret\",\"bucketName\":\"$bucketName\"}"
}