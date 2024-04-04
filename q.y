
%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
int tmp = 0;
char tmpvar[32];
char lastvar[32];


#include "dyn.h"
dynamic_str ftype;
dynamic_str fforall;
dynamic_str fvars;

void push(dynamic_str s);
void pop(void);
char const *topstr(void);

void addstmt(dynamic_str s);
void adddecl(dynamic_str s);
void printall(void);
dynamic_str aggregate_condition(dynamic_str s);
int yylex(void);
void yyerror(char *s);
dynamic_str make_binary(dynamic_str op, dynamic_str lhs, dynamic_str rhs);
dynamic_str make_unary(dynamic_str op, dynamic_str rhs);
%}

%token IF ELSE OUT CHECK SEMI COMMA LP RP LC RC VAL COLON NOT GIVEN AS
%token<str> IDENT NUM T10 T20 T30 T40 TYPE T5 U1 T4 T3
%type<str> expr exprlist nonempty_exprlist

%left LOW
%left LP
%nonassoc REDUCE 
%left ELSE 
%left T3
%left T4
%left T5
%left T10
%left T20
%left T30
%left T40
%left U1



%union {
    struct dynamic_str str;
}
   


%%
prog : prog decls stmt 
     | 
     ;

stmt : exprstmt
     | if
     | out
     | check
     | stmts
     | shortfunc
     ;

shortfunc: GIVEN { 
    ftype = dyn_new("");
    fforall = dyn_new("");
    fvars = dyn_new("");
    
} IDENT LP sparams RP COLON TYPE AS expr SEMI {
    dynamic_str s = dyn_new("(declare-fun ");
    s = dyn_cat(s, dyn_clone($3));
    s = dyn_cat_str(s, "(");
    s = dyn_cat(s, ftype);
    s = dyn_cat_str(s, ") ");
    s = dyn_cat(s, $8);
    s = dyn_cat_str(s, ")");
    addstmt(s);
    
    dynamic_str v = dyn_new("(assert (forall (");
    v = dyn_cat(v, fforall);
    v = dyn_cat_str(v, ") ");
    v = dyn_cat_str(v, "(= (");
    v = dyn_cat(v, $3);
    v = dyn_cat_str(v, " ");
    v = dyn_cat(v, fvars);
    v = dyn_cat_str(v, ")"); 
    v = dyn_cat(v, $10);
    v = dyn_cat_str(v, ")))");
    addstmt(v);
}

sparams : | nonempty_sparams;

nonempty_sparams : sparam COMMA nonempty_sparams  | sparam;

sparam : IDENT COLON TYPE {
    
    fvars = dyn_cat(dyn_cat_str(fvars, " "), dyn_clone($1));
    ftype = dyn_cat(dyn_cat_str(ftype, " "), dyn_clone($3));
    
    fforall = dyn_cat_str(fforall, "(");
    fforall = dyn_cat(fforall, $1);
    fforall = dyn_cat_str(fforall, " ");
    fforall = dyn_cat(fforall, $3);
    fforall = dyn_cat_str(fforall, ")");
}

decls : decl decls | ;
decl : VAL IDENT COLON TYPE SEMI {
        dynamic_str s = dyn_new("(declare-const ");
        s = dyn_cat(s, $2);
        s = dyn_cat_str(s, " ");
        s = dyn_cat(s, $4);
        s = dyn_cat_str(s, ")");
        addstmt(s);
    }



stmts : LC stmtlist RC ;

stmtlist : stmtlist stmt
         | stmt
         ;

exprstmt :  expr SEMI {
        dynamic_str s = dyn_new("(assert ");
        s = dyn_cat(s, aggregate_condition($1));
        s = dyn_cat_str(s, ")");
        addstmt(s);
    }
    ;

check : CHECK SEMI {
        dynamic_str s = dyn_new("(check-sat)");
        addstmt(s);
    };


