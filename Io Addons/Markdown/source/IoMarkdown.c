#include <locale.h>
#include <string.h>
#include <stdio.h>
#include <mkdio.h>

#include "IoMarkdown.h"

void *run_readline_loop(void *null);


pthread_t readlineThread;
pthread_mutex_t mutex;
char *lines[100];
int lineCount = 0;


IoTag *IoMarkdown_newTag(void *state)
{
	IoTag *tag = IoTag_newWithName_("Markdown");
	IoTag_state_(tag, state);
	return tag;
}

IoMarkdown *IoMarkdown_proto(void *state)
{
	IoMethodTable methodTable[] = {
		{"parse", IoMarkdown_parse},
		{NULL, NULL},
	};

	IoObject *self = IoObject_new(state);
	IoObject_tag_(self, IoMarkdown_newTag(state));

	IoState_registerProtoWithFunc_((IoState *)state, self, IoMarkdown_proto);

	IoObject_addMethodTable_(self, methodTable);


	return self;
}



/* ----------------------------------------------------------- */

IoObject *IoMarkdown_parse(IoMarkdown *self, IoObject *locals, IoMessage *m)
{
	int messageArgCount = IoMessage_argCount(m);
	if (messageArgCount < 2)
	{
		IoState_error_(IOSTATE, m, "Markdown error: expected 2 arguments; path to source file and path to output file!");
		return IONIL(self);
	}
	
	char *sourecepath = IoMessage_locals_cStringArgAt_(m, locals, 0);
	char *destpath = IoMessage_locals_cStringArgAt_(m, locals, 1);
	if (!sourecepath || !destpath)
	{
		IoState_error_(IOSTATE, m, "Markdown error: expected 2 arguments; path to source file and path to output file!");
		return IONIL(self);
	}
	
	FILE *sourcefile = fopen(sourecepath, "r");
	if (!sourcefile)
	{
		IoState_error_(IOSTATE, m, "Markdown error: error opening source file!");
		return IONIL(self);
	}
	
	FILE *destfile = fopen(destpath, "w");
	if (!destfile)
	{
		IoState_error_(IOSTATE, m, "Markdown error: error opening destination file!");
		return IONIL(self);
	}
	
	MMIOT *mk = mkd_in(sourcefile, 0);
	markdown(mk, destfile, 0);
		
	fclose(sourcefile);
	fclose(destfile);

	return self;
}

