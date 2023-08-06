
getValueFromJson() {
    echo $(jq -r ".$1" "$(getUserConfigJsonPath)")
}

mainInstall() {
    source $(getInstallScriptFilePath)/utils/install_keycloak.sh
    source $(getInstallScriptFilePath)/utils/install_postgresql.sh
    source $(getInstallScriptFilePath)/utils/install_minio.sh
    source $(getInstallScriptFilePath)/utils/install_outline.sh
    # Param1: "new" -> New Install. "backup" -> Install and import backup file.
    if [[ $1 == "new" ]]; then
        # Install Keycloak and auto configure realm
        installKeyCloak "dev-mode" "http" $3 $4 $5 $6
        keycloakConfigureRes=$(configureKeycloak $3 $4 $5 $7)
        keycloakClientID=$(echo $keycloakConfigureRes | jq --raw-output '."id"')
        keycloakClientSecretKey=$(echo $keycloakConfigureRes | jq --raw-output '."key"')
        keycloakClientRealm=$(echo $keycloakConfigureRes | jq --raw-output '."realm"')

        # Install PostgreSQL
        printGreen "> Installing PostgreSQL container..."
        postgreSQLInitRes=$(installPostgreSQL $8)
        # echo $postgreSQLInitRes
        postgreSQLUsername=$(echo $postgreSQLInitRes | jq --raw-output '."user"')
        postgreSQLPassword=$(echo $postgreSQLInitRes | jq --raw-output '."pass"')
        printGreen "> PostgreSQL container install successfully!"

        # Install MinIO
        printGreen "> Installing MinIO container..."
        minioInitRes=$(installMinIO $9 ${10})
        # echo $minioInitRes
        minioUsername=$(echo $minioInitRes | jq --raw-output '."user"')
        minioPassword=$(echo $minioInitRes | jq --raw-output '."pass"')
        minioConfigureRes=$(configureMinIO $minioUsername $minioPassword ${10})
        # echo $minioConfigureRes
        minioBucketAccessKey=$(echo $minioConfigureRes | jq --raw-output '."accessKey"')
        minioBucketSecretKey=$(echo $minioConfigureRes | jq --raw-output '."secretKey"')
        minioBucketUsername=$(echo $minioConfigureRes | jq --raw-output '."user"')
        minioBucketUserPass=$(echo $minioConfigureRes | jq --raw-output '."pass"')
        minioBucketName=$(echo $minioConfigureRes | jq --raw-output '."bucketName"')
        printGreen "> MinIO container install successfully!"

        # Install Outline
        printGreen "> Installing Outline wiki container..."
        #                               $outlinePort $outlineBaseUrl $sqlURL $sqlPort $postgreSQLUsername $postgreSQLPassword
        #                               $minioBucketAccessKey $minioBucketSecretKey $minioURL $minioBucketName
        #                               $keycloakClientID $keycloakClientSecretKey $ssoURL $keycloakClientRealm
        #                               $ssoName
        outlineInitRes=$(installOutline ${11} $7 ${12} $8 $postgreSQLUsername $postgreSQLPassword \
                                        $minioBucketAccessKey $minioBucketSecretKey ${13} $minioBucketName \
                                        $keycloakClientID $keycloakClientSecretKey ${14} $keycloakClientRealm \
                                        ${15})
        
        printGreen "> Outline wiki install successfully!"
    fi
}

mainInstallFromUserConfig() {
    # Read value from user-config.json
    installType=$(getValueFromJson "installType")
    adminUsername=$(getValueFromJson "adminUsername")
    adminPassword=$(getValueFromJson "adminPassword")
    ssoURL=$(getValueFromJson "ssoURL")
    ssoURL=${ssoURL%/}
    ssoName=$(getValueFromJson "ssoName")
    ssoHttpPort=$(getValueFromJson "ssoHttpPort")
    ssoHttpsPort=$(getValueFromJson "ssoHttpsPort")
    sqlIP=$(getValueFromJson "sqlIP")
    sqlPort=$(getValueFromJson "sqlPort")
    minioBucketURL=$(getValueFromJson "minioBucketURL")
    minioBucketURL=${minioBucketURL%/}
    minioBucketPort=$(getValueFromJson "minioBucketPort")
    minioAdminPort=$(getValueFromJson "minioAdminPort")
    outlinePort=$(getValueFromJson "outlinePort")
    outlineBaseUrl=$(getValueFromJson "outlineBaseUrl")
    outlineBaseUrl=${outlineBaseUrl%/}

    # Check if any param is empty
    paramList=("installType" "adminUsername" "adminPassword" "ssoHttpPort" "ssoHttpsPort" \
               "sqlPort" "minioBucketPort" "minioAdminPort" "outlineBaseUrl")

    for perParam in "${paramList[@]}"
    do
        if [ -z "${!perParam}" ]; then
            printRed "Error: $perParam param is empty, stopping..."
            exit 1
        fi
    done

    # Start install
    mainInstall $installType "keycloak" $adminUsername $adminPassword \
                $ssoHttpPort $ssoHttpsPort $outlineBaseUrl $sqlPort \
                $minioBucketPort $minioAdminPort $outlinePort $sqlIP \
                $minioBucketURL $ssoURL $ssoName
}

