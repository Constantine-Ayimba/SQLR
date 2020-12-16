#!/usr/bin/python
from socket import AF_INET, socket, SOCK_STREAM
from threading import Thread
import sys
import random

PORT = 43000

BUFSIZ = 1024
ADDR = (str(sys.argv[1]), PORT)

#print(str(sys.argv[1]))
strPayload = "1000"
try:
    client_socket = socket(AF_INET, SOCK_STREAM)
    client_socket.connect(ADDR)

    strPayload = client_socket.recv(BUFSIZ).decode("utf8")
    client_socket.close()
except:
    print("Error in connection")
else:
    print strPayload
    client_socket.close()
