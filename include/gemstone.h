#include <string.h>
#include "hashtable.c"
#include "setjmp.h"

#define GS_TYPE_STRING 1
#define GS_TYPE_FIXNUM 2
#define GS_TYPE_LAMBDA 3

struct gs_value {
  int type;
  const char *string;
  unsigned long fixnum;

  void (*lambda_func)(); // for lambdas

  struct gs_value *dispatcher;
};


struct gs_stack_frame {
  struct gs_value *receiver;
  struct gs_value *argument_stack[16];
  struct gs_value **argument_stack_pointer;

  hash_table_t *lvars;

  struct gs_value *result;
};





struct gs_stack_frame gs_stack[255];
struct gs_stack_frame *gs_stack_pointer;





void gs_argstack_init() {
  //memset((*gs_stack_pointer).argument_stack, 0, sizeof((*gs_stack_pointer).argument_stack));
  (*gs_stack_pointer).argument_stack_pointer = &(*gs_stack_pointer).argument_stack[0];
}

void gs_argstack_push(struct gs_value *to_push) {
  *(*gs_stack_pointer).argument_stack_pointer = to_push;
  (*gs_stack_pointer).argument_stack_pointer = (*gs_stack_pointer).argument_stack_pointer + 1;
}

struct gs_value *gs_argstack_pop() {
  (*gs_stack_pointer).argument_stack_pointer = (*gs_stack_pointer).argument_stack_pointer - 1;
  return *((*gs_stack_pointer).argument_stack_pointer);
}




void gs_lvars_init() {
  (*gs_stack_pointer).lvars = hash_table_new(MODE_VALUEREF); // TODO: leak check
}


void gs_lvars_assign(const char *name, struct gs_value *val) {
  struct gs_value *old_val = (struct gs_value *)hash_table_lookup((*gs_stack_pointer).lvars, (void*)name, strlen(name));
  if(old_val != NULL) {
    LOG("--L removing old value for %s, it was set to %p", name, old_val);
    hash_table_remove((*gs_stack_pointer).lvars, (void*)name, strlen(name));
  }
  LOG("--L adding %s set to %p", name, val);
  hash_table_add((*gs_stack_pointer).lvars, (void*)name, strlen(name), val, sizeof(&val));
}

struct gs_value *gs_lvars_fetch(const char *name) {
  struct gs_value *v = (struct gs_value *)hash_table_lookup((*gs_stack_pointer).lvars, (void*)name, strlen(name));
  LOG("--L fetched %s - its %p", name, v);
  return v;
}




void gs_stack_init() {
  //memset(gs_stack, 0, sizeof(gs_stack));
  gs_stack_pointer = gs_stack;
}

void gs_stack_push_with_lscope() {
  // stack element 0 is left empty for now
  gs_stack_pointer = gs_stack_pointer + 1;
  LOG(">> entering stack level and creating new lscope [%ld]", (gs_stack_pointer - gs_stack));
  //memset(gs_stack_pointer, 0, sizeof(struct gs_stack_frame));

  gs_argstack_init();

  gs_lvars_init();
}

void gs_stack_push() {
  // stack element 0 is left empty for now
  hash_table_t *lvars = gs_stack_pointer->lvars;
  gs_stack_pointer = gs_stack_pointer + 1;
  gs_stack_pointer->lvars = lvars;
  
  LOG(">> entering stack level and preserving lscope [%ld]", (gs_stack_pointer - gs_stack));
  //memset(gs_stack_pointer, 0, sizeof(struct gs_stack_frame));

  gs_argstack_init();
}

struct gs_stack_frame gs_stack_pop() {
  LOG(">> leaving stack level [%ld]", (gs_stack_pointer - gs_stack));
  gs_stack_pointer = gs_stack_pointer - 1;
  return *gs_stack_pointer;
}



void gs_str_new(struct gs_value *value, const char *str, size_t len) {
  value->type = GS_TYPE_STRING;
  value->string = str;
}

void gs_fixnum_new(struct gs_value *value, unsigned long fixnum) {
  value->type = GS_TYPE_FIXNUM;
  value->fixnum = fixnum;
}


struct gs_value *gs_string_literal(const char *str, size_t len) {
  // FIXME: leak memory like a boss - collect garbage like a boss
  struct gs_value *val = malloc(sizeof(struct gs_value));
  gs_str_new(val, str, len);
  return val;
}


struct gs_value *gs_fixnum_literal(unsigned long fixnum) {
  // FIXME: leak memory like a boss - collect garbage like a boss
  struct gs_value *val = malloc(sizeof(struct gs_value));
  gs_fixnum_new(val, fixnum);
  return val;
}



int gemstone_typeof(struct gs_value *value) {
  return value->type;
}