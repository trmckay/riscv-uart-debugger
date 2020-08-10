CC = gcc
BUILD = build
CFLAGS = -Wall -L/usr/include -lreadline
TARGET = $(BUILD)/uart-db

rv32:
	mkdir -p build
	$(CC) src/*.c $(CFLAGS) -D RV32 -o $(TARGET)

rv64:
	mkdir -p build
	$(CC) src/*.c $(CFLAGS) -D RV64 -o $(TARGET)

install:
	mkdir -p ${HOME}/.local/bin
	cp $(TARGET) ${HOME}/.local/bin/

clean:
	rm -rf $(BUILD)
