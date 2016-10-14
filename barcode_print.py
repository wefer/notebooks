#!/usr/bin/env python
# encoding: utf-8

"""
We're using labels with size 25x13 mm
ZPL-format is set accordingly. 
"""

import socket
import time
from os import environ

#Varibles
TCP_IP = environ.get('ZEBRA_IP')
TCP_PORT = 9100
BUFFER_SIZE = 1024


def create_zpl(content):
  """
  Wrap content in EAN-8 zpl
  """
  zpl = """^XA^LL150
  ^FO20,20^BY2
  ^B8N,50,Y,N
  ^FD{}^FS
  ^XZ
  """.format(content)
  return zpl


def sendtoprint(tcp_ip, tcp_port, payload):
  """
  Send zpl-code to printer
  """
  s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
  s.connect((tcp_ip, tcp_port))
  time.sleep(1)
  resp = s.send(bytes(payload, 'utf-8'))
  time.sleep(1)
  s.close()
  return resp

def test():
    for i in range(10,15):
      content = '10000' + str(i)
      zpl = create_zpl(content)
      print('Sending code: {}'.format(zpl))
      r = sendtoprint(TCP_IP, TCP_PORT, zpl)
      print('Return code: {}'.format(r))


