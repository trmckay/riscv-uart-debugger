#ifndef DATA_H
#define DATA_H

#include "types.h"
#include <gmodule.h>

typedef GHashTable ht_t;

int parse_register_addr(ht_t *vars, char *tok);
void ht_destroy(ht_t *ht, char **keys, int count);
int populate_vars(ht_t *vars_ht, char **keys, word_t *values, char *path);
word_t get_num(ht_t *vars, char *tok);

#endif
