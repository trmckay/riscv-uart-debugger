#include "file_io.h"

int open_file(char *path, off_t *num_words) {
    int file;
    struct stat s;

    //  try to open the file
    if ((file = open(path, O_RDONLY)) == -1) {
        fprintf(stderr, "open(%s): %s\n", path, strerror(errno));
        return -1;
    }

    if (fstat(file, &s) == -1) {
        perror("fstat(file)");
        return -1;
    }

    // return FD and size in words
    *num_words = (s.st_size + 3) / 4; // round up to nearest 4 bytes
    return file;
}

// read a word from the steam
int read_word_file(int file, word_t *w) {
    ssize_t br;
    word_t r;

    br = read(file, &r, WORD_SIZE);

    if (br == -1) {
        perror("read(file)");
        return 1;
    }
    if (br == 0) {
        fprintf(stderr, "File size changed\n");
        return 1;
    }

    *w = r;
    return 0;
}
