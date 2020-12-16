#!/usr/bin/python
from socket import AF_INET, socket, SOCK_STREAM
from threading import Thread
from subprocess import check_output
from subprocess import call
import datetime
import time
import sys

def accept_incoming_connections():
	"""Sets up handling for incoming clients."""
	while True:
		client, client_address = SERVER.accept()
		print("%s:%s has connected." % client_address)
		sys.stdout.flush()
		LookBackWindow = client.recv(BUFSIZ).decode("utf8")
		Thread(target=handle_client, args=(client,LookBackWindow,)).start()

def handle_client(client,LBK):  # Takes client socket as argument.
	"""Handles a single client connection."""
	#proc_Stats = check_output(['./getCPU_Utils.sh',str(LBK)])#interval based
	proc_Stats = check_output(['./getCPU_Utils_reqCount.sh',str(LBK)])#Event driven, at least 50 requests
	client.send(bytes(proc_Stats))
	client.close()

HOST = ''
PORT = int(sys.argv[1])
BUFSIZ = 1024
ADDR = (HOST, PORT)

SERVER = socket(AF_INET, SOCK_STREAM)
SERVER.bind(ADDR)

if __name__ == "__main__":
	SERVER.listen(10)
	print("Waiting for connection...")
	ACCEPT_THREAD = Thread(target=accept_incoming_connections)
	ACCEPT_THREAD.start()
	ACCEPT_THREAD.join()
	SERVER.close()
