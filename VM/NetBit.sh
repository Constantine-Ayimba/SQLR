#!/usr/bin/python
import hashlib, struct
from socket import AF_INET, socket, SOCK_DGRAM, SOCK_STREAM
from threading import Thread
from subprocess import call
from subprocess import check_output
import datetime
import random
import time
import sys
import os.path

loop_Times = int(sys.argv[1])*1000

def accept_incoming_connections():
	"""Sets up handling for incoming clients."""
	while True:
		client, client_address = SERVER.accept()
		start_At = int(round(time.time()*1000))
		sys.stdout.flush()
		Thread(target=handle_client, args=(client,start_At,client_address,)).start()
	
def handle_client(client,startTime,cltA):
	"""Handles a single client connection."""

	global loop_Times
	BUFSIZ = 1024
	ver = 2
	strPayload = client.recv(BUFSIZ).decode("utf8")
	strHost = str(cltA[0])
	client.close()
	cAddr = strPayload[:strPayload.index(";")]
	cPort = strPayload[(strPayload.index(";")+1):strPayload.index(":")]
	REQID = strPayload[strPayload.rfind(":")+1:strPayload.index("#")]
	ReqTimeStamp = strPayload[strPayload.rfind("#")+1:]
	
	prev_block = '%064x' % random.randrange(16**48)
	mrkl_root = '%064x' % random.randrange(16**64)
	time_ = int(round(time.time()))
	bits = 0x19015f53
	
	nonce = 0
	while nonce < 0x100000000:
		header = ( struct.pack("<L", ver) + prev_block.decode('hex')[::-1] + mrkl_root.decode('hex')[::-1] + struct.pack("<LLL", time_, bits, nonce))
		hash = hashlib.sha256(hashlib.sha256(header).digest()).digest()
		if nonce >= ((int(REQID)*1e5)+3e5): #hash[::-1].encode('hex')[:4] == '0000':
		#if nonce >= loop_Times: #hash[::-1].encode('hex')[:4] == '0000':
		#if hash[::-1].encode('hex')[:5] == '00000':
			#print str(int(round(time.time()*1000))),nonce,hash[::-1].encode('hex'),str(int(round(time.time()*1000))-startTime)
			#val_CPU = round(float(check_output("tail -1 " + str(datetime.datetime.now().strftime ("%Y%m%d")) + "_res_util_smoothed | awk '{print $1}'",shell=True).replace('\n', '')),2)
			str_Stream =  "echo " + str(int(round(time.time()*1000))) + " " + str(nonce) + " " + str(int(round(time.time()*1000))-startTime) + " >> " + str(datetime.datetime.now().strftime ("%Y%m%d")) + "_HashTimes"
			call(str_Stream,shell=True)
			break
		nonce += 1
	sock = socket(AF_INET, SOCK_DGRAM)
	server_address = (cAddr, int(cPort))
	message = str(nonce) + " " + hash[::-1].encode('hex') + "\n"
	print message 

	sent = sock.sendto(message, server_address)
	PORT = 37000+(random.randint(0,10))
	BUFSIZ = 1024
	ADDR = (strHost, PORT)
	strPayload = "1000"
        try:
                client_socket = socket(AF_INET, SOCK_STREAM)
                client_socket.connect(ADDR)

		#strPayload = client_socket.send(bytes(ReqTimeStamp+":"+cAddr+":"+cPort+":"+REQID))
		ST_Low = (int(round(time.time()*1000))-startTime)/float(nonce)
		strPayload = client_socket.send(bytes(ReqTimeStamp+":"+cAddr+":"+cPort+":"+str(ST_Low)))
                client_socket.close()
        except:
                print("Error in connection")
        else:
                print strPayload
                client_socket.close()

	#client.send(bytes(str(nonce) + " " + hash[::-1].encode('hex') + "\n"))
	#client.close()
	
HOST = ''
PORT = int(sys.argv[2])
BUFSIZ = 1024
ADDR = (HOST, PORT)
SERVER = socket(AF_INET, SOCK_STREAM)
SERVER.bind(ADDR)

if __name__ == "__main__":
	SERVER.listen(1)
	print("Waiting for connection...")
	ACCEPT_THREAD = Thread(target=accept_incoming_connections)
	ACCEPT_THREAD.start()
	ACCEPT_THREAD.join()
	SERVER.close()
