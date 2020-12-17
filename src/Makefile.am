CFLAGS= --pedantic -Wall
LDFLAGS=-L/usr/include -lreadline `pkg-config --cflags --libs glib-2.0`
bin_PROGRAMS = uartdb
uartdb_SOURCES = \
    cli.c \
    cli.h \
    data.c \
    data.h \
    debug.c \
    debug.h \
    file_io.c \
    file_io.h \
    main.c \
    Makefile.am \
    serial.c \
    serial.h \
    types.h \
    util.c \
    util.h
