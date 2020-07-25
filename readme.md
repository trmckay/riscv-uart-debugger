# RISC-V Debugger and Controller #

### About ###
Control and debug a RISC-V MCU over USB. Works with any target that correctly implements the protocol and most Linux hosts.

### Detailed implementation and protocol documentation ###
Documentation source be found [here](https://github.com/trmckay/pipeline-debugger/tree/master/doc). Build with pdflatex or your choice of LaTeX compiler. Prebuilt PDFs can also be found in the releases.

### Project Structure ###
```
.
├── client
│   └── src
│       ├── serial.c
│       └── serial.h
├── doc
│   ├── figures
│   │   ├── pipeline_db.drawio
│   │   └── pipeline_db.png
│   └── protocol.tex
├── module
│   ├── design
│   │   ├── mcu_controller.sv
│   │   ├── uart_rx.sv
│   │   └── uart_tx.sv
│   └── sim
│       ├── testbench
│       │   ├── ctlr_testbench.sv
│       │   ├── db_testbench.sv
│       │   └── serial_testbench.sv
│       └── wcfg
│           ├── ctrlr_testbench_behav.wcfg
│           └── serial_testbench_behav.wcfg
└── readme.md
```
