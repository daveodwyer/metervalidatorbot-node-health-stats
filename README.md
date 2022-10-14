## About 

This Python script utilizes the psutils library to gather system data and forward it on to MeterValidatorBot for
parsing. Once installed, you can query MeterValidatorBot for node health stats such as CPU, RAM and disc usage using the
`/health` command.

The script has been designed to run inside a Docker container. The image is limited to 32 MB of RAM and, if supported by
the host, 32 MB of swappable memory. The CPU is limited to 1% per core. The max log size of the container has been set 
to 20 MB. These limits have been set to help prevent the container taking up resources should the official Meter node 
container require them.

## Notes
You cannot install the Docker image if the host is not a valid Meter Validator and linked with MeterValidatorBot. If you
have not linked the server with MeterValidatorBot, a Telegram link will be generated that you can use to complete the 
linking process.

Requests sent to the bot API end point 
by a server that is not a valid Meter Validator are ignored.

## Usage

To install the Docker image, execute the following command on the host machine:
```shell
bash <(wget -q -O - https://raw.githubusercontent.com/daveodwyer/metervalidatorbot-node-health-stats/development/node-health-monitor-installer.sh)
```
