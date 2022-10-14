import os
import time
from datetime import datetime

import requests
from requests.exceptions import HTTPError
import psutil as psu


# This function utilizes psutil to obtain system information before sending it to the bot
def system_info(poll_interval_seconds):

    # object containing system data
    system_data = {
        "boot_time": int(psu.boot_time()),
        "cpu_perc": f"{psu.cpu_percent(1)}",
        "mem_perc": f"{psu.virtual_memory().percent}",
        "meter_disc_free": f"{psu.disk_usage(meter_data_location).free / (float(1 << 30)):,.3f} GiB",
        "root_disc_free": f"{psu.disk_usage('/').free / (float(1 << 30)):,.3f} GiB"
    }

    request_failure = False
    try:
        response = requests.post(full_api_url, system_data)
        response.raise_for_status()
    except HTTPError as http_err:
        print(f'HTTP error occurred: {http_err}')
        request_failure = True
    except Exception as err:
        print(f'Other error occurred: {err}')
        request_failure = True

    if request_failure:
        # sleep for 5 minutes if there is an error with the request
        print(f'Request error has occurred at ' + datetime.now().strftime("%m/%d/%Y, %H:%M:%S"))
        print(f'Halting further requests for 15 minutes due to above error...')
        time.sleep(60 * 15)
        print(f'Re-attempting connection now at ' + datetime.now().strftime("%m/%d/%Y, %H:%M:%S") + '...')
    else:
        # sleep for poll interval duration
        time.sleep(poll_interval_seconds)


# initialize
if __name__ == '__main__':

    bot_domain = 'https://bot.metervalidatorbot.com'

    api_version = '1.0.0'

    api_endpoint = '/system-update?v=' + api_version

    full_api_url = bot_domain + api_endpoint

    meter_data_location = os.environ.get('METER_MAIN_DATA_PATH', '/')

    # default poll interval is 5 minutes, but can be overwritten with environment variable passed in
    poll_interval_in_minutes = int(os.environ.get('MVB_POLL_INTERVAL', 5))

    # convert to seconds
    poll_interval_in_seconds = poll_interval_in_minutes * 60

    print(f'Health monitor starting at ' + datetime.now().strftime("%m/%d/%Y, %H:%M:%S"))

    while True:
        system_info(poll_interval_in_seconds)
