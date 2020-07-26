CC = gcc
BUILD = build
CFLAGS = -Wall -L/usr/include -lreadline
TARGET = $(BUILD)/rv-uart-dbg

all:
	@echo "Make sure the readline library is installed."
	@echo "(readline-dev on Debian/Ubuntu derivatives, lib32-readline on Arch derivatives)"
	@echo ""

	mkdir -p build
	$(CC) src/*.c $(CFLAGS) -o $(TARGET)

install:
	echo "Installing to $(TARGET). Make sure this is in your PATH."
	sudo cp $(TARGET) /usr/bin/

clean:
	rm -r $(BUILD)