expr :  
    expr T3 expr { 
        $$ = make_binary($2, $1, $3);
    }
    |
    expr T4 expr { 
        $$ = make_binary($2, $1, $3);
    }  
    |
    expr T5 expr { 
        $$ = make_binary($2, $1, $3);
    }  
    |  
    expr T10 expr { 
        $$ = make_binary($2, $1, $3);
    }    
    | expr T20 expr { 
        $$ = make_binary($2, $1, $3);
    }
    | expr T30 expr { 
         $$ = make_binary($2, $1, $3);
    }
    | expr T40 expr { 
         $$ = make_binary($2, $1, $3);
    }
    | U1 expr {
        $$ = make_unary($1, $2);
    }
    | IDENT LP exprlist RP {
        $$ = dyn_new("(");
        $$ = dyn_cat($$, $1);
        $$ = dyn_cat_str($$, " ");
        $$ = dyn_cat($$, $3);
        $$ = dyn_cat_str($$, ")");
    }
    | IDENT %prec LOW {
        $$ = $1;
    }
    | NUM {
        $$ = $1;
    }
    | LP expr RP {
        $$ = $2;
    }
    ;

exprlist : { $$ = dyn_new(""); } | nonempty_exprlist {$$ = $1;};

nonempty_exprlist : expr COMMA nonempty_exprlist {
    $$ = $1;
    $$ = dyn_cat_str($$, " ");
    $$ = dyn_cat($$, $3);
} | expr {
    $$ = $1;
};

if :  IF expr {
    tmp++;
    sprintf(tmpvar, "c%d", tmp);
    // define c%d as Bool, use declare-const
    dynamic_str s = dyn_new("(declare-const ");
    s = dyn_cat_str(s, tmpvar);
    s = dyn_cat_str(s, " Bool)");
    addstmt(s);

    dynamic_str cond = dyn_new("(assert (= ");
    cond = dyn_cat(cond, $2);
    cond = dyn_cat_str(cond, " ");
    cond = dyn_cat_str(cond, tmpvar);
    cond = dyn_cat_str(cond, "))");
    addstmt(cond);
    

    // push not bool
    dynamic_str boolvar = dyn_new("(not ");
    boolvar = dyn_cat_str(boolvar, tmpvar);
    boolvar = dyn_cat_str(boolvar, ")");
    push(boolvar);
} stmt {strcpy(lastvar, topstr()); pop(); } iftail;

iftail : %prec REDUCE | 
    ELSE {
        // push bool
        char const* topvar =topstr();
        dynamic_str boolvar = dyn_new("(");
        boolvar = dyn_cat_str(boolvar, topvar);
        pop();    
        push(boolvar);
    } stmt {
        pop();
    };
   
    
out : OUT LP expr RP SEMI {
    dynamic_str s = dyn_cat(dyn_new("(eval "), $3);
    s = dyn_cat_str(s, ")");
    addstmt(s);
};



%% 
dynamic_str dyn_new(const char *str) {
    dynamic_str dstr;
    dstr.str = (char *)malloc(strlen(str) + 1);
    dstr.len = strlen(str);
    dstr.cap = strlen(str) + 1;
    strcpy(dstr.str, str);
    return dstr;
}

void dyn_free(dynamic_str dstr) {
    free(dstr.str);
}

dynamic_str dyn_cat(dynamic_str /*ref*/ dstr, dynamic_str /*move*/ dstr2) {
    if (dstr.cap < dstr.len + dstr2.len + 1) {
        dstr.str = (char *)realloc(dstr.str, dstr.len + dstr2.len + 1);
        dstr.cap = dstr.len + dstr2.len;
    }
    strcat(dstr.str, dstr2.str);
    dstr.len += dstr2.len;
    dyn_free(dstr2);
    return dstr;
}

dynamic_str dyn_cat_str(dynamic_str /*ref*/ dstr, char const * /*static*/ str2) {
    int w = (int)strlen(str2);
    if (dstr.cap < dstr.len + w + 1) {
        dstr.str = (char *)realloc(dstr.str, dstr.len + w + 1);
        dstr.cap = dstr.len + w;
    }
    strcat(dstr.str, str2);
    dstr.len += w;
    return dstr;
}

