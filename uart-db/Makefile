CC = gcc
BUILD = build
CFLAGS = -Wall -L/usr/include -lreadline `pkg-config --cflags --libs glib-2.0`
TARGET = $(BUILD)/uart-db

rv32:
	mkdir -p build
	$(CC) src/*.c $(CFLAGS) -D RV32 -o $(TARGET)

rv64:
	mkdir -p build
	$(CC) src/*.c $(CFLAGS) -D RV64 -o $(TARGET)

install:
	install -Dm 755 build/uart-db /usr/bin/uart-db

clean:
	rm -rf $(BUILD)
