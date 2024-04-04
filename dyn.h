#ifndef  DYN_H
#define  DYN_H


struct dynamic_str {
    char *str;
    int len;
    int cap;
};

typedef struct dynamic_str dynamic_str;
dynamic_str dyn_new(char const *str);
dynamic_str dyn_cat(dynamic_str s1, dynamic_str s2);
dynamic_str dyn_cat_str(dynamic_str s, char const *str);
char const *dyn_get_str(dynamic_str s);
void dyn_free(dynamic_str s);
dynamic_str dyn_clone(dynamic_str s);
#endif