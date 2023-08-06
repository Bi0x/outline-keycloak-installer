#!/bin/bash

getInstallScriptFilePath() {
    echo $(dirname $(realpath $0))
}


mainProcess() {

    # Get installer base path
    basePath=$(getInstallScriptFilePath)

    # Load colorful print
    colorPrintPath=$basePath/utils/color_print.sh
    source $colorPrintPath

    printGreen "> Pre-checking..."

    # Pre check
    preInstallPath=$basePath/utils/pre_install.sh
    source $preInstallPath
    preCheckProcess

    # Main install
    printGreen "> Installing..."
    mainInstallPath=$basePath/utils/main_install.sh
    source $mainInstallPath
    # mainInstallMenu
    mainInstallFromUserConfig
}


mainProcess
