### About ###
General purpose debugger and controller of an MCU via UART over USB.

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
