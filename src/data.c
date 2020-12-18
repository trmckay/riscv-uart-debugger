#include "data.h"
#include "cli.h"
#include "file_io.h"
#include "types.h"
#include "util.h"
#include <stdio.h>
#include <stdlib.h>
#include <readline/readline.h>
#include <string.h>
#include <strings.h>

// searches defined variables, or parses as integer
word_t get_num(ht_t *vars, char *tok) {
    word_t *r;
    r = (word_t *)g_hash_table_lookup(vars, tok);
    if (r == NULL)
        return parse_int(tok);
    else
        return *r;
}

// loads user defined variables into program from path
// default: ~/.config/rvdb/config
// returns number of variables found
int populate_vars(ht_t *vars_ht, char **keys, word_t *values, char *path) {
    char *line_buf = NULL, *str_key;
    word_t value;
    size_t line_buf_size = 0;
    int line_count = 0, var_count = 0;
    ssize_t line_size;
    FILE *fp = fopen(path, "r");

    if (!fp) {
        fprintf(stderr, "Error opening file '%s'\n", path);
        return 0;
    }

    /* Get the first line of the file. */
    line_size = getline(&line_buf, &line_buf_size, fp);

    /* Loop through until we are done with the file. */
    while (line_size >= 0 && var_count < MAX_VAR_COUNT) {
        /* Increment our line count */
        line_count++;

        // get pointer to key, and integer value
        str_key = strtok(line_buf, " ");
        value = parse_int(strtok(NULL, " "));

        // save value
        values[var_count] = value;

        // dynamically allocate key
        if ((keys[var_count] = malloc(strlen(str_key) + 1)) == NULL) {
            perror("");
            exit(EXIT_FAILURE);
        }
        strcpy(keys[var_count], str_key);

        // add the key-value pair to the hash table
        g_hash_table_insert(vars_ht, keys[var_count], &values[var_count]);

        var_count++;

        /* Get the next line */
        line_size = getline(&line_buf, &line_buf_size, fp);
    }

    /* Free the allocated line buffer */
    free(line_buf);
    line_buf = NULL;

    /* Close the file now that we are done with it */
    fclose(fp);

    return var_count;
}

void ht_destroy(ht_t *ht, char **keys, int count) {
    g_hash_table_destroy(ht);
    for (int i = 0; i < count; i++)
        free(keys[i]);
}

// god help us
int parse_register_addr(ht_t *vars, char *tok) {
    if (tok[0] == 'x')
        return parse_int(tok + sizeof(char));
    if (match_strs(tok, X0))
        return 0;
    else if (match_strs(tok, X1))
        return 1;
    else if (match_strs(tok, X2))
        return 2;
    else if (match_strs(tok, X3))
        return 3;
    else if (match_strs(tok, X4))
        return 4;
    else if (match_strs(tok, X5))
        return 5;
    else if (match_strs(tok, X6))
        return 6;
    else if (match_strs(tok, X7))
        return 7;
    else if (match_strs(tok, X8))
        return 8;
    else if (match_strs(tok, X9))
        return 9;
    else if (match_strs(tok, X10))
        return 10;
    else if (match_strs(tok, X11))
        return 11;
    else if (match_strs(tok, X12))
        return 12;
    else if (match_strs(tok, X13))
        return 13;
    else if (match_strs(tok, X14))
        return 14;
    else if (match_strs(tok, X15))
        return 15;
    else if (match_strs(tok, X16))
        return 16;
    else if (match_strs(tok, X17))
        return 17;
    else if (match_strs(tok, X18))
        return 18;
    else if (match_strs(tok, X19))
        return 19;
    else if (match_strs(tok, X20))
        return 20;
    else if (match_strs(tok, X21))
        return 21;
    else if (match_strs(tok, X22))
        return 22;
    else if (match_strs(tok, X23))
        return 23;
    else if (match_strs(tok, X24))
        return 24;
    else if (match_strs(tok, X25))
        return 25;
    else if (match_strs(tok, X26))
        return 26;
    else if (match_strs(tok, X27))
        return 27;
    else if (match_strs(tok, X28))
        return 28;
    else if (match_strs(tok, X29))
        return 29;
    else if (match_strs(tok, X30))
        return 30;
    else if (match_strs(tok, X31))
        return 31;
    else
        return get_num(vars, tok);
}
