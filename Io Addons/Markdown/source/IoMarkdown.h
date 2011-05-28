#ifndef IoMarkdown_DEFINED
#define IoMarkdown_DEFINED 1

#include "Common.h"
#include "IoObject.h"

#ifdef __cplusplus
extern "C" {
#endif

#define ISMarkdown(self) IoObject_hasCloneFunc_(self, (IoTagCloneFunc *)IoMarkdown_rawClone)

typedef IoObject IoMarkdown;

IoMarkdown *IoMarkdown_proto(void *state);
IoMarkdown *IoMarkdown_rawClone(IoMarkdown *self);

IoObject *IoMarkdown_parse(IoMarkdown *self, IoObject *locals, IoMessage *m);


#ifdef __cplusplus
}
#endif
#endif
