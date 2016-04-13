from random import random

f = open('TRACEFILE.txt','w')

def gcd(a,b):
    while b!=0:
        tmp = b
        b = a%b
        a = tmp
    return a

def pr(a):
    q = gcd(a[0],a[1])
    for i in range(2,8):
        q = gcd(q,a[i])
    outstr = ''
    for x in a:
        outstr += '{:016b} '.format(x)
    outstr += '{:016b}\n'.format(q)
    f.write(outstr)

def rng(a):
    l = [];
    for i in range(8):
        q = int(random()*511)+1
        l.append(q*a)
    pr(l)

for i in range(1000):
    rng(int(random()*127)+1)
