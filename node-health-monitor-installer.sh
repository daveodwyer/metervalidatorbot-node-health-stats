#!/bin/bash

# outputAscii outputs the ascii text
function outputAscii() {

echo "                        ..
                       =.:=
                       +===
                        =:
                        +=
                        #+
                        #*
                 :-=+:..**..-+=-.
             ::+#%=-::.. ..::--+%%-::
          .::::-#%+=-:::..:::-=*##:::::.
        ::::::::::.:---:-::---:::::::::::.
      .:::::::::::::.:..:....::::::::::::::
     :::::::::::........:........:::::::::::.
  .%@*::::::::..........:..........::::::::-#@#
  %@@@+::::::...........:...........:::::::*@@@#
 -%%@@#::::.............:.............:::::%@%%%
 +%%%@%:::..............:..............:::=@@%%#:
 *#%%@%:::....:::....   .   .....:::...:::+@@%%#:
 *%%%@%::...@@@@@@@#    .     %@@@@@@@...:=@@%%#:
 -%%@@#::.*@*+.  :+%@:  .   -@#+:  .+#@+::-@@%%%.
  %@@@+::=@+========*@. .  .@*=-===-==+@-::#@@%%
  :@@#:::@#=--::::-==@= .  +@==-::::--=%@::=%@@
    :::::@%=-:....:-=@= .  =@=-:....:-=%@::::
      .::-@=-:....:-#@  .  .@#-:.. .:-+@:::.
        :.=@#-::::=%@.  .   :@#-::::-#@=:.
          ..*@@@@@%-..  :   ..=%@@@@@*..
            ............:............
                 .......:.........
                 -+@@########@@=-
             .#%%-+@@@@%##%@@@@+-%%#
             %@%+:*.-+######+-:*-*%@%
            @@@@:.    *@@@@=    :-%@@@.
          ..:-:-:   #%:    -@*  .:-.-:..
         :--=+ ... %+        *# -:. +=--:
     . .:-+*** ..:-%  *@ #%= +=.=:: +**+-:. .
    : .:-+***+ :.:*-=%%@#:@#: @-=:: =***+-:. :
   :=@%@%%%*#: :-::-  .       @.-::  #*#%@@@%*:
   %@====#@%*  :*. *#        %= :+-  +%@%====@%
   =.::----%   .*   :@%:..:%%.  .*.   #----::.=
   .::-@@@=:     .     :==.     .     .-@@@=::.
   .::=@@@*-       +--......-=-       :+@@@+::.
   .::-%**-        .@%%%@%%%%@         -+*%-:..
     -#::.           =%%%%%%.           .::+=
                     .*%%%%-
                  ::::::::::::::
                   ..::::::::.

"

}

outputAscii

dockerHubImage="dewire/metervalidatorbot-node-health:latest"
bot_domain='https://bot.metervalidatorbot.com'

echo "Running pre-liminary checks..."

if [[ $(which docker) && $(docker --version) ]]; then
  echo "Docker is present..."
else
  echo "Docker cannot be found. This tool is designed to work with Meter mainnet nodes. Please install a node on this system before running this tool"
  exit
fi

docker ps | grep "meterio\/mainnet:latest" > /dev/null 2>&1

if [ $? -eq -0 ]; then
  echo "Meter Node image present and running..."
else
  echo "meterio/mainnet:latest docker container image does not appear to be running on this system. Exiting."
  exit
fi

# request to confirm that the server installing the docker image is a valid Meter Validator
isMeterValidator=$(wget --spider -S "$bot_domain/validator-status" 2>&1 | grep "HTTP/" | tail -1 | awk '{print $2}')
if [[   ${isMeterValidator} -eq 200 ]]; then
        echo "This node is a valid Meter Validator..."
elif [[ ${isMeterValidator} -eq 500 ]]; then
        echo "There is an issue with the bot. Please highlight this error in Meter Validators Telegram group"
        exit
else
        echo "This node is not a valid Meter Validator. This script can only be used on a valid Meter Validator node/server."
        exit
fi

# request to confirm that the server is linked to a registered Telegram User with MeterValidatorBot
isLinkedWithBot=$(wget --spider -S "$bot_domain/linked-status" 2>&1 | grep "HTTP/" | tail -1 | awk '{print $2}')
if [[   ${isLinkedWithBot} -eq 200 ]]; then
        echo "You have already linked with MeterValidatorBot..."
elif [[ ${isLinkedWithBot} -eq 500 ]]; then
        echo "There is an issue with the bot. Please highlight this error in Meter Validators Telegram group"
        exit
else
        echo "You are not linked with the Telegram bot."
        registrationString=$(wget -q -O - "$bot_domain/registration-req" 2>&1)
        echo "Open the following link in your browser and click the 'start' button once redirected to Telegram. This will link your Telegram account with your node and the bot: https://t.me/MeterValidatorBot?start=${registrationString}"
        echo "You can re-run the script after you've successfully linked"
        exit
fi

read -p 'You can define how often, in minutes, node health stats are logged. Leave blank for default [5]:' poll_interval
if [[ -z $poll_interval ]]; then
        poll_interval=5
fi

echo "Node health stats will be logged every ${poll_interval} minutes..."

source <(grep -m 1 "METER_MAIN_DATA_PATH" ~/.bashrc )

docker pull ${dockerHubImage}

# check to see if a previous version is present
docker container stats --no-stream meter_val_bot_node_health > /dev/null 2>&1
if [ $? -eq -0 ]; then
        echo "Previous image exists... Uninstalling..."
        docker container rm meter_val_bot_node_health --force > /dev/null 2>&1
fi

echo -e "Beginning installation..."

# If swap is not configured on the host, docker will pass a warning message back to the console when we restrict
# the amount of memory that the container can use. This message might be alarming to new users. Passing in -1 as the
# memory-swap flag value prevents the message appearing (-1 is the default if swap is not enabled on the host).
passMemorySwapOption=''

# format the below to JSON so that we can grep the output
dockerInfoNoSwapLimit=$(docker info --format='{{json .}}' | grep "No swap limit")
if [[ $? -eq -0 ]]; then
  passMemorySwapOption="--memory-swap=-1"
fi

# initialise the container
dockerRun=$(docker run --name meter_val_bot_node_health -e METER_MAIN_DATA_PATH="${METER_MAIN_DATA_PATH}" -e MVB_POLL_INTERVAL=${poll_interval} -v ${METER_MAIN_DATA_PATH}:${METER_MAIN_DATA_PATH}:ro --restart always --log-opt max-size=20M --cpus=".01" --memory=32M ${passMemorySwapOption} -d ${dockerHubImage})

if [[ $? -eq -0 ]]; then
        echo "Installation complete. MeterValidatorBot will message you shortly!"
else
        echo $dockerRun
        echo "Error occurred. Please examine above output. If you require assistance please reach out in the Meter Validators Telegram group"
fi

exit