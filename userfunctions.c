   /*******************************************************/
   /*      "C" Language Integrated Production System      */
   /*                                                     */
   /*            CLIPS Version 6.40  07/30/16             */
   /*                                                     */
   /*                USER FUNCTIONS MODULE                */
   /*******************************************************/

/*************************************************************/
/* Purpose:                                                  */
/*                                                           */
/* Principal Programmer(s):                                  */
/*      Gary D. Riley                                        */
/*                                                           */
/* Contributing Programmer(s):                               */
/*                                                           */
/* Revision History:                                         */
/*                                                           */
/*      6.24: Created file to seperate UserFunctions and     */
/*            EnvUserFunctions from main.c.                  */
/*                                                           */
/*      6.30: Removed conditional code for unsupported       */
/*            compilers/operating systems (IBM_MCW,          */
/*            MAC_MCW, and IBM_TBC).                         */
/*                                                           */
/*            Removed use of void pointers for specific      */
/*            data structures.                               */
/*                                                           */
/*************************************************************/

/***************************************************************************/
/*                                                                         */
/* Permission is hereby granted, free of charge, to any person obtaining   */
/* a copy of this software and associated documentation files (the         */
/* "Software"), to deal in the Software without restriction, including     */
/* without limitation the rights to use, copy, modify, merge, publish,     */
/* distribute, and/or sell copies of the Software, and to permit persons   */
/* to whom the Software is furnished to do so.                             */
/*                                                                         */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS */
/* OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF              */
/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT   */
/* OF THIRD PARTY RIGHTS. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY  */
/* CLAIM, OR ANY SPECIAL INDIRECT OR CONSEQUENTIAL DAMAGES, OR ANY DAMAGES */
/* WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN   */
/* ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF */
/* OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.          */
/*                                                                         */
/***************************************************************************/

#include "clips.h"
#include "sqlite3.h"
#include <string.h>

void UserFunctions(Environment *);

void SqliteLibversionFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	returnValue->lexemeValue = CreateSymbol(theEnv, sqlite3_libversion());
}

void SqliteLibversionNumberFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	returnValue->integerValue = CreateInteger(theEnv, sqlite3_libversion_number());
}

void SqliteSourceidFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	returnValue->lexemeValue = CreateSymbol(theEnv, sqlite3_sourceid());
}

void SqliteThreadsafeFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	returnValue->lexemeValue = sqlite3_threadsafe() ? TrueSymbol(theEnv) : FalseSymbol(theEnv);
}

void SqliteMemoryUsedFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	returnValue->integerValue = CreateInteger(theEnv, sqlite3_memory_used());
}

void SqliteMemoryHighwaterFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	int reset = 0;
	if (UDFHasNextArgument(context))
	{
		UDFNextArgument(context,LEXEME_BITS,&theArg);
		if (theArg.header->type != SYMBOL_TYPE && theArg.header->type != STRING_TYPE)
		{
			WriteString(theEnv, STDERR, "sqlite-memory-highwater: first arg must be TRUE or FALSE\n");
			returnValue->lexemeValue = FalseSymbol(theEnv);
			return;
		}
		else
		if (theArg.lexemeValue != TrueSymbol(theEnv) && theArg.lexemeValue != FalseSymbol(theEnv))
		{
			WriteString(theEnv, STDERR, "sqlite-memory-highwater: first arg must be TRUE or FALSE\n");
			returnValue->lexemeValue = FalseSymbol(theEnv);
			return;
		}
		else
		if (theArg.lexemeValue == TrueSymbol(theEnv))
		{
			reset = 1;
		}
	}

	returnValue->integerValue = CreateInteger(theEnv, sqlite3_memory_highwater(reset));
}

void SqliteCompileoptionGetFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	const char *option;

	UDFNextArgument(context,INTEGER_BIT,&theArg);
	if (theArg.header->type != INTEGER_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-compileoption-get: first arg must be an integer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	if (NULL == (option = sqlite3_compileoption_get(theArg.integerValue->contents)))
	{
		WriteString(theEnv, STDERR, "sqlite-compileoption-get: could not get compile option\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	returnValue->lexemeValue = CreateSymbol(theEnv, option);
}

void SqliteCompileoptionUsedFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;

	UDFNextArgument(context,LEXEME_BITS,&theArg);
	if (theArg.header->type != SYMBOL_TYPE && theArg.header->type != STRING_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-compileoption-used: first arg must be a symbol or a string\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	if (sqlite3_compileoption_used(theArg.lexemeValue->contents))
	{
		returnValue->lexemeValue = TrueSymbol(theEnv);
	}
	else
	{
		returnValue->lexemeValue = FalseSymbol(theEnv);
	}
}

int OpenFlagToInt(const char *flag)
{
	if (strlen(flag) == strlen("SQLITE_OPEN_READONLY") && 0 == strcmp(flag, "SQLITE_OPEN_READONLY"))
	{
		return SQLITE_OPEN_READONLY;
	}
	else
	if (strlen(flag) == strlen("SQLITE_OPEN_READWRITE") && 0 == strcmp(flag, "SQLITE_OPEN_READWRITE"))
	{
		return SQLITE_OPEN_READWRITE;
	}
	else
	if (strlen(flag) == strlen("SQLITE_OPEN_CREATE") && 0 == strcmp(flag, "SQLITE_OPEN_CREATE"))
	{
		return SQLITE_OPEN_CREATE;
	}
	else
	if (strlen(flag) == strlen("SQLITE_OPEN_URI") && 0 == strcmp(flag, "SQLITE_OPEN_URI"))
	{
		return SQLITE_OPEN_URI;
	}
	else
	if (strlen(flag) == strlen("SQLITE_OPEN_MEMORY") && 0 == strcmp(flag, "SQLITE_OPEN_MEMORY"))
	{
		return SQLITE_OPEN_MEMORY;
	}
	else
	if (strlen(flag) == strlen("SQLITE_OPEN_NOMUTEX") && 0 == strcmp(flag, "SQLITE_OPEN_NOMUTEX"))
	{
		return SQLITE_OPEN_NOMUTEX;
	}
	else
	if (strlen(flag) == strlen("SQLITE_OPEN_FULLMUTEX") && 0 == strcmp(flag, "SQLITE_OPEN_FULLMUTEX"))
	{
		return SQLITE_OPEN_FULLMUTEX;
	}
	else
	if (strlen(flag) == strlen("SQLITE_OPEN_SHAREDCACHE") && 0 == strcmp(flag, "SQLITE_OPEN_SHAREDCACHE"))
	{
		return SQLITE_OPEN_SHAREDCACHE;
	}
	else
	if (strlen(flag) == strlen("SQLITE_OPEN_PRIVATECACHE") && 0 == strcmp(flag, "SQLITE_OPEN_PRIVATECACHE"))
	{
		return SQLITE_OPEN_PRIVATECACHE;
	}
	else
	if (strlen(flag) == strlen("SQLITE_OPEN_EXRESCODE") && 0 == strcmp(flag, "SQLITE_OPEN_EXRESCODE"))
	{
		return SQLITE_OPEN_EXRESCODE;
	}
	else
	if (strlen(flag) == strlen("SQLITE_OPEN_NOFOLLOW") && 0 == strcmp(flag, "SQLITE_OPEN_NOFOLLOW"))
	{
		return SQLITE_OPEN_NOFOLLOW;
	}
	else
	{
		return -1;
	}
}

void SqliteOpenFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	sqlite3 *db = NULL;
	int flag;
	int flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE;
	const char *vfs = NULL;

	UDFNextArgument(context,LEXEME_BITS,&theArg);
	const char *path = theArg.lexemeValue->contents;

	if(UDFHasNextArgument(context))
	{
		UDFNextArgument(context,MULTIFIELD_BIT|LEXEME_BITS,&theArg);
		if (theArg.header->type != MULTIFIELD_TYPE && theArg.header->type != SYMBOL_TYPE && theArg.header->type != STRING_TYPE)
		{
			WriteString(theEnv, STDERR, "sqlite-open: third argument must be a multifield, symbol, or string\n");
			returnValue->lexemeValue = FalseSymbol(theEnv);
			return;
		}
		else
		if (theArg.header->type == MULTIFIELD_TYPE)
		{
			if (theArg.multifieldValue->length > 0)
			{
				flags = 0;
			}
			for (int x = 0; x < theArg.multifieldValue->length; x++)
			{
				if (theArg.multifieldValue->contents[x].header->type == SYMBOL_TYPE || theArg.multifieldValue->contents[x].header->type == STRING_TYPE)
				{
					flag = OpenFlagToInt(theArg.multifieldValue->contents[x].lexemeValue->contents);
					if (flag != -1)
					{
						flags |= flag;
					}
				}
			}
		}
		else
		{
			flags = 0;
			flag = OpenFlagToInt(theArg.lexemeValue->contents);
			if (flag != -1)
			{
				flags = flag;
			}
		}
	}

	if(UDFHasNextArgument(context))
	{
		UDFNextArgument(context,LEXEME_BITS,&theArg);
		vfs = theArg.lexemeValue->contents;
	}

	if (sqlite3_open_v2(path, &db, flags, vfs) != SQLITE_OK || db == NULL)
	{
		WriteString(theEnv, STDERR, "sqlite-open: could not open database ");
		WriteString(theEnv, STDERR, path);
		WriteString(theEnv, STDERR, ": ");
		WriteString(theEnv, STDERR, sqlite3_errmsg(db));
		WriteString(theEnv, STDERR, "\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		if (db) {
			sqlite3_close(db);
		}
		return;
	}

	returnValue->externalAddressValue = CreateCExternalAddress(theEnv, (void*)db);
}

void SqliteCloseFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;

	UDFNextArgument(context,EXTERNAL_ADDRESS_BIT,&theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-close: first arg must be a database pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	if (!theArg.externalAddressValue->contents)
	{
		WriteString(theEnv, STDERR, "sqlite-close: database pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	if (sqlite3_close((sqlite3 *)theArg.externalAddressValue->contents) != SQLITE_OK)
	{
		WriteString(theEnv, STDERR, "sqlite-close: could not close database: ");
		WriteString(theEnv, STDERR, sqlite3_errmsg(theArg.externalAddressValue->contents));
		WriteString(theEnv, STDERR, "\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	theArg.externalAddressValue->contents = NULL;
	returnValue->lexemeValue = TrueSymbol(theEnv);
}

void SqliteChangesFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;

	UDFNextArgument(context,EXTERNAL_ADDRESS_BIT,&theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-changes: first arg must be a database pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	if (!theArg.externalAddressValue->contents)
	{
		WriteString(theEnv, STDERR, "sqlite-changes: database pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	returnValue->integerValue = CreateInteger(theEnv, sqlite3_changes((sqlite3 *)theArg.externalAddressValue->contents));
}

void SqliteTotalChangesFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;

	UDFNextArgument(context,EXTERNAL_ADDRESS_BIT,&theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-total-changes: first arg must be a database pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	if (!theArg.externalAddressValue->contents)
	{
		WriteString(theEnv, STDERR, "sqlite-total-changes: database pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	returnValue->integerValue = CreateInteger(theEnv, sqlite3_total_changes((sqlite3 *)theArg.externalAddressValue->contents));
}

void SqliteLastInsertRowidFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;

	UDFNextArgument(context,EXTERNAL_ADDRESS_BIT,&theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-last-insert-rowid: first arg must be a database pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	if (!theArg.externalAddressValue->contents)
	{
		WriteString(theEnv, STDERR, "sqlite-last-insert-rowid: database pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	returnValue->integerValue = CreateInteger(theEnv, sqlite3_last_insert_rowid((sqlite3 *)theArg.externalAddressValue->contents));
}

void SqliteDbNameFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	sqlite3 *db = NULL;
	const char *name;

	UDFNextArgument(context,EXTERNAL_ADDRESS_BIT,&theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-db-name: first arg must be a database pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	db = (sqlite3 *)theArg.externalAddressValue->contents;
	if (!db)
	{
		WriteString(theEnv, STDERR, "sqlite-db-name: database pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	UDFNextArgument(context,INTEGER_BIT,&theArg);
	if (!(name = sqlite3_db_name(db, theArg.integerValue->contents)))
	{
		WriteString(theEnv, STDERR, "sqlite-db-name: out of range\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	returnValue->lexemeValue = CreateString(theEnv, name);
}

void SqliteDbFilenameFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	sqlite3 *db = NULL;
	const char *name;

	UDFNextArgument(context,EXTERNAL_ADDRESS_BIT,&theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-db-filename: first arg must be a database pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	db = (sqlite3 *)theArg.externalAddressValue->contents;
	if (!db)
	{
		WriteString(theEnv, STDERR, "sqlite-db-filename: database pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	UDFNextArgument(context,LEXEME_BITS,&theArg);
	name = sqlite3_db_filename(db, theArg.lexemeValue->contents);
	if (name == NULL || name[0] == '\0')
	{
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	returnValue->lexemeValue = CreateString(theEnv, name);
}

void SqliteDbReadonlyFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	sqlite3 *db = NULL;

	UDFNextArgument(context,EXTERNAL_ADDRESS_BIT,&theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-db-readonly: first arg must be a database pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	db = (sqlite3 *)theArg.externalAddressValue->contents;
	if (!db)
	{
		WriteString(theEnv, STDERR, "sqlite-db-readonly: database pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	UDFNextArgument(context,LEXEME_BITS,&theArg);
	switch(sqlite3_db_readonly(db, theArg.lexemeValue->contents))
	{
		case 1:
			returnValue->lexemeValue = TrueSymbol(theEnv);
			return;
		case 0:
			returnValue->lexemeValue = FalseSymbol(theEnv);
			return;
		case -1:
			WriteString(theEnv, STDERR, "sqlite-db-readonly: no such database ");
			WriteString(theEnv, STDERR, theArg.lexemeValue->contents);
			WriteString(theEnv, STDERR, " on connection\n");
			returnValue->lexemeValue = FalseSymbol(theEnv);
			return;
	}
}

void SqliteDbExistsFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	sqlite3 *db = NULL;

	UDFNextArgument(context,EXTERNAL_ADDRESS_BIT,&theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-db-exists: first arg must be a database pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	db = (sqlite3 *)theArg.externalAddressValue->contents;
	if (!db)
	{
		WriteString(theEnv, STDERR, "sqlite-db-exists: database pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	UDFNextArgument(context,LEXEME_BITS,&theArg);
	switch(sqlite3_db_readonly(db, theArg.lexemeValue->contents))
	{
		case 1:
			returnValue->lexemeValue = TrueSymbol(theEnv);
			return;
		case 0:
			returnValue->lexemeValue = TrueSymbol(theEnv);
			return;
		case -1:
			returnValue->lexemeValue = FalseSymbol(theEnv);
			return;
	}
}

void SqlitePrepareFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	sqlite3_stmt *stmt;
	sqlite3 *db = NULL;

	UDFNextArgument(context,EXTERNAL_ADDRESS_BIT,&theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-prepare: first arg must be a database pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	db = (sqlite3 *)theArg.externalAddressValue->contents;
	if (!db)
	{
		WriteString(theEnv, STDERR, "sqlite-prepare: database pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	UDFNextArgument(context,LEXEME_BITS,&theArg);
	if (sqlite3_prepare_v2(db, theArg.lexemeValue->contents, -1, &stmt, NULL) != SQLITE_OK || stmt == NULL) {
		WriteString(theEnv, STDERR, "sqlite-prepare: prepare failed: ");
		WriteString(theEnv, STDERR, sqlite3_errmsg(db));
		WriteString(theEnv, STDERR, "\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	returnValue->externalAddressValue = CreateCExternalAddress(theEnv, (void*)stmt);
}

void SqliteStmtExplainFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	sqlite3_stmt *stmt;
	sqlite3 *db = NULL;

	UDFNextArgument(context, EXTERNAL_ADDRESS_BIT, &theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-stmt-explain: first arg must be a statement pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	if (!(stmt = (sqlite3_stmt *) theArg.externalAddressValue->contents)) {
		WriteString(theEnv, STDERR, "sqlite-stmt-explain: statement pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	db = sqlite3_db_handle(stmt);

	UDFNextArgument(context, INTEGER_BIT, &theArg);
	if (theArg.header->type != INTEGER_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-stmt-explain: second arg must be an integer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	if (theArg.integerValue->contents != 0 && theArg.integerValue->contents != 1 && theArg.integerValue->contents != 2)
	{
		WriteString(theEnv, STDERR, "sqlite-stmt-explain: second arg must 0, 1, or 2\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	if (sqlite3_stmt_explain(stmt, theArg.integerValue->contents) != SQLITE_OK)
	{
		WriteString(theEnv, STDERR, "sqlite-stmt-explain: \n");
		WriteString(theEnv, STDERR, sqlite3_errmsg(db));
		WriteString(theEnv, STDERR, "\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	returnValue->lexemeValue = TrueSymbol(theEnv);
}

void SqliteStmtIsexplainFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	sqlite3_stmt *stmt = NULL;
	sqlite3 *db = NULL;

	UDFNextArgument(context, EXTERNAL_ADDRESS_BIT, &theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-stmt-isexplain: first arg must be a statement pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	if (!(stmt = (sqlite3_stmt *) theArg.externalAddressValue->contents)) {
		WriteString(theEnv, STDERR, "sqlite-stmt-isexplain: statement pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	db = sqlite3_db_handle(stmt);

	switch (sqlite3_stmt_isexplain(stmt))
	{
		case 0:
			returnValue->lexemeValue = FalseSymbol(theEnv);
			return;
		case 1:
			returnValue->lexemeValue = CreateString(theEnv, "EXPLAIN");
			return;
		case 2:
			returnValue->lexemeValue = CreateString(theEnv, "EXPLAIN QUERY PLAN");
			return;
		default:
			WriteString(theEnv, STDERR, "sqlite-stmt-explain: \n");
			WriteString(theEnv, STDERR, sqlite3_errmsg(db));
			WriteString(theEnv, STDERR, "\n");
			returnValue->lexemeValue = FalseSymbol(theEnv);
			return;

	}
}

static int bind_one_CV(sqlite3_stmt *stmt, int idx, Environment *theEnv, CLIPSValue *v)
{
	if (v->header->type == SYMBOL_TYPE && v->lexemeValue == CreateSymbol(theEnv, "nil"))
		return sqlite3_bind_null(stmt, idx);

	switch (v->header->type)
	{
		case INTEGER_TYPE:
			return sqlite3_bind_int64(stmt, idx, v->integerValue->contents);

		case FLOAT_TYPE:
			return sqlite3_bind_double(stmt, idx, v->floatValue->contents);

		case STRING_TYPE:
		case SYMBOL_TYPE:
		case INSTANCE_NAME_TYPE:
			return sqlite3_bind_text(stmt, idx, v->lexemeValue->contents, -1, SQLITE_TRANSIENT);

		case EXTERNAL_ADDRESS_TYPE:
			/* Unsupported here; bind NULL (or change to blob if you carry a size separately). */
			return sqlite3_bind_null(stmt, idx);

		case FACT_ADDRESS_TYPE:
		case INSTANCE_ADDRESS_TYPE:
		case MULTIFIELD_TYPE:
		default:
			/* Unsupported scalar types for a single bind -> NULL */
			return sqlite3_bind_null(stmt, idx);
	}
}

static int bind_one(sqlite3_stmt *stmt, int idx, Environment *theEnv, UDFValue *v)
{
	if (v->header->type == SYMBOL_TYPE && v->lexemeValue == CreateSymbol(theEnv, "nil"))
		return sqlite3_bind_null(stmt, idx);

	switch (v->header->type)
	{
		case INTEGER_TYPE:
			return sqlite3_bind_int64(stmt, idx, v->integerValue->contents);

		case FLOAT_TYPE:
			return sqlite3_bind_double(stmt, idx, v->floatValue->contents);

		case STRING_TYPE:
		case SYMBOL_TYPE:
		case INSTANCE_NAME_TYPE:
			return sqlite3_bind_text(stmt, idx, v->lexemeValue->contents, -1, SQLITE_TRANSIENT);

		case EXTERNAL_ADDRESS_TYPE:
			/* Unsupported here; bind NULL (or change to blob if you carry a size separately). */
			return sqlite3_bind_null(stmt, idx);

		case FACT_ADDRESS_TYPE:
		case INSTANCE_ADDRESS_TYPE:
		case MULTIFIELD_TYPE:
		default:
			/* Unsupported scalar types for a single bind -> NULL */
			return sqlite3_bind_null(stmt, idx);
	}
}

void SqliteBindFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue a1, a2, a3;
	sqlite3_stmt *stmt = NULL;
	sqlite3 *db = NULL;
	int argc = UDFArgumentCount(context);
	int inherit;
	Defclass *d;

	UDFNextArgument(context, EXTERNAL_ADDRESS_BIT, &a1);
	if (a1.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-bind: first arg must be a statement pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	stmt = (sqlite3_stmt *) a1.externalAddressValue->contents;
	if (!stmt)
	{
		WriteString(theEnv, STDERR, "sqlite-bind: statement pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	db = sqlite3_db_handle(stmt);

	UDFNextArgument(context, ANY_TYPE_BITS, &a2);
	size_t n;
	CLIPSValue cv, out;
	switch (a2.header->type)
	{
		case MULTIFIELD_TYPE:
			n = a2.multifieldValue->length;
			for (size_t i = 0; i < n; ++i)
			{
				UDFValue fv;
				fv.header = a2.multifieldValue->contents[i].header;
				fv.value  = a2.multifieldValue->contents[i].value;
				int rc = bind_one(stmt, (int)i + 1, theEnv, &fv);
				if (rc != SQLITE_OK)
				{
					WriteString(theEnv, STDERR, "sqlite-bind: ordered bind failed: ");
					WriteString(theEnv, STDERR, sqlite3_errmsg(db));
					WriteString(theEnv, STDERR, "\n");
					returnValue->lexemeValue = FalseSymbol(theEnv);
					return;
				}
			}
			break;
		case FACT_ADDRESS_TYPE:
			FactSlotNames(a2.factValue, &cv);
			n = cv.multifieldValue->length;
			for (size_t i = 0; i < n; ++i)
			{
				const char *name;
				if (cv.multifieldValue->contents[i].header->type != SYMBOL_TYPE)
				{
					WriteString(theEnv, STDERR, "sqlite-bind: The fact's slot name was not a symbol\n");
					returnValue->lexemeValue = FalseSymbol(theEnv);
					return;
				}
				name = cv.multifieldValue->contents[i].lexemeValue->contents;
				int idx = sqlite3_bind_parameter_index(stmt, name);
				if (idx == 0)
				{
					continue;
				}
				GetFactSlot(a2.factValue, name, &out);
				int rc = bind_one_CV(stmt, idx, theEnv, &out);
				if (rc != SQLITE_OK)
				{
					WriteString(theEnv, STDERR, "sqlite-bind: bind from fact failed: ");
					WriteString(theEnv, STDERR, sqlite3_errmsg(db));
					WriteString(theEnv, STDERR, "\n");
					returnValue->lexemeValue = FalseSymbol(theEnv);
					return;
				}
			}
			break;
		case INSTANCE_NAME_TYPE:
			inherit = true;
			if (argc == 3)
			{
				UDFNextArgument(context, LEXEME_BITS, &a3);
				if (a3.header->type == SYMBOL_TYPE && a3.lexemeValue == FalseSymbol(theEnv))
				{
					inherit = false;
				}
			}
			Instance *in = FindInstance(theEnv, NULL, a2.lexemeValue->contents, true);
			if (in == NULL)
			{
				WriteString(theEnv, STDERR, "sqlite-bind: instance with name ");
				WriteString(theEnv, STDERR, a2.lexemeValue->contents);
				WriteString(theEnv, STDERR, " not found\n");
				returnValue->lexemeValue = FalseSymbol(theEnv);
				return;
			}
			d = InstanceClass(in);
			ClassSlots(d, &cv, inherit);
			n = cv.multifieldValue->length;
			for (size_t i = 0; i < n; ++i)
			{
				const char *name;
				if (cv.multifieldValue->contents[i].header->type != SYMBOL_TYPE)
				{
					WriteString(theEnv, STDERR, "sqlite-bind: The instance's slot name was not a symbol\n");
					returnValue->lexemeValue = FalseSymbol(theEnv);
					return;
				}
				name = cv.multifieldValue->contents[i].lexemeValue->contents;
				int idx = sqlite3_bind_parameter_index(stmt, name);
				if (idx == 0)
				{
					continue;
				}
				DirectGetSlot(in, name, &out);
				int rc = bind_one_CV(stmt, idx, theEnv, &out);
				if (rc != SQLITE_OK)
				{
					WriteString(theEnv, STDERR, "sqlite-bind: bind from instance failed: ");
					WriteString(theEnv, STDERR, sqlite3_errmsg(db));
					WriteString(theEnv, STDERR, "\n");
					returnValue->lexemeValue = FalseSymbol(theEnv);
					return;
				}
			}
			break;
		case INSTANCE_ADDRESS_TYPE:
			inherit = true;
			if (argc == 3)
			{
				UDFNextArgument(context, LEXEME_BITS, &a3);
				if (a3.header->type == SYMBOL_TYPE && a3.lexemeValue == FalseSymbol(theEnv))
				{
					inherit = false;
				}
			}
			d = InstanceClass(a2.instanceValue);
			ClassSlots(d, &cv, inherit);
			n = cv.multifieldValue->length;
			for (size_t i = 0; i < n; ++i)
			{
				const char *name;
				if (cv.multifieldValue->contents[i].header->type != SYMBOL_TYPE)
				{
					WriteString(theEnv, STDERR, "sqlite-bind: The instance's slot name was not a symbol\n");
					returnValue->lexemeValue = FalseSymbol(theEnv);
					return;
				}
				name = cv.multifieldValue->contents[i].lexemeValue->contents;
				int idx = sqlite3_bind_parameter_index(stmt, name);
				if (idx == 0)
				{
					continue;
				}
				DirectGetSlot(a2.instanceValue, name, &out);
				int rc = bind_one_CV(stmt, idx, theEnv, &out);
				if (rc != SQLITE_OK)
				{
					WriteString(theEnv, STDERR, "sqlite-bind: bind from instance failed: ");
					WriteString(theEnv, STDERR, sqlite3_errmsg(db));
					WriteString(theEnv, STDERR, "\n");
					returnValue->lexemeValue = FalseSymbol(theEnv);
					return;
				}
			}
			break;
		case SYMBOL_TYPE:
		case STRING_TYPE:
			if (argc == 2)
			{
				int rc = bind_one(stmt, 1, theEnv, &a2);
				if (rc != SQLITE_OK)
				{
					WriteString(theEnv, STDERR, "sqlite-bind: bind(1) failed: ");
					WriteString(theEnv, STDERR, sqlite3_errmsg(db));
					WriteString(theEnv, STDERR, "\n");
					returnValue->lexemeValue = FalseSymbol(theEnv);
					return;
				}
			}
			else
			if (argc == 3)
			{
				UDFNextArgument(context, ANY_TYPE_BITS, &a3);
				const char *name = a2.lexemeValue->contents;
				int idx = sqlite3_bind_parameter_index(stmt, name);
				if (idx == 0)
				{
					WriteString(theEnv, STDERR, "sqlite-bind: unknown named parameter: ");
					WriteString(theEnv, STDERR, name);
					WriteString(theEnv, STDERR, "\n");
					returnValue->lexemeValue = FalseSymbol(theEnv);
					return;
				}

				int rc = bind_one(stmt, idx, theEnv, &a3);
				if (rc != SQLITE_OK)
				{
					WriteString(theEnv, STDERR, "sqlite-bind: named bind failed: ");
					WriteString(theEnv, STDERR, sqlite3_errmsg(db));
					WriteString(theEnv, STDERR, "\n");
					returnValue->lexemeValue = FalseSymbol(theEnv);
					return;
				}
			}
			else
			{
				WriteString(theEnv, STDERR, "sqlite-bind: expected 2 or 3 arguments\n");
				returnValue->lexemeValue = FalseSymbol(theEnv);
				return;
			}
			break;
		case INTEGER_TYPE:
			if (argc == 2)
			{
				int rc = bind_one(stmt, 1, theEnv, &a2);
				if (rc != SQLITE_OK)
				{
					WriteString(theEnv, STDERR, "sqlite-bind: bind(1) failed: ");
					WriteString(theEnv, STDERR, sqlite3_errmsg(db));
					WriteString(theEnv, STDERR, "\n");
					returnValue->lexemeValue = FalseSymbol(theEnv);
					return;
				}
			}
			else
			if (argc == 3)
			{
				UDFNextArgument(context, ANY_TYPE_BITS, &a3);
				int idx = (int) a2.integerValue->contents;
				if (idx <= 0)
				{
					WriteString(theEnv, STDERR, "sqlite-bind: parameter index must be >= 1\n");
					returnValue->lexemeValue = FalseSymbol(theEnv);
					return;
				}

				int rc = bind_one(stmt, idx, theEnv, &a3);
				if (rc != SQLITE_OK)
				{
					WriteString(theEnv, STDERR, "sqlite-bind: positional bind failed: ");
					WriteString(theEnv, STDERR, sqlite3_errmsg(db));
					WriteString(theEnv, STDERR, "\n");
					returnValue->lexemeValue = FalseSymbol(theEnv);
					return;
				}
			}
			else
			{
				WriteString(theEnv, STDERR, "sqlite-bind: expected 2 or 3 arguments\n");
				returnValue->lexemeValue = FalseSymbol(theEnv);
				return;
			}
			break;
		default:
			int rc = bind_one(stmt, 1, theEnv, &a2);
			if (rc != SQLITE_OK)
			{
				WriteString(theEnv, STDERR, "sqlite-bind: bind(1) failed: ");
				WriteString(theEnv, STDERR, sqlite3_errmsg(db));
				WriteString(theEnv, STDERR, "\n");
				returnValue->lexemeValue = FalseSymbol(theEnv);
				return;
			}
			break;
	}
	returnValue->lexemeValue = TrueSymbol(theEnv);
}

void SqliteFinalizeFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	int rc;
	sqlite3_stmt *stmt = NULL;

	UDFNextArgument(context, EXTERNAL_ADDRESS_BIT, &theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-finalize: first arg must be a statement pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	if (!(stmt = (sqlite3_stmt *) theArg.externalAddressValue->contents)) {
		WriteString(theEnv, STDERR, "sqlite-finalize: statement pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	if ((rc = sqlite3_finalize(stmt)) != SQLITE_OK) {
		WriteString(theEnv, STDERR, "sqlite-finalize: finalize failed: ");
		WriteString(theEnv, STDERR, sqlite3_errstr(rc));
		WriteString(theEnv, STDERR, "\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	theArg.externalAddressValue->contents = NULL;

	returnValue->lexemeValue = TrueSymbol(theEnv);
}

void SqliteBindParameterCountFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	sqlite3_stmt *stmt = NULL;

	UDFNextArgument(context, EXTERNAL_ADDRESS_BIT, &theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-bind-param-count: first arg must be a statement pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	if (!(stmt = (sqlite3_stmt *) theArg.externalAddressValue->contents)) {
		WriteString(theEnv, STDERR, "sqlite-bind-param-count: statement pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	returnValue->integerValue = CreateInteger(theEnv, sqlite3_bind_parameter_count(stmt));
}

void SqliteBindParameterIndexFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	sqlite3_stmt *stmt;
	int index;

	UDFNextArgument(context, EXTERNAL_ADDRESS_BIT, &theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-bind-parameter-index: first arg must be a statement pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	if (!(stmt = (sqlite3_stmt *) theArg.externalAddressValue->contents)) {
		WriteString(theEnv, STDERR, "sqlite-bind-parameter-index: statement pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	UDFNextArgument(context, LEXEME_BITS, &theArg);
	if (theArg.header->type != SYMBOL_TYPE && theArg.header->type != STRING_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-bind-parameter-index: second arg must be a symbol or string\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	if (!(index = sqlite3_bind_parameter_index(stmt, theArg.lexemeValue->contents)))
	{
		WriteString(theEnv, STDERR, "sqlite-bind-parameter-index: something went wrong getting the bind parameter index\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	returnValue->integerValue = CreateInteger(theEnv, index);
}

void SqliteBindParameterNameFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	sqlite3_stmt *stmt;
	const char *name;

	UDFNextArgument(context, EXTERNAL_ADDRESS_BIT, &theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-bind-parameter-name: first arg must be a statement pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	if (!(stmt = (sqlite3_stmt *) theArg.externalAddressValue->contents)) {
		WriteString(theEnv, STDERR, "sqlite-bind-parameter-name: statement pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	UDFNextArgument(context, INTEGER_BIT, &theArg);
	if (theArg.header->type != INTEGER_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-bind-parameter-name: second arg must be an integer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	if (!(name = sqlite3_bind_parameter_name(stmt, theArg.integerValue->contents)))
	{
		WriteString(theEnv, STDERR, "sqlite-bind-parameter-name: something went wrong getting the bind parameter name\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	returnValue->lexemeValue = CreateSymbol(theEnv, name);
}

void SqliteSqlFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	sqlite3_stmt *stmt;

	UDFNextArgument(context, EXTERNAL_ADDRESS_BIT, &theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-sql: first arg must be a statement pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	if (!(stmt = (sqlite3_stmt *) theArg.externalAddressValue->contents)) {
		WriteString(theEnv, STDERR, "sqlite-sql: statement pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	const char *sql = sqlite3_sql(stmt);
	if (!sql)
	{
		WriteString(theEnv, STDERR, "sqlite-sql: could not generate SQL string for statement");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	returnValue->lexemeValue = CreateString(theEnv, sql);
}

void SqliteExpandedSqlFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	sqlite3_stmt *stmt;

	UDFNextArgument(context, EXTERNAL_ADDRESS_BIT, &theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-expanded-sql: first arg must be a statement pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	if (!(stmt = (sqlite3_stmt *) theArg.externalAddressValue->contents)) {
		WriteString(theEnv, STDERR, "sqlite-expanded-sql: statement pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	char *sql = sqlite3_expanded_sql(stmt);
	if (!sql)
	{
		WriteString(theEnv, STDERR, "sqlite-expanded-sql: could not generate SQL string for statement");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	returnValue->lexemeValue = CreateString(theEnv, sql);

	sqlite3_free(sql);
}

#ifdef SQLITE_ENABLE_NORMALIZE
void SqliteNormalizedSqlFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	sqlite3_stmt *stmt;

	UDFNextArgument(context, EXTERNAL_ADDRESS_BIT, &theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-normalized-sql: first arg must be a statement pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	if (!(stmt = (sqlite3_stmt *) theArg.externalAddressValue->contents)) {
		WriteString(theEnv, STDERR, "sqlite-normalized-sql: statement pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	char *sql = sqlite3_normalized_sql(stmt);
	if (!sql)
	{
		WriteString(theEnv, STDERR, "sqlite-normalized-sql: could not generate SQL string for statement");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	returnValue->lexemeValue = CreateString(theEnv, sql);
}
#endif

void SqliteResetFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	sqlite3_stmt *stmt;
	int rc;
	sqlite3 *db;

	UDFNextArgument(context, EXTERNAL_ADDRESS_BIT, &theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-reset: first arg must be a statement pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	if (!(stmt = (sqlite3_stmt *) theArg.externalAddressValue->contents)) {
		WriteString(theEnv, STDERR, "sqlite-reset: statement pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	db = sqlite3_db_handle(stmt);
	rc = sqlite3_reset(stmt);

	if (rc != SQLITE_OK)
	{
		WriteString(theEnv, STDERR, "sqlite-reset: reset failed: ");
		WriteString(theEnv, STDERR, sqlite3_errmsg(db));
		WriteString(theEnv, STDERR, "\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	returnValue->lexemeValue = TrueSymbol(theEnv);
}

void SqliteClearBindingsFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	sqlite3_stmt *stmt;
	int rc;
	sqlite3 *db;

	UDFNextArgument(context, EXTERNAL_ADDRESS_BIT, &theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-clear-bindings: first arg must be a statement pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	if (!(stmt = (sqlite3_stmt *) theArg.externalAddressValue->contents)) {
		WriteString(theEnv, STDERR, "sqlite-clear-bindings: statement pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	db = sqlite3_db_handle(stmt);
	rc = sqlite3_clear_bindings(stmt);

	if (rc != SQLITE_OK)
	{
		WriteString(theEnv, STDERR, "sqlite-clear-bindings: ");
		WriteString(theEnv, STDERR, sqlite3_errmsg(db));
		WriteString(theEnv, STDERR, "\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	returnValue->lexemeValue = TrueSymbol(theEnv);
}

void SqliteStepFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	sqlite3_stmt *stmt;
	int rc;
	sqlite3 *db;

	UDFNextArgument(context, EXTERNAL_ADDRESS_BIT, &theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-step: first arg must be a statement pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	if (!(stmt = (sqlite3_stmt *) theArg.externalAddressValue->contents)) {
		WriteString(theEnv, STDERR, "sqlite-step: statement pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	db = sqlite3_db_handle(stmt);
	rc = sqlite3_step(stmt);

	switch(rc)
	{
		case SQLITE_ROW:
			returnValue->lexemeValue = CreateSymbol(theEnv, "SQLITE_ROW");
			return;
		case SQLITE_DONE:
			returnValue->lexemeValue = CreateSymbol(theEnv, "SQLITE_DONE");
			return;
		default:
			WriteString(theEnv, STDERR, "sqlite-step: ");
			WriteString(theEnv, STDERR, sqlite3_errmsg(db));
			WriteString(theEnv, STDERR, "\n");
			returnValue->lexemeValue = FalseSymbol(theEnv);
			return;
	}

}

void SqliteColumnCountFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	sqlite3_stmt *stmt;

	UDFNextArgument(context, EXTERNAL_ADDRESS_BIT, &theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-column-count: first arg must be a statement pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	if (!(stmt = (sqlite3_stmt *) theArg.externalAddressValue->contents)) {
		WriteString(theEnv, STDERR, "sqlite-column-count: statement pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	returnValue->integerValue = CreateInteger(theEnv, sqlite3_column_count(stmt));
}

void SqliteColumnDatabaseNameFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	sqlite3_stmt *stmt;
	const char *name;
	int column = 0;

	UDFNextArgument(context, EXTERNAL_ADDRESS_BIT, &theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-column-database-name: first arg must be a statement pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	if (!(stmt = (sqlite3_stmt *) theArg.externalAddressValue->contents)) {
		WriteString(theEnv, STDERR, "sqlite-column-database-name: statement pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	if (UDFHasNextArgument(context))
	{
		UDFNextArgument(context, INTEGER_BIT, &theArg);
		if (theArg.header->type != INTEGER_TYPE)
		{
			WriteString(theEnv, STDERR, "sqlite-column-database-name: second arg must be an integer\n");
			returnValue->lexemeValue = FalseSymbol(theEnv);
			return;
		}
		column = theArg.integerValue->contents;
	}

	if (!(name = sqlite3_column_database_name(stmt, column)))
	{
		WriteString(theEnv, STDERR, "sqlite-column-database-name: could not get database name from that column\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	returnValue->lexemeValue = CreateString(theEnv, name);
}

void SqliteColumnOriginNameFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	sqlite3_stmt *stmt;
	const char *name;
	int column = 0;

	UDFNextArgument(context, EXTERNAL_ADDRESS_BIT, &theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-column-origin-name: first arg must be a statement pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	if (!(stmt = (sqlite3_stmt *) theArg.externalAddressValue->contents)) {
		WriteString(theEnv, STDERR, "sqlite-column-origin-name: statement pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	if (UDFHasNextArgument(context))
	{
		UDFNextArgument(context, INTEGER_BIT, &theArg);
		if (theArg.header->type != INTEGER_TYPE)
		{
			WriteString(theEnv, STDERR, "sqlite-column-origin-name: second arg must be an integer\n");
			returnValue->lexemeValue = FalseSymbol(theEnv);
			return;
		}
		column = theArg.integerValue->contents;
	}

	if (!(name = sqlite3_column_origin_name(stmt, column)))
	{
		WriteString(theEnv, STDERR, "sqlite-column-origin-name: could not get origin name from that column\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	returnValue->lexemeValue = CreateString(theEnv, name);
}

void SqliteColumnTableNameFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	sqlite3_stmt *stmt;
	const char *name;
	int column = 0;

	UDFNextArgument(context, EXTERNAL_ADDRESS_BIT, &theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-column-table-name: first arg must be a statement pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	if (!(stmt = (sqlite3_stmt *) theArg.externalAddressValue->contents)) {
		WriteString(theEnv, STDERR, "sqlite-column-table-name: statement pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	if (UDFHasNextArgument(context))
	{
		UDFNextArgument(context, INTEGER_BIT, &theArg);
		if (theArg.header->type != INTEGER_TYPE)
		{
			WriteString(theEnv, STDERR, "sqlite-column-table-name: second arg must be an integer\n");
			returnValue->lexemeValue = FalseSymbol(theEnv);
			return;
		}
		column = theArg.integerValue->contents;
	}

	if (!(name = sqlite3_column_table_name(stmt, column)))
	{
		WriteString(theEnv, STDERR, "sqlite-column-table-name: could not get table name from that column\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	returnValue->lexemeValue = CreateString(theEnv, name);
}

void SqliteColumnNameFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	sqlite3_stmt *stmt;
	const char *name;

	UDFNextArgument(context, EXTERNAL_ADDRESS_BIT, &theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-column-name: first arg must be a statement pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	if (!(stmt = (sqlite3_stmt *) theArg.externalAddressValue->contents)) {
		WriteString(theEnv, STDERR, "sqlite-column-name: statement pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	UDFNextArgument(context, INTEGER_BIT, &theArg);
	if (theArg.header->type != INTEGER_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-column-name: second arg must be an integer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	if (!(name = sqlite3_column_name(stmt, theArg.integerValue->contents)))
	{
		WriteString(theEnv, STDERR, "sqlite-column-name: something went wrong getting the column name\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	returnValue->lexemeValue = CreateString(theEnv, name);
}

void SqliteColumnTypeFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	sqlite3_stmt *stmt;

	UDFNextArgument(context, EXTERNAL_ADDRESS_BIT, &theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-column-type: first arg must be a statement pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	if (!(stmt = (sqlite3_stmt *) theArg.externalAddressValue->contents)) {
		WriteString(theEnv, STDERR, "sqlite-column-type: statement pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	UDFNextArgument(context, INTEGER_BIT, &theArg);
	if (theArg.header->type != INTEGER_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-column-type: second arg must be an integer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	switch (sqlite3_column_type(stmt, theArg.integerValue->contents))
	{
		case SQLITE_INTEGER:
			returnValue->lexemeValue = CreateSymbol(theEnv, "SQLITE_INTEGER");
			break;
		case SQLITE_FLOAT:
			returnValue->lexemeValue = CreateSymbol(theEnv, "SQLITE_FLOAT");
			break;
		case SQLITE_TEXT:
			returnValue->lexemeValue = CreateSymbol(theEnv, "SQLITE_TEXT");
			break;
		case SQLITE_BLOB:
			returnValue->lexemeValue = CreateSymbol(theEnv, "SQLITE_BLOB");
			break;
		case SQLITE_NULL:
			returnValue->lexemeValue = CreateSymbol(theEnv, "SQLITE_NULL");
			break;
		default:
			WriteString(theEnv, STDERR, "sqlite-column-type: column has unrecognized sqlite type\n");
			returnValue->lexemeValue = FalseSymbol(theEnv);
			break;
	}
}

void SqliteColumnFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	sqlite3_stmt *stmt;

	UDFNextArgument(context, EXTERNAL_ADDRESS_BIT, &theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-column: first arg must be a statement pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	if (!(stmt = (sqlite3_stmt *) theArg.externalAddressValue->contents)) {
		WriteString(theEnv, STDERR, "sqlite-column: statement pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	UDFNextArgument(context, INTEGER_BIT, &theArg);
	if (theArg.header->type != INTEGER_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-column: second arg must be an integer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

        switch (sqlite3_column_type(stmt, theArg.integerValue->contents))
	{
		case SQLITE_INTEGER:
			returnValue->integerValue = CreateInteger(theEnv, (long long)sqlite3_column_int64(stmt,theArg.integerValue->contents));
			break;
		case SQLITE_FLOAT:
			returnValue->floatValue = CreateFloat(theEnv, sqlite3_column_double(stmt,theArg.integerValue->contents));
			break;
		case SQLITE_TEXT:
			returnValue->lexemeValue = CreateString(theEnv, (const char *)sqlite3_column_text(stmt,theArg.integerValue->contents));
			break;
		case SQLITE_BLOB:
			returnValue->lexemeValue = CreateString(theEnv, sqlite3_column_blob(stmt,theArg.integerValue->contents));
			break;
		case SQLITE_NULL:
			returnValue->lexemeValue = CreateSymbol(theEnv, "nil");
			break;
		default:
			WriteString(theEnv, STDERR, "sqlite-column: SQLite column has unexpected type\n");
			returnValue->lexemeValue = FalseSymbol(theEnv);
			break;
	}
}

void SqliteDataCountFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	sqlite3_stmt *stmt;

	UDFNextArgument(context, EXTERNAL_ADDRESS_BIT, &theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-data-count: first arg must be a statement pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	if (!(stmt = (sqlite3_stmt *) theArg.externalAddressValue->contents)) {
		WriteString(theEnv, STDERR, "sqlite-data-count: statement pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	returnValue->integerValue = CreateInteger(theEnv, sqlite3_data_count(stmt));
}


void SqliteErrmsgFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;

	UDFNextArgument(context,EXTERNAL_ADDRESS_BIT,&theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-err-code: first arg must be a database pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	if (!theArg.externalAddressValue->contents)
	{
		WriteString(theEnv, STDERR, "sqlite-err-code: database pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	
	returnValue->lexemeValue = CreateString(theEnv, sqlite3_errmsg((sqlite3 *)theArg.externalAddressValue->contents));
}

void SqliteBusyTimeoutFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	sqlite3 *db = NULL;

	UDFNextArgument(context,EXTERNAL_ADDRESS_BIT,&theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-busy-timeout: first arg must be a database pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	db = (sqlite3 *)theArg.externalAddressValue->contents;
	if (!db)
	{
		WriteString(theEnv, STDERR, "sqlite-busy-timeout: database pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	UDFNextArgument(context,INTEGER_BIT,&theArg);
	if (SQLITE_OK != sqlite3_busy_timeout(db, theArg.integerValue->contents))
	{
		WriteString(theEnv, STDERR, "sqlite-busy-timeout: ");
		WriteString(theEnv, STDERR, sqlite3_errmsg(db));
		WriteString(theEnv, STDERR, "\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	returnValue->lexemeValue = TrueSymbol(theEnv);
}

void SqliteRowToMultifieldFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	sqlite3_stmt *stmt;
	MultifieldBuilder *mb;

	UDFNextArgument(context, EXTERNAL_ADDRESS_BIT, &theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-row-to-multifield: first arg must be a statement pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	if (!(stmt = (sqlite3_stmt *) theArg.externalAddressValue->contents)) {
		WriteString(theEnv, STDERR, "sqlite-row-to-multifield: statement pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	mb = CreateMultifieldBuilder(theEnv, 0);
	for (int x = 0; x < sqlite3_column_count(stmt); x++)
	{
		switch (sqlite3_column_type(stmt, x))
		{
			case SQLITE_INTEGER:
				MBAppendInteger(mb, (long long)sqlite3_column_int64(stmt,x));
				break;
			case SQLITE_FLOAT:
				MBAppendFloat(mb, sqlite3_column_double(stmt,x));
				break;
			case SQLITE_TEXT:
				MBAppendString(mb, (const char *)sqlite3_column_text(stmt,x));
				break;
			case SQLITE_BLOB:
				MBAppendString(mb, sqlite3_column_blob(stmt,x));
				break;
			case SQLITE_NULL:
				MBAppendSymbol(mb, "nil");
				break;
			default:
				WriteString(theEnv, STDERR, "sqlite-column: SQLite column has unexpected type\n");
				MBAppendSymbol(mb, "<unknown>");
				break;
		}
	}

	returnValue->multifieldValue = MBCreate(mb);

	MBDispose(mb);
}

void SqliteRowToFactFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	sqlite3_stmt *stmt;
	FactBuilder *fb;
	Fact *f;

	UDFNextArgument(context, EXTERNAL_ADDRESS_BIT, &theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-row-to-fact: first arg must be a statement pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	if (!(stmt = (sqlite3_stmt *) theArg.externalAddressValue->contents)) {
		WriteString(theEnv, STDERR, "sqlite-row-to-fact: statement pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	UDFNextArgument(context, SYMBOL_BIT, &theArg);
	if (theArg.header->type != SYMBOL_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-row-to-fact: second arg must be a symbol\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	fb = CreateFactBuilder(theEnv, theArg.lexemeValue->contents);
	switch(FBError(theEnv))
	{
		case FBE_DEFTEMPLATE_NOT_FOUND_ERROR:
			WriteString(theEnv, STDERR, "sqlite-row-to-fact: second arg must be an existing deftemplate\n");
			FBDispose(fb);
			returnValue->lexemeValue = FalseSymbol(theEnv);
			return;
		case FBE_IMPLIED_DEFTEMPLATE_ERROR:
			WriteString(theEnv, STDERR, "sqlite-row-to-fact: second arg cannot be the implied deftemplate\n");
			FBDispose(fb);
			returnValue->lexemeValue = FalseSymbol(theEnv);
			return;
		case FBE_NO_ERROR:
			break;
		default:
			WriteString(theEnv, STDERR, "sqlite-row-to-fact: something unexpected happened when creating FactBuilder\n");
			FBDispose(fb);
			returnValue->lexemeValue = FalseSymbol(theEnv);
			return;
	}
	for (int x = 0; x < sqlite3_column_count(stmt); x++)
	{
		switch (sqlite3_column_type(stmt, x))
		{
			case SQLITE_INTEGER:
				FBPutSlotInteger(fb, sqlite3_column_name(stmt, x), (long long)sqlite3_column_int64(stmt,x));
				break;
			case SQLITE_FLOAT:
				FBPutSlotFloat(fb, sqlite3_column_name(stmt, x), sqlite3_column_double(stmt,x));
				break;
			case SQLITE_TEXT:
				FBPutSlotString(fb, sqlite3_column_name(stmt, x), (const char *)sqlite3_column_text(stmt,x));
				break;
			case SQLITE_BLOB:
				FBPutSlotString(fb, sqlite3_column_name(stmt, x), sqlite3_column_blob(stmt,x));
				break;
			case SQLITE_NULL:
				FBPutSlotSymbol(fb, sqlite3_column_name(stmt, x), "nil");
				break;
			default:
				WriteString(theEnv, STDERR, "sqlite-column: SQLite column has unexpected type\n");
				FBPutSlotSymbol(fb, sqlite3_column_name(stmt, x), "<unknown>");
				break;
		}
	}

	f = FBAssert(fb);

	if (f == NULL)
	{
		switch(FBError(theEnv))
		{
			case FBE_NO_ERROR:
				break;
			case FBE_NULL_POINTER_ERROR:
				WriteString(theEnv, STDERR, "sqlite-row-to-fact: no deftemplate associated with FactBuilder\n");
				FBDispose(fb);
				returnValue->lexemeValue = FalseSymbol(theEnv);
				return;
			case FBE_COULD_NOT_ASSERT_ERROR:
				WriteString(theEnv, STDERR, "sqlite-row-to-fact: could not assert Fact from FactBuilder\n");
				FBDispose(fb);
				returnValue->lexemeValue = FalseSymbol(theEnv);
				return;
			case FBE_RULE_NETWORK_ERROR:
				WriteString(theEnv, STDERR, "sqlite-row-to-fact: an error occurred while assertion was being processed by the rule network\n");
				FBDispose(fb);
				returnValue->lexemeValue = FalseSymbol(theEnv);
				return;
			default:
				WriteString(theEnv, STDERR, "sqlite-row-to-fact: something unexpected happened when asserting Fact from FactBuilder\n");
				FBDispose(fb);
				returnValue->lexemeValue = FalseSymbol(theEnv);
				return;
		}
	}

	returnValue->factValue = f;

	FBDispose(fb);
}

void SqliteRowToInstanceFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	sqlite3_stmt *stmt;
	const char *defclassName, *instanceName, *nameSlotReplacement, *columnName;
	InstanceBuilder *ib;
	Instance *i;

	UDFNextArgument(context, EXTERNAL_ADDRESS_BIT, &theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-row-to-instance: first arg must be a statement pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	if (!(stmt = (sqlite3_stmt *) theArg.externalAddressValue->contents)) {
		WriteString(theEnv, STDERR, "sqlite-row-to-instance: statement pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	UDFNextArgument(context, SYMBOL_BIT, &theArg);
	if (theArg.header->type != SYMBOL_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-row-to-instance: second arg must be a symbol\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	defclassName = theArg.lexemeValue->contents;

	instanceName = NULL;
	if (UDFHasNextArgument(context))
	{
		UDFNextArgument(context, SYMBOL_BIT, &theArg);
		if (theArg.header->type != SYMBOL_TYPE)
		{
			WriteString(theEnv, STDERR, "sqlite-row-to-instance: third arg must be a symbol\n");
			returnValue->lexemeValue = FalseSymbol(theEnv);
			return;
		}
		if (0 != strcmp("nil", theArg.lexemeValue->contents) || strlen("nil") != strlen(theArg.lexemeValue->contents))
		{
			instanceName = theArg.lexemeValue->contents;
		}
	}

	nameSlotReplacement = "_name";
	if (UDFHasNextArgument(context))
	{
		UDFNextArgument(context, SYMBOL_BIT, &theArg);
		if (theArg.header->type != SYMBOL_TYPE)
		{
			WriteString(theEnv, STDERR, "sqlite-row-to-instance: fourth arg must be a symbol\n");
			returnValue->lexemeValue = FalseSymbol(theEnv);
			return;
		}
		nameSlotReplacement = theArg.lexemeValue->contents;
	}

	ib = CreateInstanceBuilder(theEnv, defclassName);
	switch(IBError(theEnv))
	{
		case IBE_DEFCLASS_NOT_FOUND_ERROR:
			WriteString(theEnv, STDERR, "sqlite-row-to-instance: second arg must be an existing defclass\n");
			IBDispose(ib);
			returnValue->lexemeValue = FalseSymbol(theEnv);
			return;
		case IBE_NO_ERROR:
			break;
		default:
			WriteString(theEnv, STDERR, "sqlite-row-to-instance: something unexpected happened when creating InstanceBuilder\n");
			IBDispose(ib);
			returnValue->lexemeValue = FalseSymbol(theEnv);
			return;
	}

	for (int x = 0; x < sqlite3_column_count(stmt); x++)
	{
		columnName = sqlite3_column_name(stmt, x);
		if (strlen("name") == strlen(columnName) && 0 == strcmp("name", columnName))
		{
			columnName = nameSlotReplacement;
		}
		switch (sqlite3_column_type(stmt, x))
		{
			case SQLITE_INTEGER:
				IBPutSlotInteger(ib, columnName, (long long)sqlite3_column_int64(stmt,x));
				break;
			case SQLITE_FLOAT:
				IBPutSlotFloat(ib, columnName, sqlite3_column_double(stmt,x));
				break;
			case SQLITE_TEXT:
				IBPutSlotString(ib, columnName, (const char *)sqlite3_column_text(stmt,x));
				break;
			case SQLITE_BLOB:
				IBPutSlotString(ib, columnName, sqlite3_column_blob(stmt,x));
				break;
			case SQLITE_NULL:
				IBPutSlotSymbol(ib, columnName, "nil");
				break;
			default:
				WriteString(theEnv, STDERR, "sqlite-row-to-instance: SQLite column has unexpected type\n");
				IBPutSlotSymbol(ib, columnName, "<unknown>");
				break;
		}
	}

	i = IBMake(ib, instanceName);

	if (i == NULL)
	{
		switch(FBError(theEnv))
		{
			case IBE_NO_ERROR:
				break;
			case IBE_NULL_POINTER_ERROR:
				WriteString(theEnv, STDERR, "sqlite-row-to-instance: no deftemplate associated with InstanceBuilder\n");
				IBDispose(ib);
				returnValue->lexemeValue = FalseSymbol(theEnv);
				return;
			case IBE_COULD_NOT_CREATE_ERROR:
				WriteString(theEnv, STDERR, "sqlite-row-to-instance: could not make Instance from InstanceBuilder\n");
				IBDispose(ib);
				returnValue->lexemeValue = FalseSymbol(theEnv);
				return;
			case IBE_RULE_NETWORK_ERROR:
				WriteString(theEnv, STDERR, "sqlite-row-to-instance: an error occurred while assertion was being processed by the rule network\n");
				IBDispose(ib);
				returnValue->lexemeValue = FalseSymbol(theEnv);
				return;
			default:
				WriteString(theEnv, STDERR, "sqlite-row-to-instance: something unexpected happened when making Instance from InstanceBuilder\n");
				IBDispose(ib);
				returnValue->lexemeValue = FalseSymbol(theEnv);
				return;
		}
	}

	returnValue->instanceValue = i;

	IBDispose(ib);
}

void SqliteLimitFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	sqlite3 *db = NULL;
	int id;
	int newVal = -1;

	UDFNextArgument(context, EXTERNAL_ADDRESS_BIT, &theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-limit: first arg must be a database pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	db = (sqlite3 *) theArg.externalAddressValue->contents;
	if (!db)
	{
		WriteString(theEnv, STDERR, "sqlite-limit: database pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	UDFNextArgument(context, INTEGER_BIT|LEXEME_BITS, &theArg);
	if (theArg.header->type == INTEGER_TYPE && theArg.integerValue->contents >= 0 && theArg.integerValue->contents <= 11)
	{
		id = theArg.integerValue->contents;
	}
	else if (0 == strcmp(theArg.lexemeValue->contents, "SQLITE_LIMIT_LENGTH"))
	{
		id = SQLITE_LIMIT_LENGTH;
	}
	else if (0 == strcmp(theArg.lexemeValue->contents, "SQLITE_LIMIT_SQL_LENGTH"))
	{
		id = SQLITE_LIMIT_SQL_LENGTH;
	}
	else if (0 == strcmp(theArg.lexemeValue->contents, "SQLITE_LIMIT_COLUMN"))
	{
		id = SQLITE_LIMIT_COLUMN;
	}
	else if (0 == strcmp(theArg.lexemeValue->contents, "SQLITE_LIMIT_EXPR_DEPTH"))
	{
		id = SQLITE_LIMIT_EXPR_DEPTH;
	}
	else if (0 == strcmp(theArg.lexemeValue->contents, "SQLITE_LIMIT_COMPOUND_SELECT"))
	{
		id = SQLITE_LIMIT_COMPOUND_SELECT;
	}
	else if (0 == strcmp(theArg.lexemeValue->contents, "SQLITE_LIMIT_VDBE_OP"))
	{
		id = SQLITE_LIMIT_VDBE_OP;
	}
	else if (0 == strcmp(theArg.lexemeValue->contents, "SQLITE_LIMIT_FUNCTION_ARG"))
	{
		id = SQLITE_LIMIT_FUNCTION_ARG;
	}
	else if (0 == strcmp(theArg.lexemeValue->contents, "SQLITE_LIMIT_ATTACHED"))
	{
		id = SQLITE_LIMIT_ATTACHED;
	}
	else if (0 == strcmp(theArg.lexemeValue->contents, "SQLITE_LIMIT_LIKE_PATTERN_LENGTH"))
	{
		id = SQLITE_LIMIT_LIKE_PATTERN_LENGTH;
	}
	else if (0 == strcmp(theArg.lexemeValue->contents, "SQLITE_LIMIT_VARIABLE_NUMBER"))
	{
		id = SQLITE_LIMIT_VARIABLE_NUMBER;
	}
	else if (0 == strcmp(theArg.lexemeValue->contents, "SQLITE_LIMIT_TRIGGER_DEPTH"))
	{
		id = SQLITE_LIMIT_TRIGGER_DEPTH;
	}
	else if (0 == strcmp(theArg.lexemeValue->contents, "SQLITE_LIMIT_WORKER_THREADS"))
	{
		id = SQLITE_LIMIT_WORKER_THREADS;
	}
	else
	{
		WriteString(theEnv, STDERR, "sqlite-limit: Unknown id");
		WriteString(theEnv, STDERR, theArg.lexemeValue->contents);
		WriteString(theEnv, STDERR, "\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	if (UDFHasNextArgument(context))
	{
		UDFNextArgument(context, INTEGER_BIT, &theArg);
		newVal = theArg.integerValue->contents;
	}

	returnValue->integerValue = CreateInteger(theEnv, sqlite3_limit(db, id, newVal));
}

void SqliteSleepFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;

	UDFNextArgument(context,INTEGER_BIT,&theArg);
	if (theArg.header->type != INTEGER_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-sleep: first arg must be number of milliseconds as an integer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	
	returnValue->integerValue = CreateInteger(theEnv, sqlite3_sleep(theArg.integerValue->contents));
}

void SqliteBackupInitFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	sqlite3_backup *backup;
	sqlite3 *db1, *db2 = NULL;
	const char *name1, *name2;

	UDFNextArgument(context,EXTERNAL_ADDRESS_BIT,&theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-backup-init: first arg must be a database pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	db1 = (sqlite3 *)theArg.externalAddressValue->contents;
	if (!db1)
	{
		WriteString(theEnv, STDERR, "sqlite-backup-init: first database pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	UDFNextArgument(context, LEXEME_BITS, &theArg);
	if (theArg.header->type != SYMBOL_TYPE && theArg.header->type != STRING_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-backup-init: second arg must be a symbol or string\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	name1 = theArg.lexemeValue->contents;

	UDFNextArgument(context,EXTERNAL_ADDRESS_BIT,&theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-backup-init: third arg must be a database pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	db2 = (sqlite3 *)theArg.externalAddressValue->contents;
	if (!db2)
	{
		WriteString(theEnv, STDERR, "sqlite-backup-init: second database pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	UDFNextArgument(context, LEXEME_BITS, &theArg);
	if (theArg.header->type != SYMBOL_TYPE && theArg.header->type != STRING_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-backup-init: fourth arg must be a symbol or string\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	name2 = theArg.lexemeValue->contents;

	if (NULL == (backup = sqlite3_backup_init(db1, name1, db2, name2)))
	{
		WriteString(theEnv, STDERR, "sqlite-backup-init: ");
		WriteString(theEnv, STDERR, sqlite3_errmsg(db1));
		WriteString(theEnv, STDERR, "\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	returnValue->externalAddressValue = CreateCExternalAddress(theEnv, (void*)backup);
}

void SqliteBackupStepFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;
	sqlite3_backup *backup = NULL;
	int rc;

	UDFNextArgument(context,EXTERNAL_ADDRESS_BIT,&theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-backup-step: first arg must be a backup pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	backup = (sqlite3_backup *)theArg.externalAddressValue->contents;
	if (!backup)
	{
		WriteString(theEnv, STDERR, "sqlite-backup-step: backup pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	UDFNextArgument(context,INTEGER_BIT,&theArg);

	rc = sqlite3_backup_step(backup, theArg.integerValue->contents);
	switch(rc)
	{
		case SQLITE_OK:
			returnValue->lexemeValue = CreateSymbol(theEnv, "SQLITE_OK");
			return;
		case SQLITE_BUSY:
			returnValue->lexemeValue = CreateSymbol(theEnv, "SQLITE_BUSY");
			return;
		case SQLITE_LOCKED:
			returnValue->lexemeValue = CreateSymbol(theEnv, "SQLITE_LOCKED");
			return;
		case SQLITE_NOMEM:
			returnValue->lexemeValue = CreateSymbol(theEnv, "SQLITE_NOMEM");
			return;
		case SQLITE_READONLY:
			returnValue->lexemeValue = CreateSymbol(theEnv, "SQLITE_READONLY");
			return;
		case SQLITE_DONE:
			returnValue->lexemeValue = CreateSymbol(theEnv, "SQLITE_DONE");
			return;
		default:
			returnValue->integerValue = CreateInteger(theEnv, rc);
			return;
	}
}

void SqliteBackupPagecountFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;

	UDFNextArgument(context,EXTERNAL_ADDRESS_BIT,&theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-backup-pagecount: first arg must be a backup pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	if (!theArg.externalAddressValue->contents)
	{
		WriteString(theEnv, STDERR, "sqlite-backup-pagecount: backup pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	
	returnValue->integerValue = CreateInteger(theEnv, sqlite3_backup_pagecount((sqlite3_backup *)theArg.externalAddressValue->contents));
}

void SqliteBackupRemainingFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;

	UDFNextArgument(context,EXTERNAL_ADDRESS_BIT,&theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-backup-remaining: first arg must be a backup pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	if (!theArg.externalAddressValue->contents)
	{
		WriteString(theEnv, STDERR, "sqlite-backup-remaining: backup pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	
	returnValue->integerValue = CreateInteger(theEnv, sqlite3_backup_remaining((sqlite3_backup *)theArg.externalAddressValue->contents));
}

void SqliteBackupFinishFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	UDFValue theArg;

	UDFNextArgument(context,EXTERNAL_ADDRESS_BIT,&theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-backup-finish: first arg must be a backup pointer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	if (!theArg.externalAddressValue->contents)
	{
		WriteString(theEnv, STDERR, "sqlite-backup-finish: backup pointer is NULL\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
	if (sqlite3_backup_finish((sqlite3_backup *)theArg.externalAddressValue->contents) != SQLITE_OK)
	{
		WriteString(theEnv, STDERR, "sqlite-backup-finish: could not finish backup: ");
		WriteString(theEnv, STDERR, sqlite3_errmsg(theArg.externalAddressValue->contents));
		WriteString(theEnv, STDERR, "\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	theArg.externalAddressValue->contents = NULL;
	returnValue->lexemeValue = TrueSymbol(theEnv);
}

/*********************************************************/
/* UserFunctions: Informs the expert system environment  */
/*   of any user defined functions. In the default case, */
/*   there are no user defined functions. To define      */
/*   functions, either this function must be replaced by */
/*   a function with the same name within this file, or  */
/*   this function can be deleted from this file and     */
/*   included in another file.                           */
/*********************************************************/
void UserFunctions(
		Environment *env)
{
#if MAC_XCD
#pragma unused(env)
#endif

	AddUDF(env,"sqlite-libversion","y",0,0,NULL,SqliteLibversionFunction,"SqliteLibversionFunction",NULL);
	AddUDF(env,"sqlite-libversion-number","l",0,0,NULL,SqliteLibversionNumberFunction,"SqliteLibversionNumberFunction",NULL);
	AddUDF(env,"sqlite-sourceid","y",0,0,NULL,SqliteSourceidFunction,"SqliteSourceidFunction",NULL);
	AddUDF(env,"sqlite-threadsafe","b",0,0,NULL,SqliteThreadsafeFunction,"SqliteThreadsafeFunction",NULL);
	AddUDF(env,"sqlite-memory-used","l",0,0,NULL,SqliteMemoryUsedFunction,"SqliteMemoryUsedFunction",NULL);
	AddUDF(env,"sqlite-memory-highwater","l",0,1,";b",SqliteMemoryHighwaterFunction,"SqliteMemoryHighwaterFunction",NULL);

	AddUDF(env,"sqlite-compileoption-get","y",1,1,";l",SqliteCompileoptionGetFunction,"SqliteCompileoptionGetFunction",NULL);
	AddUDF(env,"sqlite-compileoption-used","b",1,1,";sy",SqliteCompileoptionUsedFunction,"SqliteCompileoptionUsedFunction",NULL);

	AddUDF(env,"sqlite-open","e",1,3,";sy;sym;sy",SqliteOpenFunction,"SqliteOpenFunction",NULL);
	AddUDF(env,"sqlite-close","b",1,1,";e",SqliteCloseFunction,"SqliteCloseFunction",NULL);
	AddUDF(env,"sqlite-changes","bl",1,1,";e",SqliteChangesFunction,"SqliteChangesFunction",NULL);
	AddUDF(env,"sqlite-total-changes","bl",1,1,";e",SqliteTotalChangesFunction,"SqliteTotalChangesFunction",NULL);
	AddUDF(env,"sqlite-last-insert-rowid","bl",1,1,";e",SqliteLastInsertRowidFunction,"SqliteLastInsertRowidFunction",NULL);
	AddUDF(env,"sqlite-db-name","bs",2,2,";e;l",SqliteDbNameFunction,"SqliteDbNameFunction",NULL);
	AddUDF(env,"sqlite-db-filename","bs",2,2,";e;sy",SqliteDbFilenameFunction,"SqliteDbFilenameFunction",NULL);
	AddUDF(env,"sqlite-db-readonly","bs",2,2,";e;sy",SqliteDbReadonlyFunction,"SqliteDbReadonlyFunction",NULL);
	AddUDF(env,"sqlite-db-exists","bs",2,2,";e;sy",SqliteDbExistsFunction,"SqliteDbExistsFunction",NULL);
	AddUDF(env,"sqlite-prepare","be",2,2,";e;s",SqlitePrepareFunction,"SqlitePrepareFunction",NULL);
	AddUDF(env,"sqlite-stmt-explain","bly",2,2,";e;l",SqliteStmtExplainFunction,"SqliteStmtExplainFunction",NULL);
	AddUDF(env,"sqlite-stmt-isexplain","by",1,1,";e",SqliteStmtIsexplainFunction,"SqliteStmtIsexplainFunction",NULL);
	AddUDF(env,"sqlite-bind","be",2,3,";e;*;*",SqliteBindFunction,"SqliteBindFunction",NULL);
	AddUDF(env,"sqlite-finalize","b",1,1,";e",SqliteFinalizeFunction,"SqliteFinalizeFunction",NULL);
	AddUDF(env,"sqlite-bind-parameter-count","bl",1,1,";e",SqliteBindParameterCountFunction,"SqliteBindParameterCountFunction",NULL);
	AddUDF(env,"sqlite-bind-parameter-index","bl",2,2,";e;sy",SqliteBindParameterIndexFunction,"SqliteBindParameterIndexFunction",NULL);
	AddUDF(env,"sqlite-bind-parameter-name","by",2,2,";e;l",SqliteBindParameterNameFunction,"SqliteBindParameterNameFunction",NULL);
	AddUDF(env,"sqlite-sql","bs",1,1,";e",SqliteSqlFunction,"SqliteSqlFunction",NULL);
	AddUDF(env,"sqlite-expanded-sql","bs",1,1,";e",SqliteExpandedSqlFunction,"SqliteExpandedSqlFunction",NULL);
#ifdef SQLITE_ENABLE_NORMALIZE
	AddUDF(env,"sqlite-normalized-sql","bs",1,1,";e",SqliteNormalizedSqlFunction,"SqliteNormalizedSqlFunction",NULL);
#endif
	AddUDF(env,"sqlite-reset","b",1,1,";e",SqliteResetFunction,"SqliteResetFunction",NULL);
	AddUDF(env,"sqlite-clear-bindings","b",1,1,";e",SqliteClearBindingsFunction,"SqliteClearBindingsFunction",NULL);
	AddUDF(env,"sqlite-step","by",1,1,";e",SqliteStepFunction,"SqliteStepFunction",NULL);
	AddUDF(env,"sqlite-row-to-multifield","bm",1,1,";e",SqliteRowToMultifieldFunction,"SqliteRowToMultifieldFunction",NULL);
	AddUDF(env,"sqlite-row-to-fact","bf",2,2,";e;y",SqliteRowToFactFunction,"SqliteRowToFactFunction",NULL);
	AddUDF(env,"sqlite-row-to-instance","bi",2,4,";e;y;y;y",SqliteRowToInstanceFunction,"SqliteRowToInstanceFunction",NULL);
	AddUDF(env,"sqlite-column-count","bl",1,1,";e",SqliteColumnCountFunction,"SqliteColumnCountFunction",NULL);
	AddUDF(env,"sqlite-column-database-name","bs",2,2,";e;l",SqliteColumnDatabaseNameFunction,"SqliteColumnDatabaseNameFunction",NULL);
	AddUDF(env,"sqlite-column-origin-name","bs",2,2,";e;l",SqliteColumnOriginNameFunction,"SqliteColumnOriginNameFunction",NULL);
	AddUDF(env,"sqlite-column-table-name","bs",2,2,";e;l",SqliteColumnTableNameFunction,"SqliteColumnTableNameFunction",NULL);
	AddUDF(env,"sqlite-column-name","bs",2,2,";e;l",SqliteColumnNameFunction,"SqliteColumnNameFunction",NULL);
	AddUDF(env,"sqlite-column-type","by",2,2,";e;l",SqliteColumnTypeFunction,"SqliteColumnTypeFunction",NULL);
	AddUDF(env,"sqlite-column","bdls",2,2,";e;l",SqliteColumnFunction,"SqliteColumnFunction",NULL);
	AddUDF(env,"sqlite-data-count","bl",1,1,";e",SqliteDataCountFunction,"SqliteDataCountFunction",NULL);

	AddUDF(env,"sqlite-errmsg","bs",1,1,";e",SqliteErrmsgFunction,"SqliteErrmsgFunction",NULL);

	AddUDF(env,"sqlite-busy-timeout","b",2,2,";e;l",SqliteBusyTimeoutFunction,"SqliteBusyTimeoutFunction",NULL);
	AddUDF(env,"sqlite-limit","bl",2,3,";e;lsy;l",SqliteLimitFunction,"SqliteLimitFunction",NULL);
	AddUDF(env,"sqlite-sleep","bl",1,1,";l",SqliteSleepFunction,"SqliteSleepFunction",NULL);

	AddUDF(env,"sqlite-backup-init","be",4,4,";e;sy;e;sy",SqliteBackupInitFunction,"SqliteBackupInitFunction",NULL);
	AddUDF(env,"sqlite-backup-step","bly",2,2,";e;l",SqliteBackupStepFunction,"SqliteBackupStepFunction",NULL);
	AddUDF(env,"sqlite-backup-pagecount","bl",1,1,";e",SqliteBackupPagecountFunction,"SqliteBackupPagecountFunction",NULL);
	AddUDF(env,"sqlite-backup-remaining","bl",1,1,";e",SqliteBackupRemainingFunction,"SqliteBackupRemainingFunction",NULL);
	AddUDF(env,"sqlite-backup-finish","bl",1,1,";e",SqliteBackupFinishFunction,"SqliteBackupFinishFunction",NULL);
}
