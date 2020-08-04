# RISC-V UART Debugger #

### About ###
Control and debug a RISC-V MCU over USB UART.

Configured by default for a 50 MHz CPU communicating with a baud rate of 115200. This can be adjusted by changing the BAUD definion in client/src/serial.h and the serial\_driver instantiation in module/design/mcu\_controller.sv.

### Installation ###

The best way is to build and install from source:

```
git clone git@github.com:trmckay/riscv-uart-debugger.git; cd riscv-uart-debugger; ./install; cd ..
```

### Usage ###
Launch the tool with
```
uart-db <device>
```
Your device is likely connected to /dev/ttyUSBX or /dev/ttySX.
Once in the tool, type 'h' or 'help' for more information.

### Updating ###
If you have previously installed the tool and still have the repository cloned, you can use the update script to install the latest version. If you don't have the repository still, just follow the installation instructions above, it will overwrite any previous versions.

### Protocol implementation ###
Documentation source be found [here](https://github.com/trmckay/pipeline-debugger/tree/master/doc). Build with pdflatex or your choice of LaTeX compiler. Prebuilt PDFs can also be found in the releases.

Implement the protocol as defined in the doc on your MCU. Then, add the proper constraints to
forward your UART tx/sx connections to the mcu\_controller module.

### Project Structure ###
```
9 directories, 27 files
.
├── client
│   ├── Makefile
│   └── src
│       ├── cli.c
│       ├── cli.h
│       ├── debug.c
│       ├── debug.h
│       ├── file_io.c
│       ├── file_io.h
│       ├── main.c
│       ├── serial.c
│       └── serial.h
├── doc
│   ├── Makefile
│   └── tex
│       ├── figures
│       │   ├── pipeline_db.drawio
│       │   └── pipeline_db.png
│       └── protocol.tex
├── Makefile
├── module
│   ├── design
│   │   ├── controller_fsm.sv
│   │   ├── mcu_controller.sv
│   │   ├── serial_driver.sv
│   │   ├── uart_rx.sv
│   │   ├── uart_rx_word.sv
│   │   ├── uart_tx.sv
│   │   └── uart_tx_word.sv
│   └── testbench
│       ├── constraints
│       │   └── serial_board_testbench.xdc
│       ├── ctlr_testbench.sv
│       ├── db_testbench.sv
│       ├── db_wrapper.sv
│       ├── serial_board_testbench.sv
│       ├── serial_testbench.sv
│       ├── sseg.sv
│       └── wcfg
│           ├── ctrlr_testbench_behav.wcfg
│           └── serial_testbench_behav.wcfg
└── readme.md
```
