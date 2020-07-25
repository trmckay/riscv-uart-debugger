// Raw I/O UART byte transciever
// Updated by Trevor McKay
//
// Based on code by Keefe Johnson:
//     https://github.com/KeefeJ/otter_debugger
//
// Original terminal config code from:
//     https://www.gnu.org/software/libc/manual/html_node/Noncanon-Example.html


#include "serial.h"

/* open_serial
 *
 * DESCRIPTION
 * Opens a raw input/output serial connection for transferring bytes
 * at a time.
 *
 * RETURNS
 * Nothing; saves serial port FD to int *serial_port.
 *
 * ARGUMENTS
 * char *path: string of the path to the serial port;
 *     something like /dev/ttyX
 * int *serial_port: pointer to an integer which should be allocated in
 *     the main stack frame or dynamically
 */
void open_serial(char *path, int *serial_port)
{
    term_sa saved_attributes;

    void exit_handler(void) {
        printf("Restoring serial port settings...");
        tcsetattr(*serial_port, TCSANOW, &saved_attributes);
        printf("closing port...");
        close(*serial_port);
        printf("closed!\n");
    }

    struct termios tattr;

    printf("Opening serial port.\n");

    if ((*serial_port = open(path, O_RDWR)) == -1) {
        fprintf(stderr, "ERROR: open(%s): %s\n", path, strerror(errno));
        exit(EXIT_FAILURE);
    }

    /* Make sure the port is a terminal. */
    if (!isatty(*serial_port)) {
        fprintf(stderr, "ERROR: File is not a terminal.\n");
        exit(EXIT_FAILURE);
    }

    /* Save the terminal attributes so we can restore them later. */
    printf("Reading terminal attributes and saving for restore.\n");
    tcgetattr(*serial_port, &saved_attributes);
    atexit(exit_handler);

    // Set the funny terminal modes.
    tcgetattr(*serial_port, &tattr);
    tattr.c_oflag &= ~OPOST;  // raw output
    tattr.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG | ECHONL | IEXTEN);  // raw input
    tattr.c_cflag &= ~(CSIZE | PARENB | CSTOPB);  // 8N1 ...
    tattr.c_cflag |= (CS8 | CLOCAL | CREAD);      // ... and enable without ownership
    // more raw input, and no software flow control
    tattr.c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL | IXON | IXOFF | IXANY);
    tattr.c_cc[VMIN] = MIN_BYTES;
    tattr.c_cc[VTIME] = INTER_BYTE_TIMEOUT;  // allow up to 1.0 secs between bytes received
    cfsetospeed(&tattr, BAUD);    // set baud rate
    printf("Flushing transmit buffer and setting raw mode.\n");
    tcsetattr(*serial_port, TCSAFLUSH, &tattr);

    printf("Ready to communicate with:\n");
    printf("    Port: %s\n", path);
    printf("    Baud: %s\n", BAUDS);
}


/* send_byte
 * 
 * DESCRIPTION
 * Send a single byte over serial to the target device.
 * Will exit with error if write fails.
 *
 * ARGUMENTS
 * byte_t byte_send: Byte to be sent.
 * int serial_port: FD of the serial port.
 * volatile sig_atomic_t ctrlc: ctrlC signal.
 */
void send_byte(byte_t byte_send, int serial_port)
{
    ssize_t wc;
    byte_send = htonl(byte_send);
    wc = write(serial_port, &byte_send, BYTES_PER_SEND);
    if (wc == ERR) {
        perror("ERROR: write(serial)");
        exit(EXIT_FAILURE);
    }
    if (wc != 1) {
        fprintf(stderr, "ERROR: Could not write enough bytes.\n");
        exit(EXIT_FAILURE);
    }
}


/* byte_t rcv_byte
 * DESCRIPTION
 * Recieve a byte over serial from the target device.
 * Will exit with error if read fails.
 *
 * RETURNS
 * byte_t byte_rcv: Byte recieved from the device.
 *
 * ARGUMENTS
 * int serial_port: FD of the serial port.
 * volatile sig_atomic_t ctrlc: ctrlC signal.
 */
byte_t rcv_byte(int serial_port)
{
    byte_t byte_rcv;
    ssize_t rc;
    byte_rcv = 0;
    rc = read(serial_port, &byte_rcv, BYTES_PER_RCV);
    if (rc == ERR) {
        perror("ERROR: read(serial)");
        exit(EXIT_FAILURE);
    }
    if (rc != 1) {
        fprintf(stderr, "ERROR: Could not read enough bytes.");
        exit(EXIT_FAILURE);
    }
    // TODO: Do the bits need to be reversed? Probably not; but, worth thinking about.
    return byte_rcv;
}
