## home_projects

This repo tracks my home projects, scratch work and notes in the read me as I go. Hopefully will become mroe organized as it matures

## build root:

## Development Notes
arty chip: xc7a35tcsg324-3 (active)

[xadc dt](https://github.com/Xilinx/linux-xlnx/blob/master/Documentation/devicetree/bindings/iio/adc/xilinx-xadc.txt)

[xadc iio device driver](https://github.com/Xilinx/linux-xlnx/blob/master/drivers/iio/adc/xilinx-xadc-core.c) 

1.	used little endiam microblaze axi architecture
	* least significant byte is stored at the lowest address
	* data    0x 12 34 56 78
	* address[0x 03 02 01 00 ]
	* axi agnostic to endianess

2.	be aware of linux kernel headers version when writing a kernel driver for avaialble system function calls 
3. static libraries vs shared:
	1. Stati linked at compile time, no external dependencies in executable, watch out for large executables and need for recompilation
	2. Shared linked at runtime, depends on .so file being installed on system. Watch out for dll hell, version dependency problems
4. Use busybox init system to build in essential linux commands but keep the build lightweight

## Buildroot notes
1. make BR2_DEFCONFIG=configs/arty_mb_board_defconfig defconfig
	* add custome defconfig to .config
2. make sure menuconfig-->toolchain-->toolchain path is set for your preinstalled external toolchain path, even if its in the defconfig?
3. dont use xilinx microblaze compiler, its missing kernel headers, use buildroot toolchain and set to microblaze architecture

## General Notes
1. What happens before main:
	* Main is the entry point for your program, but a lot happens before entering the program and running
2. Reentrant vs non reentrant function
3. Who is making the device tree? How does the device tree compile from .xsa?
4. Kernel driver development vs user space programs that interact with hardware through the kernel driver
5. Think of a list of challengin problems and how you handled them
6. Think of times when ambiguous requirements or task definitions came up and how you worked through them
7. Lattice ecp5


## Linux commands as they Come to Mind
	1. scp
	2. screen
	3. ssh
	4. grep
	5. history
	6. apt install
	7. time
	8. sudo 
	9. where
	10. tar 
	11. sftp
	12. systemctl
		* systemd init commands
	13. mv
	14. cp
	15. vi
	16. vim
	17. ifconfig
	18. ip 
	19. find
	20. dtc
	21. cat
	22. ls
	23. lsblk
	24 uname -m (architecture report)

## Device Drivers
	1. I2C
	2. SPI
	3. USB.
	4. IIO


## Kernel Module Example

	#include <linux/module.h>
	#include <linux/kernel.h>

	static int __init hello_init(void) {
	    printk(KERN_INFO "Hello, kernel!\n");
	    return 0;
	}

	static void __exit hello_exit(void) {
	    printk(KERN_INFO "Goodbye, kernel!\n");
	}

	module_init(hello_init);
	module_exit(hello_exit);
	MODULE_LICENSE("GPL");

	static struct i2c_driver si5341_driver = {
	.driver = {
		.name = "si5341",
		.of_match_table = clk_si5341_of_match,
	},
	.probe		= si5341_probe,
	.remove		= si5341_remove,
	.id_table	= si5341_id,
    };
    module_i2c_driver(si5341_driver);
    
    MODULE_AUTHOR("Mike Looijmans <mike.looijmans@topic.nl>");
    MODULE_DESCRIPTION("Si5341 driver");
    MODULE_LICENSE("GPL");