char const* dyn_get_str(dynamic_str dstr) {
    return dstr.str;
}

typedef struct node {
    dynamic_str data;
    struct node *next;
} stack;

stack *top = NULL; 
void push(dynamic_str s) {
    stack *new_node = (stack *)malloc(sizeof(stack));
    new_node->data = s;
    new_node->next = top;
    top = new_node;
}

void pop(void) {
    if (top == NULL) {
        return;
    }
    stack *temp = top;
    top = top->next;
    dyn_free(temp->data);
    free(temp);
}

typedef struct node stmt, node;

node *head, *tail;
node *declhead, *decltail;

void add(dynamic_str s, node **head, node **tail) {
    stmt *new_node = (stmt *)malloc(sizeof(stmt));
    new_node->data = s;
    new_node->next = NULL;
    if (*head == NULL) {
        *head = new_node;
        *tail = new_node;
    } else {
        (*tail)->next = new_node;
        *tail = new_node;
    }
}

void adddecl(dynamic_str s) {
    add(s, &declhead, &decltail);
}

void addstmt(dynamic_str s) {
    add(s, &head, &tail);
}

void printall() {
    for (stmt *s = declhead; s != NULL; s = s->next) {
        printf("%s\n", dyn_get_str(s->data));
    }
    for (stmt *s = head; s != NULL; s = s->next) {
        printf("%s\n", dyn_get_str(s->data));
    }
}

char const *topstr(void) {
    return dyn_get_str(top->data);
}
void cleanall() {
    while (top != NULL) {
        pop();
    }
    for (stmt *s = head; s != NULL; ) {
        node *temp = s->next;
        dyn_free(s->data);
        free(s);
        s = temp;
    }
    for (stmt *s = declhead; s != NULL;) {
        node *temp = s->next;
        dyn_free(s->data);
        free(s);
        s = temp;
    }
}


dynamic_str dyn_clone(dynamic_str s) {
    return dyn_new(s.str);
}

dynamic_str aggregate_condition(dynamic_str s) {
    if (top == NULL) {
        return s;
    }
    // iterate from stack top to bottom, make (and t1 t2 t3 ...)
    dynamic_str and = dyn_new("(and ");
    // don't consume stack
    for (stack *s = top; s != NULL; s = s->next) {
        and = dyn_cat_str(and, " ");
        and = dyn_cat_str(and, dyn_get_str(s->data));
    }
    and = dyn_cat_str(and, ")");
    // concat "(and " {and} {s} ")"
    dynamic_str all = dyn_new("(or ");
    all = dyn_cat(all, and);
    all = dyn_cat_str(all, " ");
    all = dyn_cat(all, s);
    all = dyn_cat_str(all, ")");
    return all;
}

void yyerror(char *s) {
    fprintf(stderr, "%s\n", s);
    exit(1);
}

int yywrap() {
    return 1;
}

extern FILE *yyin;
int main(int argc, char *argv[]) {
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
    } else {
        yyin = stdin;
    }
    yyparse();
    printall();
    cleanall();
    
    if (argc > 1) {
        fclose(yyin);
    }
    
    
    return 0;
}

dynamic_str make_binary(dynamic_str op, dynamic_str lhs, dynamic_str rhs) {
    dynamic_str s = dyn_new("(");
    s = dyn_cat(s, op);
    s = dyn_cat_str(s, " ");
    s = dyn_cat(s, lhs);
    s = dyn_cat_str(s, " ");
    s = dyn_cat(s, rhs);
    s = dyn_cat_str(s, ")");
    return s;
}

dynamic_str make_unary(dynamic_str op, dynamic_str rhs) {
    dynamic_str s = dyn_new("(");
    s = dyn_cat(s, op);
    s = dyn_cat_str(s, " ");
    s = dyn_cat(s, rhs);
    s = dyn_cat_str(s, ")");
    return s;
}