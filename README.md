# RISC-V UART Debugger

## About

Control and debug a RISC-V MCU over USB UART.

Configured by default for a 50 MHz CPU communicating with a baud rate of 115200.
This can be adjusted by changing the BAUD definition in `client/src/serial.h` and the `BAUD`/`CLK_RATE`
parameters of the `mcu_controller` module.


## How to build

The following programs are needed:

- `automake`
- `autoconf`
- `libtool`
- `pkgconfig`
- GNU Make
- a C compiler

The following libraries are needed:

- `readline` >= 8.1.0
- `glib-2.0` >= 2.24.1

Once the dependencies are satisfied run

```
git clone https://github.com/trmckay/riscv-uart-debugger
cd riscv-uart-debugger
```

to download the source.

Then, run

```
./bootstrap.sh
mkdir -p build
cd build
../configure [--prefix="/path/to/install"]
```

to set up the build environment.

Finally, build and install with

```
make
[sudo] make install
```


## Usage

Launch with `rvdb`.

See `man rvdb` for more information.


## Protocol implementation

Documentation source be built with `pdflatex` or your choice of LaTeX compiler.
Pre-built PDFs can also be found in the releases.

Implement the protocol as defined in the doc on your MCU.
Then, add the proper constraints to
forward your UART `tx`/`sx` connections to the `mcu_controller` module.
