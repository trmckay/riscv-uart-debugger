#ifndef UTIL_H
#define UTIL_H

#include "types.h"
#include <stdlib.h>
#include <string.h>
#include <strings.h>

#define match_strs(s, m1, m2)                                                  \
    ((strcasecmp(s, m1) == 0) || (strcasecmp(s, m2) == 0))

int starts_with(char *cmp, char *str);
int parse_int(char *str);

#endif
