#include <string.h>
#define GS_TYPE_STRING 0
#define GS_TYPE_FIXNUM 1

struct gs_value {
  int type;
  const char *string;
  unsigned long fixnum;
};

struct gs_value gs_stack[255];
int gs_stack_pointer; 

void gs_stack_init() {
  memset(gs_stack, 0, sizeof(gs_stack));
}

void gs_stack_push(struct gs_value to_push) {
  gs_stack[gs_stack_pointer] = to_push;
  gs_stack_pointer++;
}

struct gs_value gs_stack_pop() {
  gs_stack_pointer--;
  return gs_stack[gs_stack_pointer];
}

void gs_str_new(struct gs_value *value, const char *str, size_t len) {
  value->type = GS_TYPE_STRING;
  value->string = str;
}

void gs_fixnum_new(struct gs_value *value, unsigned long fixnum) {
  value->type = GS_TYPE_FIXNUM;
  value->fixnum = fixnum;
}

int gemstone_typeof(struct gs_value *value) {
  return value->type;
}