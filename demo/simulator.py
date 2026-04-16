import socket
import time
import random
from fall_generator import generate_fall,generate_normal

HOST = "127.0.0.1"
PORT = 9000

client = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
client.connect((HOST,PORT))

print("Connected to server")

while True:

    if random.random() < 0.1:
        segment = generate_fall()
    else:
        segment = generate_normal()

    for row in segment:
        print("Sending:",row)
        line=",".join(map(str,row))+"\n"

        client.send(line.encode())

        time.sleep(0.1)   # 50Hz