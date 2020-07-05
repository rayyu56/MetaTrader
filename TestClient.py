import socket, numpy as np
import sys
import time


class socketclient:
    def __init__(self, address='', port=9090):
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.address = address
        self.port = port
        self.sock.connect((self.address, self.port))
        self.cummdata = ''



    def sendmsg(self,sym='CLEN20',barnums=20):
        self.cummdata = ''

#        while True:
        print('Sending Symbol.%s'%(sym))
        data=sym+','+str(barnums)
        data=bytes(data, 'utf-8')
        self.sock.sendall(data)
        print('Waiting to receive data.')
        i=0
        while True:
            data = self.sock.recv(1024)

            self.data = data.decode("utf-8")
            if not data:
                return
            print(i,self.data)
            i=i+1
#            return self.data

    def __del__(self):
        self.sock.close()

if __name__=='__main__':
    serv = socketclient('127.0.0.1', 9091)
    serv.sendmsg('CLEQ20',15)
    serv.sendmsg('CLEU20',45)
 #   serv.sendmsg('CLEV20',100)
    serv.sendmsg('EPU20',500)



    sys.exit(1)
    while True:
        msg = serv.sendmsg()
        time.sleep(5)