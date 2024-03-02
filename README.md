# SYCL 2024 PCB Badge

## Getting Started

Temporarily this repo targets the `zig-master` branch of
[MicroZig](https://github.com/ZigEmbeddedGroup/microzig). In order to build this
repo, you must have it checked out, and `microzig` next to `sycl-badge-2024` in
your filesystem. Once this branch is merged it won't be as janky to build this
firmware.


## Uploading firmware using a debugger

```
target extended-remote /dev/ttyACM{first}

monitor swd_scan # searches for device
attach 1
file zig-out/firmware/pybadge-io.elf
 
```

## Updating Black Magic Probe firmware

```
sudo dfu-util -a 0 --dfuse-address 0x08000000:leave -R -D ~/Downloads/blackmagic-firmware-v1.10.0-rc1/blackpill-f401cc/blackmagic-blackpill-f401cc.bin ^C
```
