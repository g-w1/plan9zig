# from 6.string
arr = [
    0x00,
    0x00,
    0x00,
    0x00,
    0x59,
    0x41,
    0x01,
    0x01,
    0x87,
    0x01,
    0x89,
    0x00,
    0xFF,
    0xFF,
    0xFF,
    0xA5,
    0x8D,
    0x00,
    0x00,
    0x00,
    0x00,
    0x5E,
    0x75,
    0x8B,
    0x1F,
    0x80,
    0x16,
    0x8B,
    0x01,
    0x83,
]

import os

pcquant = 1
lc = 0
pc = 0x200028 - pcquant
i = 0
while i < len(arr):
    oldlc = lc
    val = arr[i]
    i += 1
    if val == 0:
        lc += int.from_bytes(arr[i : i + 4], byteorder="big", signed=True)
        print(arr[i : i + 4])
        i += 4
    elif val < 65:
        lc += val
    elif val < 129:
        print(val)
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