# !! @Deprecated !!
mainInstallMenu() {
    # Removed! Now load config from user-config.json
    # Removed! Now load config from user-config.json
    # Removed! Now load config from user-config.json

    COLUMNS=1   # Show one item each line.
    INSTALL_MENU=("Install new Outline-KeyCloak instance.") # "Install Outline-KeyCloak and import backup file.(TODO)")
    select SELECTED_ITEM in "${INSTALL_MENU[@]}" Quit
    do
        case $REPLY in
            1)
                printGreen "> Installing new Outline with KeyCloak SSO..."

                # read username
                while [ -z $keycloakAdminUserName ]; do
                    printRawSameline "Enter keycloak administrator username: "
                    read keycloakAdminUserName
                done

                # read password input
                while [ -z $keycloakAdminPassword ]; do
                    printRawSameline "Enter keycloak administrator password: "
                    read keycloakAdminPassword
                done

                # read keycloak HTTP port
                printRawSameline "Enter keycloak HTTP port (default 6001 if not input): "
                read keycloakHTTPPort
                # default 6001
                if [ -z $keycloakHTTPPort ]
                then
                    keycloakHTTPPort="6001"
                    printRaw "  No port provided, using 6001 for keycloak HTTP."
                fi

                # read keycloak HTTPs port
                printRawSameline "Enter keycloak HTTPs port (default 6002 if not input): "
                read keycloakHTTPsPort
                # default 6002
                if [ -z $keycloakHTTPsPort ]
                then
                    keycloakHTTPsPort="6002"
                    printRaw "  No port provided, using 6002 for keycloak HTTPs."
                fi

                # read postgre port
                printRawSameline "Enter PostgreSQL port (default 6432 if not input): "
                read postgresqlPort
                # default 6432
                if [ -z $postgresqlPort ]
                then
                    postgresqlPort="6432"
                    printRaw "  No port provided, using 6432 for PostgreSQL port."
                fi

                # read minio port
                printRawSameline "Enter MinIO bucket port (default 9000 if not input): "
                read minioPort
                # default 9000
                if [ -z $minioPort ]
                then
                    minioPort="9000"
                    printRaw "  No port provided, using 9000 for MinIO bucket port."
                fi

                # read minio admin http port
                printRawSameline "Enter MinIO admin port (default 9001 if not input): "
                read minioAdminPort
                # default 9001
                if [ -z $minioAdminPort ]
                then
                    minioAdminPort="9001"
                    printRaw "  No port provided, using 9001 for MinIO admin port."
                fi

                # read Outline base URL
                urlRegex='^https?://[a-zA-Z0-9]+(\.[a-zA-Z0-9]+)+([^/]+)$'
                while true; do
                    printRawSameline "Enter Outline Wiki base URL without last slash (eg. http://wiki.example.com:1234): "
                    read outlineBaseUrl
                    if [[ $outlineBaseUrl =~ $urlRegex ]]
                    then 
                        break
                    else
                        printRed "> URL is not valid! Please check your input."
                    fi
                done

                mainInstall "new" "keycloak" $keycloakAdminUserName $keycloakAdminPassword \
                            $keycloakHTTPPort $keycloakHTTPsPort $outlineBaseUrl $postgresqlPort \
                            $minioPort $minioAdminPort
                break
                ;;
            # 2)
            #     printRaw "> Installing Outline with KeyCloak SSO. Then importing backup file..."
            #     mainInstall "backup" "keycloak" "backup_filepath"
            #     break
            #     ;;
            # 3)
            2)
                printRed "Quit."
                break
                ;;
            *)
                printRed "Error: Unknown command."
                ;;
        esac
    done
}
