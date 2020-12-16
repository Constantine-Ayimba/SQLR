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
        Thread(target=handle_client, args=(client,client_address,)).start()


def handle_client(client,cltAdd):  # Takes client socket as argument.
    """Handles a single client connection."""
    proc_Stats = check_output(['./getCPU.sh'])
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

