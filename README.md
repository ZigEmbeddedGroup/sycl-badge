# target extended-remote /dev/ttyACM{first}

# monitor swd_scan # searches for device
# attach 1
# file zig-out/firmware/pybadge-io.elf
# 

# $ sudo dfu-util -a 0 --dfuse-address 0x08000000:leave -R -D ~/Downloads/blackmagic-firmware-v1.10.0-rc1/blackpill-f401cc/blackmagic-blackpill-f401cc.bin ^C