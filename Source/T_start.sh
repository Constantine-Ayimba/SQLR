#!/usr/bin/python
from socket import AF_INET, socket, SOCK_STREAM
from threading import Thread
import sys

PORT = int(sys.argv[2])

BUFSIZ = 1024
ADDR = (str(sys.argv[1]), PORT)

#print(str(sys.argv[1]))
client_socket = socket(AF_INET, SOCK_STREAM)
client_socket.connect(ADDR)

SSN_VARS = str(sys.argv[3]) + ":" + str(sys.argv[4])

client_socket.send(bytes(SSN_VARS))
client_socket.close()
