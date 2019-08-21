# EFCAD

This EFCAD tool flow combines a chain of academic tools for building partially reconfigurable modules on lightweight embedded platforms.
The target platform is UltraZed with the latest 16nm UltraScale+ FPGAs tightly coupled with the 64-bit ARM CPUs in the same die of the Zynq UltraScale+ MPSoC device.

# Components
* Verilog synthesis by Yosys (https://github.com/YosysHQ/yosys)
* Placement and routing by nextpnr (https://github.com/YosysHQ/nextpnr)
* Architectural model generated initially by Xilinx Vivado tool and extracted by GoAhead
* Bitstream generation by BitMan (https://github.com/khoapham/bitman)
* OS Shell hosting the partially reconfigurable modules by ZUCL (https://github.com/zuclfpl/zucl_fsp)

# Acknowledgements
This is a part of our (Khoa Dang Pham and Malte Vesper) PhD projects in the University of Manchester, UK.
We would like to thank Xilinx University Program for software and board donations.

# Contacts
Any question, please send a message to Khoa Pham at khoa.pham@manchester.ac.uk
