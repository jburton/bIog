#include "IoState.h"
#include "IoObject.h"

IoObject *IoMarkdown_proto(void *state);

void IoMarkdownInit(IoObject *context)
{
	IoState *self = IoObject_state((IoObject *)context);

	IoObject_setSlot_to_(context, SIOSYMBOL("Markdown"), IoMarkdown_proto(self));

}
