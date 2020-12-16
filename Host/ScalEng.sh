#!/usr/bin/python
from socket import AF_INET, socket, SOCK_STREAM
from threading import Thread
from subprocess import call
from subprocess import check_output
from collections import OrderedDict
import datetime
import time
import sys
import random
import math
import numpy as np, pandas as pd
import os
import os.path
import subprocess
import pickle

intStartAt = 2
if len(sys.argv) >1:
	intStartAt = int(sys.argv[1])


gamma = 0.8
alpha = 0.2
beta = -0.001 # -0.01
theta = 10.0 # 1.0
Pb_max = 0.001

SERVERS = {'VM_MAR_1':'192.168.122.2','VM_MAR_2':'192.168.122.3','VM_MAR_3':'192.168.122.5','VM_MAR_4':'192.168.122.7','VM_MAR_5':'192.168.122.11','VM_MAR_6':'192.168.122.13','VM_MAR_7':'192.168.122.17','VM_MAR_8':'192.168.122.19','VM_MAR_9':'192.168.122.23','VM_MAR_10':'192.168.122.29'}
Max_VM = len(SERVERS)

Max_Range = 5# Action space
action_arr=range(-int(math.floor(Max_Range/2.0)),int(math.ceil(Max_Range/2.0)))
visit_Lim = Max_Range*10;
epsilon_min = 0.0
epsilon = 1.0

FNULL = open(os.devnull, 'w')
K_Count = 0
VM_Names = check_output(['./getPOWs.sh'])
VM_ALT = VM_Names.strip().split('\n')

if os.path.isfile("ScalEng_Policy"):
	fleNme = 'ScalEng_Policy'
	fleIn = open(r''+fleNme+'', 'rb')
	df_QDF = pickle.load(fleIn)
	fleIn.close()
else:
	list_all = []
	for k in range(1,Max_VM+1):
		lista = []
		vmVal=(Max_Range-k) + math.ceil(Max_Range/2.0)
		if (vmVal <= Max_Range) and (vmVal >=0):
			for x in range(0,Max_Range):
				lista.append([np.zeros((16,16)),np.zeros((16,16))]) # 0-10,10-15,15
		elif vmVal > Max_Range:
			for x in range(0,(Max_Range-int(math.floor((Max_Range-k)/2.0)))):
				lista.append([np.zeros((16,16)),np.zeros((16,16))]) # 0-10,10-15,15
		elif vmVal<0:
			for x in range(0,((2*Max_Range-k)+int(math.ceil((Max_Range)/2.0)))):
				lista.append([np.zeros((16,16)),np.zeros((16,16))]) # 0-10,10-15,15
		list_all.append(lista)
	df_QDF = pd.DataFrame(data=list_all)

	#KNOWLEDGE ADDITION
	#Biasing the reference states with Q function probabilities
	ctx_cost = 0.0
	for x in range(0,Max_VM):
		ctx_cost = beta*x #(1 - (np.exp((0-x)/2.0)))
		block_cost = 0.001
		for k in range(0,16): # Ref. Threshold from Load Optimizer
			if k>=14: # Quantized Levels 0-20 (in 2's),20-45(in 5's),45-100
				erf_arg = (k-7)*np.exp(1)
				block_val = 0.5*(1.0 + math.erf(erf_arg/math.sqrt(2.0)))
				block_cost = theta*(Pb_max-block_val)

			vmVal=(Max_Range-(x+1)) + math.ceil(Max_Range/2.0)
			posRef = Max_Range/2
			if vmVal > Max_Range:
				posRef = x

			df_QDF.loc[x][posRef][0][k][k] = round(ctx_cost+block_cost,4)
			df_QDF.loc[x][posRef][1][k][k] = 1.0

