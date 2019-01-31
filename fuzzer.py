#!/usr/local/bin/python2
import os
import time
import sys
import subprocess
import threading

HWINT = 0
ADDB = 1
TWOB = 2
EAH = 3
FFH = 4
SIXTHREE = 5
SEVENNINE = 6
HALT = 7
OUTSIDE_RAMROM = 8

" Function to read output from Qemu "
class read_line_helper:
    def __init__(self, pipe):
        self.pipe = pipe
        self.msg = None

    def timer(self):
        st = time.time()
        while not self.msg:
            tt = time.time()
            if ((tt - st) > 5):
                break

    def do_read(self):
        try:
            self.msg = self.pipe.stdout.readline()
        except Exception as err:
            print(err)
            pass

    def read(self):
        threading.Thread(target=self.do_read).start()
        self.timer()
        return self.msg

def read_line(pipe):
    rh = read_line_helper(pipe)
    return rh.read()

" Functionality to check output of qemu-system-TARGET "
issue_idents = [[HWINT, "Servicing hardware INT"],
        [ADDB, "00 00", "addb"],
        [TWOB, ".byte", "0x2b"],
        [EAH, ".byte", "0xea"],
        [FFH, ".byte", "0xff"],
        [SIXTHREE, ".byte", "0x63"],
        [SEVENNINE, ".byte", "0x79"],
        [HALT, "hlt"],
        [OUTSIDE_RAMROM, "Trying to execute code outside"]
        ]

def check_out(s):
    for line in issue_idents: 
        if (len(line) == 3):
            if ((line[1] in s) and (line[2] in s)):
                return line[0]
        else:
            if (line[1] in s):
                return line[0]
    return None

" Functionality to generate payload "
def genpayload():
    print(" *** Generating random payload...")
    os.system("dd if=/dev/urandom of=test count=16000")

    print(" *** Assembling skeleton bootloader...")
    os.system("make")

    print(" *** Adding payload to skeleton...")
    os.system("cat test >>bin/Nyanix")

    print(" *** Malicious bootloader generated :)")

" Check if qemu is running "
def qemu_not_running():
    d = os.popen("ps aux | grep -v grep | grep qemu").read()
    if ("qemu-system" not in d):
        return 1
    else:
        return None

" Kill all remaining qemu-processes "
def kaqp():
    os.system("kill -9 `ps aux | grep qemu | grep -v grep | awk '{print $2}'`>/dev/null 2>&1")

" Functionality to Fuzz "
def run_fuzzer():
    while True:
        try:
            time.sleep(5)
            genpayload()
            
            print(" *** Running...")

            pipe = subprocess.Popen(["make", "qemu"],
                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

            looping     = 0
            hwint_cnt   = 0
            null_cnt    = 0
            restart     = 0
            clean_crash = 0

            while (looping < 200 and
                    hwint_cnt < 100 and
                    null_cnt < 4000 and
                    restart == 0):
                output = []
                for i in range(5):
                    r = read_line(pipe)
                    if (not r):
                        restart = 1
                    rstat = check_out(r)
                    if (rstat == HWINT):
                        hwint_cnt += 1
                    if (rstat == ADDB):
                        null_cnt += 1
                    if (rstat == TWOB):
                        restart = 1
                    if (rstat == FFH):
                        restart = 1
                    if (rstat == EAH):
                        restart = 1
                    if (rstat == SIXTHREE):
                        restart = 1
                    if (rstat == SEVENNINE):
                        restart = 1
                    if (rstat == HALT):
                        restart = 1
                    if (rstat == OUTSIDE_RAMROM):
                        clean_crash = 1
                        restart = 1
                    sys.stdout.write(r)
                    sys.stdout.flush()

            print("-" * 50)
            print(" *** Code looped %d instructions" % looping)
            print(" *** Triggered %d hardware interrupts" % hwint_cnt)
            print(" *** Null count: %d" % null_cnt)
            print(" *** restart: %d" % restart)
            print(" *** Waiting 5 seconds to see if we caused a crash or not")
            time.sleep(5)

            if (qemu_not_running()):
                if (clean_crash == 0):
                    print(" *** Crashed Qemu :) ")
                    break
                else:
                    print(" *** Clean crash due bad code :(")
            else:
                print(" *** No crashes :( Continuing...")
            kaqp()
        except KeyboardInterrupt:
            d = raw_input("\n\n *** Exit? y/N")
            if (d == "y" or d == "Y"):
                kaqp()
                break


run_fuzzer()
