#include "util.h"

int starts_with(char *cmp, char *str) {
    int l = strlen(str);
    for (int i = 0; i < l; i++) {
        if (cmp[i] != str[i])
            return 0;
    }
    return 1;
}

// parse an int in the form 0xNNN..., 0XNNN... or NNN...
int parse_int(char *str) {
    char prefix[3];
    memcpy(prefix, str, 2);
    prefix[2] = 0;

    // hex formatted
    if (match_strs(prefix, "0x", "0X")) {
        return (word_t)strtol(str, NULL, 0);
    }
    // decimal formatted
       else
        return atoi(str);
}
