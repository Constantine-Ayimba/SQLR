#!/usr/bin/python
from socket import AF_INET, socket, SOCK_STREAM
from threading import Thread
from subprocess import call
from subprocess32 import check_output
from random import shuffle

import os
import os.path
import datetime
import time
import sys,traceback
import random
import math
import numpy as np, pandas as pd
import pickle

K_Count = 0
if os.path.isfile("LBAC_Policy"):
	fleNme = 'LBAC_Policy'
	fleIn = open(r''+fleNme+'', 'rb')
	QAT_Live=pickle.load(fleIn)
	fleIn.close()
else:	
	QAT = data=np.zeros((4,5))
	QAT_Live = pd.DataFrame(data=QAT)

gamma = 0.8
alpha = 0.1
callAct = 0
cpu_thresh = 60.0 #%age
cpu_UBound = 60.0 #%age
epsilon = 1.0
def accept_incoming_connections():
	global SERVERS
	global QAT_Live
	global K_Count
	global epsilon
	global gamma
	global alpha
	global callAct
	global cpu_thresh
	global cpu_UBound	
	visit_Lim = 500
	while True:
		try:
			client, client_address = SERVER.accept()
			#print("%s:%s has connected." % client_address)

			SSN_VARS = client.recv(BUFSIZ).decode("utf8") # ReqID + Client Port
			client.close()
			Reqs = client_address[0]+";"+SSN_VARS+"#"+str(client_address[1])

			#client.send(bytes("connected to Host\n"))
			#client.close()
			VM_ALT = check_output(['./getReady.sh']).strip().split('\n')
			shuffle(VM_ALT)

			strTimeStamp = str(int(round(time.time()*1000)))
			Reqs = client_address[0]+";"+SSN_VARS+"#"+strTimeStamp

			call("echo " + strTimeStamp + " " + str(client_address[0]) + " " + str(client_address[1]) + " >> " + str(datetime.datetime.now().strftime ("%Y%m%d")) + "_petitio",shell=True)

			blnAdded = False
			keyCount = 0
			if K_Count == 0:
				call("echo " + strTimeStamp + " " + str(K_Count) + " " + str(epsilon) + " >> " + str(datetime.datetime.now().strftime ("%Y%m%d")) + "_Epsiloner",shell=True)
			K_Count += 1


			if epsilon > 0.0:
				fleNme = 'LBAC_Policy'
				fleOut = open(r''+fleNme+'', 'wb')
				pickle.dump(QAT_Live, fleOut)
				fleOut.close()
				print("K_Count :" + str(K_Count))
				print("Epsilon :" + str(epsilon))

			callAct=0

			cpu_val = 1.0
			#check_list=check_output(['./getPOWs.sh']).strip().split('\n');
			Elected_VM = SERVERS[VM_ALT[0]]
			for x in VM_ALT:
				if x in check_output(['./getPOWs.sh']).strip().split('\n'):
					try:
						This_VM = SERVERS[x]
						util_nu = float(check_output(['./checkStats1.sh',This_VM],timeout=2).strip().split()[0])
						if util_nu < cpu_val:
							cpu_val = util_nu
							Elected_VM = This_VM
					except Exception, e:
						print("Couldn't connect to " + This_VM)
						print("ERROR " + str(e))

			#CURRENT STATE
			try:
				cpu_val = float(check_output(['./checkStats2.sh',str(Elected_VM)],timeout=3).strip().split()[0])
				s_a = QuantizeThis(cpu_val)
				print 'cpu_val b4 action='+str(cpu_val)+' level='+str(s_a)
				sys.stdout.flush()

				x_sum = sum(QAT_Live[QAT_Live.columns[s_a]][2:])
				epsilon = 1-(x_sum/(visit_Lim+0.0))
				if x_sum > visit_Lim:
					epsilon = 0

				eps_act = int(np.concatenate((np.ones(int(round((1-epsilon)*1000))),np.zeros(int(round(epsilon*1000)))),axis=0)[np.random.randint(1000, size=1)[0]])

				#CHOOSE ACTION
				if eps_act == 1: #Act greedily
					callAct = QAT_Live[QAT_Live.columns[s_a]][:2].idxmax()
					print("Acting GREEDILY callAct = " + str(callAct))
				else: #Act randomly
					x_act = np.zeros(2)
					abs_sum = sum([abs(x) for x in QAT_Live[QAT_Live.columns[s_a]][:2]])

					if x_sum > 0:
						for x in range(0,2):
							x_act[x] = (1-np.tanh((QAT_Live[QAT_Live.columns[s_a]][x+2])/x_sum))*((QAT_Live[QAT_Live.columns[s_a]][x])+abs_sum)
                                                if sum(x_act) > 0:
                                                        arr_Consider = np.concatenate([np.ones(int(round((x/sum(x_act)),3)*1000))*(i-1) for i,x in enumerate(x_act,1)])
                                                else:
                                                        arr_Consider = range(0,2)
					else:
						arr_Consider = range(0,2)

					callAct = int(arr_Consider[np.random.randint(len(arr_Consider), size=1)[0]])
					print("Acting RANDOMLY callAct = " + str(callAct))
			except Exception, unExp:
				print("Error connecting to " + str(Elected_VM))
				callAct = 0

			if callAct == 1:
				call("echo " + strTimeStamp + " " + str(client_address[0]) + " " + str(client_address[1]) + " >> " + str(datetime.datetime.now().strftime ("%Y%m%d")) + "_" + str(Elected_VM) + "_accepted",shell=True)
				call("echo " + strTimeStamp + " " + str(client_address[0]) + " " + str(client_address[1]) + " >> " + str(datetime.datetime.now().strftime ("%Y%m%d")) + "_accepted",shell=True)
				handle_client(Reqs,str(Elected_VM))
			else:
				call("echo " + strTimeStamp + " " + str(client_address[0]) + " " + str(client_address[1]) + " >> " + str(datetime.datetime.now().strftime ("%Y%m%d")) + "_rejected",shell=True)


			#NEXT STATE AFTER ACTION
			if round(epsilon,3) > 0.0:#1.0e-3:
			        cpu_val = float(check_output(['./checkStats2.sh',str(Elected_VM)],timeout=3).strip().split()[0])
			        s_aPrime = QuantizeThis(cpu_val)

			        print 'CPU_VAL ='+str(cpu_val)


			        cp_val = round((1-(0.5**(s_aPrime+callAct)))*cpu_thresh)
			        if (s_aPrime+callAct) == 4:
				        cp_val = cpu_UBound
			        elif (s_aPrime+callAct) == 5:
				        cp_val = 100.0

			        print 'cp_val ='+str(cp_val)
			        print 'epsilon='+str(round(epsilon,3))+' visits='+str(x_sum)

				#REWARD PROCESS
				r_x = ((cp_val-cpu_thresh)/100.0)
				if cp_val == cpu_UBound:
					r_x = ((cpu_thresh-cp_val)/100)
				elif cp_val > cpu_UBound:
					r_x = ((cpu_thresh-cp_val)/100)*2
				#reward_val = abs(r_x)/(np.exp(r_x)-1.0)
				#reward_val = reward_val**3
				r_x += (cpu_thresh/100)
				print 'r_x ='+str(r_x)

				refPos = 0
				if s_aPrime == s_a and callAct == 1:
					refPos = 1
				nCount = float(QAT_Live[QAT_Live.columns[s_a]][callAct+2])
				QAT_Live[QAT_Live.columns[s_a]][callAct+2] = (nCount+1.0)

				r_prime = r_x + gamma*(QAT_Live[QAT_Live.columns[s_aPrime]][refPos])

				#STATE ACTION UPDATE
				print 'Updating Q value table...'
				QAT_Live[QAT_Live.columns[s_a]][callAct] = round(((r_prime-QAT_Live[QAT_Live.columns[s_a]][callAct])/(nCount+1.0))+((nCount/(nCount+1.0))*QAT_Live[QAT_Live.columns[s_a]][callAct]),4)
                                call("echo " + strTimeStamp + " " + str(s_a) + " 0 " + str(QAT_Live[QAT_Live.columns[s_a]][0]) + " " + str(QAT_Live[QAT_Live.columns[s_a]][2]) + " " + str(int(x_sum+1)) + " >> LBAC_Learn_stats",shell=True)
                                call("echo " + strTimeStamp + " " + str(s_a) + " 1 " + str(QAT_Live[QAT_Live.columns[s_a]][1]) + " " + str(QAT_Live[QAT_Live.columns[s_a]][3]) + " " + str(int(x_sum+1)) + " >> LBAC_Learn_stats",shell=True)
		except Exception, e:
			print("Error encountered " + str(e))
			print '%'*60
			traceback.print_exc(file=sys.stdout)
			print '%'*60
			sys.stdout.flush()
