#include <string.h>
#define GS_TYPE_STRING 0
#define GS_TYPE_FIXNUM 1

struct gs_value {
  int type;
  const char *string;
  unsigned long fixnum;
};


struct gs_stack_frame {
  struct gs_value *receiver;
  struct gs_value *argument_stack[16];
  struct gs_value **argument_stack_pointer;

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
  (*gs_stack_pointer).argument_stack_pointer = (*gs_stack_pointer).argument_stack_pointer + sizeof(struct gs_value *);
}

struct gs_value *gs_argstack_pop() {
  (*gs_stack_pointer).argument_stack_pointer = (*gs_stack_pointer).argument_stack_pointer - sizeof(struct gs_value *);
  return *((*gs_stack_pointer).argument_stack_pointer);
}


void gs_stack_init() {
  //memset(gs_stack, 0, sizeof(gs_stack));
  gs_stack_pointer = gs_stack;
}

void gs_stack_push() {
  // stack element 0 is left empty for now
  gs_stack_pointer = gs_stack_pointer + 1;
  //memset(gs_stack_pointer, 0, sizeof(struct gs_stack_frame));

  gs_argstack_init();
}

struct gs_stack_frame gs_stack_pop() {
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

int gemstone_typeof(struct gs_value *value) {
  return value->type;
}