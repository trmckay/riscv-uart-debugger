CC = gcc
BUILD = build
CFLAGS = -Wall -L/usr/include -lreadline
TARGET = $(BUILD)/rv-uart-dbg

all:
	mkdir -p build
	$(CC) src/*.c $(CFLAGS) -o $(TARGET)

install:
	sudo cp $(TARGET) /usr/bin/

clean:
	rm -r $(BUILD)
