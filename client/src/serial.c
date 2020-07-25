// UART byte transciever by Trevor McKay
//
// Based on code by Keefe Johnson:
//     https://github.com/KeefeJ/otter_debugger
//
// Original terminal config code from:
//     https://www.gnu.org/software/libc/manual/html_node/Noncanon-Example.html

#include "serial.h"

volatile sig_atomic_t ctrlc = 0;

void open_serial(char *path, int serial_port, term_sa saved_attributes)
{

    void exit_handler(void) {
        fprintf(stderr, "Restoring serial port settings... ");
        tcsetattr(serial_port, TCSANOW, &saved_attributes);
        fprintf(stderr, "closing port... ");
        close(serial_port);
        fprintf(stderr, "closed\n");
    }

    struct termios tattr;

    fprintf(stderr, "Opening serial port... ");

    if ((serial_port = open(path, O_RDWR)) == -1) {
        fprintf(stderr, "open(%s): %s\n", path, strerror(errno));
        exit(EXIT_FAILURE);
    }

    /* Make sure the port is a terminal. */
    if (!isatty(serial_port)) {
        fprintf(stderr, "Not a terminal.\n");
        exit(EXIT_FAILURE);
    }

    /* Save the terminal attributes so we can restore them later. */
    fprintf(stderr, "reading old settings... ");
    tcgetattr(serial_port, &saved_attributes);
    atexit(exit_handler);

    /* Set the funny terminal modes. */
    tcgetattr(serial_port, &tattr);
    tattr.c_oflag &= ~OPOST;  // raw output
    tattr.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG | ECHONL | IEXTEN);  // raw input
    tattr.c_cflag &= ~(CSIZE | PARENB | CSTOPB);  // 8N1 ...
    tattr.c_cflag |= (CS8 | CLOCAL | CREAD);      // ... and enable without ownership
    tattr.c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL | IXON | IXOFF | IXANY);  // more raw input, and no software flow control
    tattr.c_cc[VMIN] = 4;
    tattr.c_cc[VTIME] = 10;  // allow up to 1.0 secs between bytes received
    cfsetospeed(&tattr, B115200);
    fprintf(stderr, "flushing transmit buffer and setting raw mode... ");
    tcsetattr(serial_port, TCSAFLUSH, &tattr);

    fprintf(stderr, "ready to communicate\n");
}

void send_byte(byte_t w_byte, int serial_port)
{
    ssize_t bw;
    w_byte = htonl(w_byte);
    bw = write(serial_port, &w_byte, 1);
    if (ctrlc) exit(EXIT_FAILURE);
    if (bw == -1) {
        perror("write(serial)");
        exit(EXIT_FAILURE);
    }
    if (bw != 1) {
        fprintf(stderr, "Write failed.\n");
        exit(EXIT_FAILURE);
    }
}

byte_t rcv_byte(int serial_port)
{
    uint32_t w;
    ssize_t br;
    w = 0;
    br = read(serial_port, &w, 1);
    if (ctrlc) exit(EXIT_FAILURE);
    if (br == -1) {
        perror("read(serial)");
        exit(EXIT_FAILURE);
    }
    if (br != 1) {
        fprintf(stderr, "Read failed.");
        exit(EXIT_FAILURE);
    }
    return ntohl(w);
}

