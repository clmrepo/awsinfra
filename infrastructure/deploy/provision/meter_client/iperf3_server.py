#!/usr/bin/env python3

import iperf3
import requests
import json
from multiprocessing import Process
import time
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
from iperf3_config import *


# Getting instance attributes to properly register and later identify server
# minimal attrs: provider, region
def get_attributes(file_path):
	out = {}
	try :
		with open(file_path, 'rt') as f:
			for l in f:
				if '=' in l:
					out[l.split('=')[0].strip()] = l.split('=')[1].strip()
		f.close()
	except Exception as e:
		print('[ {0} ] exception: {1}'.format(__file__, e))
		out = {'data':'empty'}
	return out

def register_endpoint(url_cc, cert_path, key_path, payload):
	r = requests.post('{0}/endpoint'.format(url_cc), cert=(cert_path, key_path), verify=False, json=payload)
	if r.ok:
		return r.json()['register']
	else:
		return 'Endpoint down'

def iperf_server(ADDR, PORT): 
	server = iperf3.Server()
	server.bind_address = ADDR
	server.port = PORT
	server.verbose = True
	while True:
		server.run()


if __name__ == '__main__':
	
	p = Process(target=iperf_server, args=(ADDR, PORT,))
	p.start()
	#print(p.pid)
	print('[ {0} ] Iperf3 proc PID: {1}'.format(__file__, p.pid))

	attrs = get_attributes(ATTRIBUTES_FILE)
	payload = attrs.copy()
	print('[ {0} ] Sleeping now for {1} seconds'.format(__file__, EXEC_DELAY_MAX))
	time.sleep(EXEC_DELAY_MAX)

	registration_counter = 0
	while True:
		rc = register_endpoint(URL_CC, CERT_PATH, KEY_PATH, payload)
		print('[ {0} ] Endpoint registration attempt result: {1}'.format(__file__, rc))
		if registration_counter < REGISTRATION_LIMIT:
			time.sleep(REGISTRATION_INTERVAL)
			registration_counter += 1
		else:
			break

#

