CC = gcc
BUILD = build
CFLAGS = -Wall -L/usr/include -lreadline -g
TARGET = $(BUILD)/uart-db

all:
	mkdir -p build
	$(CC) src/*.c $(CFLAGS) -o $(TARGET)

install:
	mkdir -p ${HOME}/.local/bin
	cp $(TARGET) ${HOME}/.local/bin/

clean:
	rm -rf $(BUILD)
