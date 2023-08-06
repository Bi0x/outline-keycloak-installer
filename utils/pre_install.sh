
getOutlineDataPath() {
    echo $(getInstallScriptFilePath)/outline-data
}

getUserConfigJsonPath() {
    echo $(getInstallScriptFilePath)/user-config.json
}

preCheckProcess() {
    # Check user-config.json is exists.
    if [ ! -f $(getUserConfigJsonPath) ]; then
        printRed " No user-config.json found! Please read README.md!"
        exit 1
    fi

    # bash command dependencies
    needCommands=("curl" "jq" "docker" "docker-compose" "md5sum" "head" "base64")
    # Check all commands are exist.
    for perCommand in "${needCommands[@]}"
    do
        if ! [ -x "$(command -v $perCommand)" ]; then
            printRed "Error: $perCommand is not installed! Stopping..."
            exit 1
        fi
    done

    # Make temp dir
    if [ ! -d $(getOutlineDataPath) ]; then
        printRaw " Making outline data directory..."
        mkdir $(getOutlineDataPath)
    fi

    # Pre check pass
    printRaw " Pre-check pass. "
}
