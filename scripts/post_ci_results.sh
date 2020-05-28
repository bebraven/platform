# Alpine linux command:
#wget -qO - https://coverage.codacy.com/get.sh | sh -s report -r coverage/coverage.xml

# Bash
bash <(curl -Ls https://coverage.codacy.com/get.sh) report -r coverage/coverage.xml