strTimeStamp = str(int(round(time.time()*1000)))
call("echo " + strTimeStamp + " " + str(-1) + " " + str(-1) + " >> " + str(datetime.datetime.now().strftime ("%Y%m%d")) + "_ScalEng_Epsiloner",shell=True)
scaler=np.zeros(2)
r_x = 0
while True:
	if K_Count%10 == 0:
		fleNme = 'ScalEng_Policy'
		fleOut = open(r''+fleNme+'', 'wb')
		pickle.dump(df_QDF, fleOut)
		fleOut.close()

	K_Count += 1

	#Pick container box
	if K_Count > 1:
		VM_ALT = check_output(['./getReady.sh']).strip().split('\n')

	N_vm = int(check_output(['./getPOWCount.sh']).strip()) # len(VM_ALT) #int(check_output(['./getPOWCount.sh']).strip())
	print("N_vm = " + str(N_vm) + " @ " + str(strTimeStamp))

	keyCount = 0
	Value_Count = 0.0
	Counter_Val = 0
	vm_list = []
	vm_cpu = []
	while keyCount < len(VM_ALT):
		Elected_VM = SERVERS.get(VM_ALT[keyCount])
		print("VM Name is " + VM_ALT[keyCount])
		if VM_ALT[keyCount] in check_output(['./getPOWs.sh']).strip().split('\n'):
			try:
				cpu_val = check_output(['./checkStats3_reqCount.sh',str(Elected_VM),strTimeStamp]).strip().split()
				print("Elected_VM = " + Elected_VM + " @ " + str(cpu_val[0]) + " / " + str(cpu_val[1]))

				vm_list.append(VM_ALT[keyCount])
				vm_cpu.append(float(cpu_val[0])/int(cpu_val[1]))

				Value_Count += float(cpu_val[0])
				Counter_Val += int(cpu_val[1])
			except Exception, unExp:
				print("Error connecting to " + str(Elected_VM))
		keyCount += 1
	SUN_DOWNERS = dict(zip(vm_list,vm_cpu))
	SUN_DOWNERS = OrderedDict(sorted(SUN_DOWNERS.items(), key=lambda x: x[1]))
	sys.stdout.flush()

	cpu_state = 0
	if Counter_Val > 0:
		cpu_state = Value_Count/Counter_Val

	if round(cpu_state,1) < 20.0:
		sa_after = int(math.floor(cpu_state/2))
	elif round(cpu_state,1) < 45.0:
		sa_after = 10 + int(math.floor((cpu_state-20)/5))
	else:
		sa_after = 15

	#Get Q(S',A') coordinates
	Pb_now = float(check_output(['./getPastBlocking_reqCount.sh',strTimeStamp],stderr=FNULL).strip())
	Pb_now = round(Pb_now,4)
	print("Pb_now =" + str(Pb_now))

	if K_Count == 1:
		sa_b4 = sa_after

	posRef = Max_Range/2
	vmVal=(Max_Range-N_vm) + math.ceil(Max_Range/2.0)
	if vmVal > Max_Range:
		posRef = N_vm-1

	if K_Count > intStartAt:
		#REWARD PROCESS
		print("cpu_state = "+str(cpu_state)+", sa_after = "+str(sa_after))
		print("pickAct = "+str(pickAct)+", N_vm_b4 = "+str(N_vm_b4))

		prev_rx = r_x
		r_x = 0.001
		if Pb_now >= Pb_max:
			r_x = theta*(Pb_max-Pb_now) #Blocking probability component
		ctx_idx = (1-N_vm)/2.0
		r_x += beta*(N_vm-1) #(1 - (np.exp(ctx_idx))) #Context Switching component

		nCount = float(df_QDF.loc[(N_vm_b4-1)][pickAct][1][sa_b4_b4][sa_b4])
		df_QDF.loc[(N_vm_b4-1)][pickAct][1][sa_b4_b4][sa_b4] = (nCount+1.0)

		r_prime = r_x + gamma*(df_QDF.loc[(N_vm-1)][posRef][0][sa_after][sa_after])

		#UPDATE the right card in the correct box
		df_QDF.loc[(N_vm_b4-1)][pickAct][0][sa_b4_b4][sa_b4] = round(((r_prime-df_QDF.loc[(N_vm_b4-1)][pickAct][0][sa_b4_b4][sa_b4])/(nCount+1.0))+((nCount/(nCount+1.0))*(df_QDF.loc[(N_vm_b4-1)][pickAct][0][sa_b4_b4][sa_b4])),4)
		print("sa_b4,sa_after = " + str(sa_b4) + "," + str(sa_after))

	#Pick Card
	actRef = (Max_Range/2)-posRef
	vmVal=(Max_Range-N_vm) + math.ceil(Max_Range/2.0)
	posVal=Max_Range
	if vmVal<0:
		posVal=int(((2*Max_Range)-N_vm)+math.ceil(Max_Range/2.0))
	act_now = action_arr[actRef:posVal]

	x_sum = 0
	for x in range(0,len(act_now)):
		x_sum += df_QDF.loc[(N_vm-1)][x][1][sa_b4][sa_after]

	prev_epsilon = epsilon
	epsilon = 1-(x_sum/(visit_Lim+0.0))

	if round(epsilon,1) <= 0.0:
		epsilon = epsilon_min #0.001

	print("K_Count :" + str(K_Count))
	print("epsilon @" + str(epsilon))
	strTimeStamp = str(int(round(time.time()*1000)))
	if K_Count > intStartAt:
		call("echo " + strTimeStamp + " " + str(sa_b4_b4) + " " + str(sa_b4) + " " + str(N_vm_b4) + " " + str(prev_rx) + " " + str(prev_epsilon) + " >> " + str(datetime.datetime.now().strftime ("%Y%m%d")) + "_ScalEng_Epsiloner",shell=True)

	eps_act = int(np.concatenate((np.ones(int(round((1-epsilon)*1000))),np.zeros(int(round(epsilon*1000)))),axis=0)[np.random.randint(1000, size=1)[0]])
	print("eps Val = "+str(eps_act))
	sys.stdout.flush()
	callAct = 0

	if eps_act == 1:
		pickAct = 0
		if K_Count > 1:
			max_reward=-1000.00
			for x in range(0,len(act_now)):
				if df_QDF.loc[(N_vm - 1)][x][0][sa_b4][sa_after] > max_reward:
					pickAct = x
					max_reward = df_QDF.loc[(N_vm - 1)][x][0][sa_b4][sa_after]
			print("Acting GREEDILY pickAct = " + str(pickAct))
			call("echo " + strTimeStamp + " " + str(sa_b4) + " " + str(sa_after) + " " + str(N_vm) + " " + str(act_now[pickAct]) + " >> " + str(datetime.datetime.now().strftime ("%Y%m%d")) + "_ScalEng_PolMon",shell=True)
	else:
		x_act = np.zeros(len(act_now))

		abs_sum = 0.0
		for i in range(0,len(act_now)):
			abs_sum += abs(df_QDF.loc[(N_vm-1)][i][0][sa_b4][sa_after])

		if x_sum  > 0:
			for x in range(0,len(act_now)):
				x_act[x] = (1-np.tanh((df_QDF.loc[(N_vm-1)][x][1][sa_b4][sa_after]/x_sum)))*((df_QDF.loc[(N_vm-1)][x][0][sa_b4][sa_after])+abs_sum)

			print str(x_act)
		if sum(x_act) > 0:
			arr_Consider = np.concatenate([np.ones(int(round((x/sum(x_act)),3)*1000))*(i-1) for i,x in enumerate(x_act,1)])
		else:
			arr_Consider = range(0,len(act_now))

		pickAct = int(arr_Consider[np.random.randint(len(arr_Consider), size=1)[0]])
		print("Acting RANDOMLY pickAct = " + str(pickAct))

	callAct = act_now[pickAct]

	#*********************** DAMPING Addendum (Only Delayed draw down of resources)**********************************************
	strDamper=""
	if epsilon <= 0.001:
		if callAct>=0:
			scaler[0]=0
			scaler[1]=0
		else:
			scaler[0]=scaler[0]+1
			scaler[1]=0
			strDamper ="(Damping IN) "
			print "Scale IN directive " + str(scaler[0])
		#elif callAct>0:
		#        strDamper ="(Damping OUT) "
		#        scaler[1]=scaler[1]+1
		#        scaler[0]=0
		#        print "Scale OUT directive " + str(scaler[1])
	else:
		scaler[0]=0
		scaler[1]=0

	if scaler[0]==1 or scaler[1]==1:
		callAct=0
		if N_vm>2:
			pickAct=2
		else:
			pickAct=(N_vm-1)

	#********************** END DAMPING Addendum ********************************************


	call("echo " + strTimeStamp + " " + str(sa_b4) + " " + str(sa_after) + " " + str(N_vm) + " " + str(act_now[pickAct]) + " >> " + str(datetime.datetime.now().strftime ("%Y%m%d")) + "_ScalEng_AllMon",shell=True)

	print(strDamper+"callAct = " + str(callAct))
	sys.stdout.flush()


	#Save priors, form coordinates of Q(S,A)
	N_vm_b4 = N_vm

	#Save third in line blocking for different traffic rate training
	sa_b4_b4 = sa_b4
	sa_b4 = sa_after

	All_VMS = check_output(['./getPOWs.sh']).strip().split('\n')
	if callAct > 0:
		scaler[1]=0
		while int(check_output(['./getPOWCount.sh']).strip()) < (callAct+N_vm):
			VM_Names = check_output(['./getPOWs.sh'])
			VM_ALT = VM_Names.strip().split('\n')
			ex_Name = list(set(SERVERS.keys())-set(VM_ALT))
			if len(ex_Name) > 0:
				VM_Name = ex_Name[0]
				print("Starting up node " + SERVERS[VM_Name])
				call("echo " + str(int(round(time.time()*1000))) + " 1 " + SERVERS[VM_Name] + " >> " + str(datetime.datetime.now().strftime ("%Y%m%d")) + "_ScalEng_Events",shell=True)
				call(['./habla_mas.sh',VM_Name])

				All_VMS = list(set(All_VMS) | set([VM_Name]))
	elif callAct < 0:
		scaler[0]=0
		counter = 0
		while (counter < abs(callAct) and counter < len(SUN_DOWNERS)):
			print("Shutting down Node " + SERVERS[SUN_DOWNERS.keys()[counter]])
			call("echo " + str(int(round(time.time()*1000))) + " 0 " + SERVERS[SUN_DOWNERS.keys()[counter]] + " >> " + str(datetime.datetime.now().strftime ("%Y%m%d")) + "_ScalEng_Events",shell=True)
			call(['./hablo_callate.sh',SERVERS[SUN_DOWNERS.keys()[counter]]])
			All_VMS = list(set(All_VMS) - set([SUN_DOWNERS.keys()[counter]]))
			counter += 1

	sys.stdout.flush()

	All_VMS = list(dict.fromkeys(All_VMS))

	call(['./commitActive.sh','0'])
	call(['./commitActive.sh','0'])

	for vm in set(All_VMS):
		call(['./commitActive.sh',vm])

	sys.stdout.flush()
	#sleep_val = 90
	sleep_val = 0
	if callAct != 0:
		sleep_val += 30+(abs(callAct)-1)*2

	time.sleep(sleep_val)
	strTimeStamp = str(int(round(time.time()*1000)))
	time.sleep(60)
