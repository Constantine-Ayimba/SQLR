#!/usr/bin/python
from socket import AF_INET, socket, SOCK_STREAM
from threading import Thread
from subprocess import call
import sys,traceback
import time

def callate():
	"""Close on connect"""
	try:
		client, client_address = SERVER.accept()
		#print("%s:%s has connected." % client_address)

		SSN_VARS = str(client.recv(BUFSIZ).decode("utf8")) # ReqID + Client Port
		SSN_VARS = SSN_VARS.strip().split('\n')[0]
		if SSN_VARS=="callate!":
			time.sleep(30)
			call("sudo shutdown -f now",shell=True)
	except Exception, e:
		print("could not shutdown")

HOST = ''
PORT = int(sys.argv[1])
BUFSIZ = 1024
ADDR = (HOST, PORT)

SERVER = socket(AF_INET, SOCK_STREAM)
SERVER.bind(ADDR)

if __name__ == "__main__":
	try:
		SERVER.listen(10)
		print("Waiting for connection...")
		sys.stdout.flush()
		ACCEPT_THREAD = Thread(target=callate)
		ACCEPT_THREAD.start()
		ACCEPT_THREAD.join()
		SERVER.close()
	except:
		print("Could not connect.")
		sys.stdout.flush()
