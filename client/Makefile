CC = gcc
BUILD = build
CFLAGS = -Wall -L/usr/include -lreadline
TARGET = $(BUILD)/debugger

all:
	mkdir -p build
	$(CC) src/*.c $(CFLAGS) -o $(TARGET)

clean:
	rm -r $(BUILD)
