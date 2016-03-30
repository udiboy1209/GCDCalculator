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

def rng(a,b):
    l = [];
    for i in range(4):
        q = int(random()*500)
        l.append(q*a)
        q = int(random()*500)
        l.append(q*b)
    pr(l)

rng(20,15)
rng(80,74)
rng(30,45)
rng(26,39)
rng(117,91)
