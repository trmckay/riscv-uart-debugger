CC = gcc
BUILD = build
CFLAGS = -Wall -L/usr/include -lreadline -g
TARGET = $(BUILD)/uart-db

all:
	mkdir -p build
	$(CC) src/*.c $(CFLAGS) -o $(TARGET)

install:
	@echo "Installing to $(TARGET). Make sure this is in your PATH."
	sudo cp $(TARGET) /usr/bin/

clean:
	rm -rf $(BUILD)
