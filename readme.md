# RISC-V UART Debugger #

### About ###
Control and debug a RISC-V MCU over USB UART.

Configured by default for a 50 MHz CPU communicating with a baud rate of 115200. This can be adjusted by changing the BAUD definion in client/src/serial.h and the serial\_driver instantiation in module/design/mcu\_controller.sv.

### Installation ###

The best way is to build and install from source:

```
git clone git@github.com:trmckay/riscv-uart-debugger.git; cd riscv-uart-debugger; ./install; cd ..
```

You can also use one of the prebuilt releases if this does not work.

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
