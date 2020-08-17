#ifndef UTIL_H
#define UTIL_H

#include "types.h"
#include <strings.h>

#define match_strs(S1, S2) ((strcasecmp((S1), (S2)) == 0))

int starts_with(char *cmp, char *str);
int parse_int(char *str);

#endif
