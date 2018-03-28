#!/usr/bin/env python3

import subprocess
import sys
import os
import time
import requests
import json
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
import random
from iperf3_config import *
import utils

def get_endpoint(url_cc, cert_path, key_path):
  r = requests.get('{0}/endpoint'.format(url_cc), cert=(cert_path, key_path), verify=False)
  if r.ok:
	  return r.json()
  else:
    return {}

def run_iperf_test(endpoint, port='9999', duration_seconds='2'):
	while True:
		res = subprocess.Popen(['iperf3', '-c', endpoint, '-p', port, '-t', duration_seconds, '-J'],stdout=subprocess.PIPE,stderr=subprocess.PIPE)
		output,error = res.communicate()
		if not res.returncode:
			print('[ {0} ] Got an output: {1}'.format(__file__, output.decode))
			break
		else:
			if 'error' in json.loads(output.decode()).keys():
				output = {}
				break
			else: 
				print('[ {0} ] Server busy, need rerun'.format(__file__))
				time.sleep(random.randrange(EXEC_DELAY_MIN, EXEC_DELAY_MAX, 3))
	return output

def send_iperf_data(url_cc, cert_path, key_path, payload):
	r = requests.post('{0}/iperf_data'.format(url_cc), cert=(cert_path, key_path), json=payload, verify=False)
	return r.json()

if __name__ == '__main__':

	# Lets wait for server to register us
	print('[ {0} ] Start delay for: {1}s'.format(__file__, EXEC_DELAY_MAX * 2))
	time.sleep(EXEC_DELAY_MAX * 2)
	
	fails_counter = 0
	while True:
		res = get_endpoint(URL_CC, CERT_PATH, KEY_PATH)
		print('[ {0} ] Next endpoint responce: {1}'.format(__file__, res))
		if 'endpoint' in res.keys():
			out = run_iperf_test(res['endpoint'])
			if not out:
				continue
		
			out_dict = json.loads(out.decode())
			print('[ {0} ] func run_iperf_test() out: {1}'.format(__file__, out_dict))

			r = send_iperf_data(URL_CC, CERT_PATH, KEY_PATH, utils.merge_two_dicts(out_dict, {'from_agent_ip': res['endpoint']}))
			print('[ {0} ] func send_iperf_data() response: {1}'.format(__file__, r))
			time.sleep(random.randrange(EXEC_DELAY_MIN, EXEC_DELAY_MAX, 3))
		else:
			fails_counter += 1
			print('[ {0} ] Failed attempts: {1}'.format(__file__, fails_counter))
			if fails_counter < FAILS_ALLOWED:
				time.sleep(random.randrange(EXEC_DELAY_MIN, EXEC_DELAY_MAX, 3))
			else:
				break



