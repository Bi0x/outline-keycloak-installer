
installPostgreSQL() {
    # Get config path
    postgresqlAssetPath=$(getInstallScriptFilePath)/assets/postgresql/
    tempPath=$(getOutlineDataPath)
    # mv new compose file
    cp $postgresqlAssetPath/postgresql-compose-template.yml $tempPath/postgresql-compose.yml
    cp $postgresqlAssetPath/init.sql $tempPath/postgresql-init.sql
    containerName=outline-data-postgresql-$(echo $RANDOM | md5sum | head -c 8; echo;)

    # Generate username and password
    postgreUsername=outline_postgre_user_$(echo $RANDOM | md5sum | head -c 8; echo;)
    postgrePassword=$(echo $RANDOM | md5sum | head -c 32; echo;)

    # Update env
    sed -i "s/_REPLACE_POSTGRESQL_CONTAINER_NAME_HERE_/$containerName/g" $tempPath/postgresql-compose.yml
    sed -i "s/_REPLACE_POSTGRE_PORT_HERE_/$1/g" $tempPath/postgresql-compose.yml
    sed -i "s/_REPLACE_POSTGRE_USERNAME_HERE_/$postgreUsername/g" $tempPath/postgresql-compose.yml
    sed -i "s/_REPLACE_POSTGRE_PASSWORD_HERE_/$postgrePassword/g" $tempPath/postgresql-compose.yml

    # Docker-compose
    docker-compose -f $tempPath/postgresql-compose.yml up -d
    # Wait for initialization.
    postgresqlWaitCount=100
    for i in $(seq $postgresqlWaitCount); do
        dockerCheckHealthyRes=$(docker ps | grep $containerName)
        if [[ $dockerCheckHealthyRes == *"(healthy)"* ]]; then
            break
        fi
        sleep 3
    done

    # return user and pass
    echo "{\"user\":\"$postgreUsername\",\"pass\":\"$postgrePassword\"}"
}
