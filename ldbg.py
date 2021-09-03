#!/usr/bin/env python3
# from 6.string
arr = list(bytes.fromhex(input()))

import os

pcquant = 1
lc = 0
pc = 0x200028 - pcquant
i = 0
while i < len(arr):
    oldlc = lc
    oldpc = pc
    val = arr[i]
    i += 1
    if val == 0:
        lc += int.from_bytes(arr[i : i + 4], byteorder="big", signed=True)
        i += 4
    elif val < 65:
        lc += val
    elif val < 129:
        val -= 64
        lc -= val
    else:
        val -= 129
        val *= pcquant
        pc += val
    pc += pcquant
    print("---")
    print("pc: ", hex(pc))
    print("lc: ", lc)
    print("dlc: ", lc - oldlc)
    print("dpc: ", pc - oldpc)