def handle_client(REQPARAMS,Host_VM):  # Takes client socket as argument.
	"""Handles a single client connection."""
	try:
		portVals=33000+(random.randint(0,10))
		client_socket = socket(AF_INET, SOCK_STREAM)
		client_socket.connect((Host_VM,portVals))

		client_socket.send(bytes(REQPARAMS))
		client_socket.close()
	except:
		call("Could not connect to " + Host_VM + " >> " + str(datetime.datetime.now().strftime ("%Y%m%d")) + "_" + Host_VM + "_rejected",shell=True)
		print("Could not connect to " + Host_VM)
		sys.stdout.flush()
def QuantizeThis(CPU_Lim):
	global cpu_UBound
	QVal = 4
	if (CPU_Lim >= round((1-(0.5**(3)))*cpu_thresh)) and (CPU_Lim <= cpu_UBound):
		QVal = 3
	else:
		for n in range(0,3):
			QL = round((1-(0.5**n))*cpu_thresh)
			QH = round((1-(0.5**(n+1)))*cpu_thresh)
			if (CPU_Lim >= QL) and (CPU_Lim < QH):
				QVal = n
				break
	return QVal

HOST = ''
PORT = int(sys.argv[1])
EPS = float(sys.argv[2])
BUFSIZ = 1024
ADDR = (HOST, PORT)

SERVERS = {'VM_MAR_1':'192.168.122.2','VM_MAR_2':'192.168.122.3','VM_MAR_3':'192.168.122.5','VM_MAR_4':'192.168.122.7','VM_MAR_5':'192.168.122.11','VM_MAR_6':'192.168.122.13','VM_MAR_7':'192.168.122.17','VM_MAR_8':'192.168.122.19','VM_MAR_9':'192.168.122.23','VM_MAR_10':'192.168.122.29'}


All_VMS = check_output(['./getPOWs.sh']).strip().split('\n')
call(['./commitActive.sh','0'])
for vm in All_VMS:
	call(['./commitActive.sh',vm])

SERVER = socket(AF_INET, SOCK_STREAM)
SERVER.bind(ADDR)

if __name__ == "__main__":
	try:
		SERVER.listen(10)
		print("Waiting for connection...")
		sys.stdout.flush()
		ACCEPT_THREAD = Thread(target=accept_incoming_connections)
		ACCEPT_THREAD.start()
		ACCEPT_THREAD.join()
		SERVER.close()
	except:
		print("Could not connect.")
		sys.stdout.flush()
