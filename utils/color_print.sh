printGreen() {
    echo -e "\e[1;32m $1 \e[0m"
}

printRed() {
    echo -e "\e[1;31m $1 \e[0m"
}

printRaw() {
    echo "    $1"
}

printRawSameline() {
    echo -n "    $1"
}
