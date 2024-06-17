#/bin/bash

echo "RPU last wrote" $(devmem 0x46D00200 32) ", last read" $(devmem 0x46D00204 32)
echo "RISCV last wrote" $(devmem 0x46D01200 32) ", last read" $(devmem 0x46D01204 32)
ps | grep read_shm
