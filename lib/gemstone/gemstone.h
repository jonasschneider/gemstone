#define GS_TYPE_STRING 0
#define GS_TYPE_FIXNUM 1

struct gs_value {
  int type;
  const char *string;
  unsigned long fixnum;
};

int gs_str_new(struct gs_value *value, const char *str, size_t len) {
  value->type = GS_TYPE_STRING;
  value->string = str;
}

int gs_fixnum_new(struct gs_value *value, unsigned long fixnum) {
  value->type = GS_TYPE_FIXNUM;
  value->fixnum = fixnum;
}

int gemstone_typeof(struct gs_value *value) {
  return value->type;
}