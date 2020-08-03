# RISC-V Debugger and Controller #

### About ###
Control and debug a RISC-V MCU over USB. Works with any target that correctly implements the protocol and most Linux hosts.

Configured by default for a 50 MHz CPU communicating with a baud rate of 115200.

### Detailed implementation and protocol documentation ###
Documentation source be found [here](https://github.com/trmckay/pipeline-debugger/tree/master/doc). Build with pdflatex or your choice of LaTeX compiler. Prebuilt PDFs can also be found in the releases.

### Project Structure ###
```
.
├── client
│   ├── Makefile
│   └── src
│       ├── ctrlr.c
│       ├── ctrlr.h
│       ├── debug.c
│       ├── debug.h
│       ├── main.c
│       ├── serial.c
│       └── serial.h
├── doc
│   ├── figures
│   │   ├── pipeline_db.drawio
│   │   └── pipeline_db.png
│   └── protocol.tex
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
│       ├── serial_board_testbench.sv
│       ├── serial_testbench.sv
│       ├── sseg.sv
│       └── wcfg
│           ├── ctrlr_testbench_behav.wcfg
│           └── serial_testbench_behav.wcfg
└── readme.md
```
