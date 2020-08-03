#include "ctrlr.h"

void connection_test(int serial_port, int n)
{
    int misses = 0;
    int r, s;
    FILE *log;

    time_t t_start;
    time(&t_start);
    
    log = fopen("test.log", "w");
    if (log == NULL)
    {
        fprintf(stderr, "Error: could not open test.log for writing\n");
        return;
    }   

    printf("Testing connection with %d commands\n", n);
    for (int i = 0; i < n; i++)
    {
        printf("Progress: %.0f%%\r", (float)(i*100)/n);

        // send null command
        send_word(serial_port, 0, 0);
        r = expect_any_word(serial_port, 0);
        if (r != 0)
            misses += 1;
        fprintf(log, "[%4d -  cmd]: sent: 0x00000000, recieved: 0x%08X\n", i, r);

        // send random addr
        s = rand();
        send_word(serial_port, s, 0);
        r = expect_any_word(serial_port, 0);
        if (s != r)
            misses += 1;
        fprintf(log, "[%4d - addr]: sent: 0x%08X, recieved: 0x%08X\n", i, s, r);
        
        // send random data
        s = rand();
        send_word(serial_port, s, 0);
        r = expect_any_word(serial_port, 0);
        if (s != r)
            misses += 1;
        fprintf(log, "[%4d - data]: sent: 0x%08X, recieved: 0x%08X\n\n", i, s, r);
        
        // wait for final reply
        expect_any_word(serial_port, 0);
    }

    time_t t_fin;
    time(&t_fin);

    int dt = (int)(t_fin - t_start);
    float nkib = (float)((n*7)/4)/1024;
    printf("\nSent/recieved: %.2f KiB in %d sec (%.2f B/s)\n", nkib, dt, 1024*nkib/dt);
    printf("Number of incorrect echoes: %d\n", misses);
    printf("Accuracy: %.3f\n", (float)((3*n) - misses)/(3*n));
    printf("See details in test.log\n");
}

int mcu_pause(int serial_port, int verbose)
{
    send_word(serial_port, FN_PAUSE, verbose);
    
    if (expect_word(serial_port, FN_PAUSE, verbose) != 1)
    {
        fprintf(stderr, "Pause command unsuccessful.\n");
        return 1;
    }

    send_word(serial_port, 0xFF89, verbose);
    expect_any_word(serial_port, verbose);
    send_word(serial_port, 0x8AB7, verbose);
    expect_any_word(serial_port, verbose);
    send_word(serial_port, 0x1234, verbose);
    return 0;
}
