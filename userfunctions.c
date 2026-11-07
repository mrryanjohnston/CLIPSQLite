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

/* sqlite3_stmt_explain() arrived in SQLite 3.43.0 */
#if SQLITE_VERSION_NUMBER < 3043000
#error "CLIPSQLite requires SQLite 3.43.0 or newer."
#endif

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
	if (theArg.header->type != SYMBOL_TYPE && theArg.header->type != STRING_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-open: first arg must be a symbol or a string\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
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
		if (theArg.header->type != SYMBOL_TYPE && theArg.header->type != STRING_TYPE)
		{
			WriteString(theEnv, STDERR, "sqlite-open: third arg must be a symbol or a string\n");
			returnValue->lexemeValue = FalseSymbol(theEnv);
			return;
		}
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
	if (theArg.header->type != INTEGER_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-db-name: second arg must be an integer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
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
			Instance *in = FindInstanceBySymbol(theEnv, a2.lexemeValue);
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

	rc = sqlite3_finalize(stmt);

	/* sqlite3_finalize releases the statement whatever it answers: anything
	   but SQLITE_OK is the error of the statement's most recent step, reported
	   once more on the way out.  So the handle is emptied either way -- left
	   as it was, a second finalize would free the statement twice. */
	theArg.externalAddressValue->contents = NULL;

	if (rc != SQLITE_OK) {
		WriteString(theEnv, STDERR, "sqlite-finalize: finalize failed: ");
		WriteString(theEnv, STDERR, sqlite3_errstr(rc));
		WriteString(theEnv, STDERR, "\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

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
	if (theArg.header->type != INTEGER_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-busy-timeout: second arg must be an integer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}
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
				WriteString(theEnv, STDERR, "sqlite-row-to-fact: no Fact was asserted and the FactBuilder reports no error\n");
				FBDispose(fb);
				returnValue->lexemeValue = FalseSymbol(theEnv);
				return;
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
		switch(IBError(theEnv))
		{
			case IBE_NO_ERROR:
				WriteString(theEnv, STDERR, "sqlite-row-to-instance: no Instance was made and the InstanceBuilder reports no error\n");
				IBDispose(ib);
				returnValue->lexemeValue = FalseSymbol(theEnv);
				return;
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

/* ====================================================================== */
/* A whole statement, or a whole query, into working memory at once.      */
/*                                                                        */
/* sqlite-row-to-fact and its siblings map the row under the cursor and   */
/* leave the stepping to the caller.  The six wrappers below do the loop: */
/* they walk every row a statement has left to give, and answer one       */
/* multifield of what they made -- fact addresses, instance addresses, or */
/* the values themselves laid end to end.  The query-taking half prepares */
/* the SQL, walks it, and finalizes it before returning.                  */
/* ====================================================================== */

static const char *SqliteWMNoun(unsigned short kind)
{
	return (FACT_ADDRESS_TYPE == kind) ? "deftemplate" : "defclass";
}

/* The instance names a caller asked for, in row order. */
typedef struct {
	CLIPSLexeme **items;   /* NULL when none were given */
	size_t count;
} SqliteInstanceNames;

/* The name for one row, or NULL to let CLIPS name it. */
static const char *SqliteInstanceNameForRow(const SqliteInstanceNames *names, size_t row)
{
	if (NULL == names || row >= names->count) return NULL;
	return names->items[row]->contents;
}

static void SqliteFreeInstanceNames(Environment *theEnv, SqliteInstanceNames *names)
{
	if (NULL == names->items) return;
	genfree(theEnv, names->items, names->count * sizeof(CLIPSLexeme *));
	names->items = NULL;
	names->count = 0;
}

static bool SqliteIsInstanceNameLexeme(unsigned short type)
{
	return SYMBOL_TYPE == type || STRING_TYPE == type || INSTANCE_NAME_TYPE == type;
}

/* Reads the optional instance-name argument the two instance forms take: one
   lexeme names the first row, a multifield names the rows it has entries for. */
static bool SqliteWMNamesFromValue(Environment *theEnv, const char *fn,
                                   UDFValue *theArg,
                                   SqliteInstanceNames *names,
                                   UDFValue *returnValue)
{
	Multifield *mf;
	size_t i;

	if (MULTIFIELD_TYPE != theArg->header->type)
	{
		if (!SqliteIsInstanceNameLexeme(theArg->header->type))
		{
			WriteString(theEnv, STDERR, fn);
			WriteString(theEnv, STDERR, ": the instance names must be a multifield, or one symbol, string or instance name\n");
			returnValue->lexemeValue = FalseSymbol(theEnv);
			return false;
		}

		names->items = (CLIPSLexeme **)genalloc(theEnv, sizeof(CLIPSLexeme *));
		names->items[0] = theArg->lexemeValue;
		names->count = 1;
		return true;
	}

	/* begin and range rather than the whole multifield: a $?rest bound on a
	   rule's LHS arrives as a window onto a longer one, and reading it from
	   field zero would name the rows after values the caller never passed. */
	mf = theArg->multifieldValue;
	if (0 == theArg->range) return true;   /* an empty list names nothing */

	names->items = (CLIPSLexeme **)genalloc(theEnv, theArg->range * sizeof(CLIPSLexeme *));
	names->count = theArg->range;

	for (i = 0; i < names->count; i++)
	{
		CLIPSValue *field = &mf->contents[theArg->begin + i];

		if (!SqliteIsInstanceNameLexeme(field->header->type))
		{
			WriteString(theEnv, STDERR, fn);
			WriteString(theEnv, STDERR, ": field ");
			WriteInteger(theEnv, STDERR, (long long)(i + 1));
			WriteString(theEnv, STDERR, " of the instance names is not a symbol, string or instance name\n");
			returnValue->lexemeValue = FalseSymbol(theEnv);
			SqliteFreeInstanceNames(theEnv, names);
			return false;
		}
		names->items[i] = field->lexemeValue;
	}
	return true;
}

/* Uppercases in place, ASCII only. */
static void SqliteUpcaseASCII(char *s)
{
	for (; '\0' != *s; s++)
	{
		if (*s >= 'a' && *s <= 'z') { *s = (char)(*s - 'a' + 'A'); }
	}
}

/* One cell of the current row as a CLIPS value: the same mapping
   sqlite-column uses, with a BLOB read as text so that the buffer SQLite
   hands back is one it has zero-terminated. */
static void SqliteColumnToCLIPSValue(Environment *theEnv, sqlite3_stmt *stmt,
                                     int col, CLIPSValue *cv)
{
	const unsigned char *text;

	switch (sqlite3_column_type(stmt, col))
	{
		case SQLITE_INTEGER:
			cv->integerValue = CreateInteger(theEnv, (long long)sqlite3_column_int64(stmt, col));
			break;
		case SQLITE_FLOAT:
			cv->floatValue = CreateFloat(theEnv, sqlite3_column_double(stmt, col));
			break;
		case SQLITE_TEXT:
		case SQLITE_BLOB:
			text = sqlite3_column_text(stmt, col);
			cv->lexemeValue = CreateString(theEnv, (NULL != text) ? (const char *)text : "");
			break;
		default:
			cv->lexemeValue = CreateSymbol(theEnv, "nil");
			break;
	}
}

/* The deftemplate or defclass name when the query-taking forms are not given
   one: the one table the result's columns come from.  Returns a string the
   caller frees, or NULL after saying why not. */
static char *SqliteInferConstructName(Environment *theEnv, const char *fn,
                                      sqlite3_stmt *stmt, unsigned short kind)
{
	int col_count = sqlite3_column_count(stmt);
	const char *found = NULL;
	char *copy;
	size_t len;
	int col;

	for (col = 0; col < col_count; col++)
	{
		const char *tn = sqlite3_column_table_name(stmt, col);

		if (NULL == tn) continue;   /* an expression, not a column of a table */
		if (NULL == found) { found = tn; continue; }
		if (0 != strcmp(found, tn))
		{
			WriteString(theEnv, STDERR, fn);
			WriteString(theEnv, STDERR, ": the query reads more than one table, so there is no single name to infer; name the ");
			WriteString(theEnv, STDERR, SqliteWMNoun(kind));
			WriteString(theEnv, STDERR, "\n");
			return NULL;
		}
	}

	if (NULL == found)
	{
		WriteString(theEnv, STDERR, fn);
		WriteString(theEnv, STDERR, ": no column of the query comes from a table, so there is no ");
		WriteString(theEnv, STDERR, SqliteWMNoun(kind));
		WriteString(theEnv, STDERR, " name to infer; name one\n");
		return NULL;
	}

	len = strlen(found);
	copy = (char *)genalloc(theEnv, len + 1);
	memcpy(copy, found, len + 1);
	if (INSTANCE_ADDRESS_TYPE == kind) { SqliteUpcaseASCII(copy); }
	return copy;
}

/* Says once that a row made nothing. */
static void SqliteWMReportRowLost(Environment *theEnv, const char *fn,
                                  const char *what, const char *name,
                                  bool *reported)
{
	if (*reported) return;
	*reported = true;

	WriteString(theEnv, STDERR, fn);
	WriteString(theEnv, STDERR, ": ");
	WriteString(theEnv, STDERR, what);
	WriteString(theEnv, STDERR, " ");
	WriteString(theEnv, STDERR, name);
	WriteString(theEnv, STDERR, " could be made for a row; those rows are skipped\n");
}

/* Walks the rows a statement has left, making one fact or instance per row,
   or appending every row to one multifield, and answers what it made in row
   order.  The row under the cursor, if the statement is sitting on one, is
   the first; then the statement is stepped until it is done, and reset. */
static void SqliteStmtToWorkingMemory(Environment *theEnv, const char *fn,
                                      sqlite3_stmt *stmt,
                                      unsigned short kind, const char *name,
                                      const SqliteInstanceNames *names,
                                      bool headers, UDFValue *returnValue)
{
	int col_count = sqlite3_column_count(stmt);
	Deftemplate *tmpl = NULL;
	Defclass *cls = NULL;
	FactBuilder *fb = NULL;
	InstanceBuilder *ib = NULL;
	MultifieldBuilder *mb;
	const char **slot_names;   /* per column: the slot it fills, or NULL to skip it */
	bool reported = false;
	/* CLIPS reports a build it refused by setting the evaluation error, and
	   that also halts execution -- after which the next row's slots are
	   refused too, and one lost row would quietly take the rest of the
	   statement with it.  The rows are independent, so the flags are put back
	   to what this call found them as and the row after gets its own attempt.
	   Only the build can do this; a slot value a constraint refuses does not
	   halt. */
	bool haltWas = GetHaltExecution(theEnv);
	bool errorWas = GetEvaluationError(theEnv);
	bool have_row;
	bool finished = false;
	size_t row = 0;
	int col;

	returnValue->lexemeValue = FalseSymbol(theEnv);

	if (FACT_ADDRESS_TYPE == kind)
	{
		fb = CreateFactBuilder(theEnv, name);
		switch (FBError(theEnv))
		{
			case FBE_NO_ERROR:
				break;
			case FBE_DEFTEMPLATE_NOT_FOUND_ERROR:
				WriteString(theEnv, STDERR, fn);
				WriteString(theEnv, STDERR, ": there is no deftemplate named ");
				WriteString(theEnv, STDERR, name);
				WriteString(theEnv, STDERR, "\n");
				FBDispose(fb);
				return;
			case FBE_IMPLIED_DEFTEMPLATE_ERROR:
				WriteString(theEnv, STDERR, fn);
				WriteString(theEnv, STDERR, ": ");
				WriteString(theEnv, STDERR, name);
				WriteString(theEnv, STDERR, " is the implied deftemplate of an ordered fact, which has no slots to fill\n");
				FBDispose(fb);
				return;
			default:
				WriteString(theEnv, STDERR, fn);
				WriteString(theEnv, STDERR, ": something unexpected happened when creating the FactBuilder\n");
				FBDispose(fb);
				return;
		}
		tmpl = FindDeftemplate(theEnv, name);
	}
	else if (INSTANCE_ADDRESS_TYPE == kind)
	{
		ib = CreateInstanceBuilder(theEnv, name);
		switch (IBError(theEnv))
		{
			case IBE_NO_ERROR:
				break;
			case IBE_DEFCLASS_NOT_FOUND_ERROR:
				WriteString(theEnv, STDERR, fn);
				WriteString(theEnv, STDERR, ": there is no defclass named ");
				WriteString(theEnv, STDERR, name);
				WriteString(theEnv, STDERR, "\n");
				IBDispose(ib);
				return;
			default:
				WriteString(theEnv, STDERR, fn);
				WriteString(theEnv, STDERR, ": something unexpected happened when creating the InstanceBuilder\n");
				IBDispose(ib);
				return;
		}
		cls = FindDefclass(theEnv, name);
	}

	/* Which columns land where is decided once, before the first row: a
	   column the shape has no slot for is skipped.  An instance's name is not
	   a slot, so under the instance form a column called "name" goes to the
	   slot "_name", the same as sqlite-row-to-instance does by default. */
	slot_names = (const char **)genalloc(theEnv, ((size_t)col_count + 1) * sizeof(const char *));
	for (col = 0; col < col_count; col++)
	{
		const char *cn = sqlite3_column_name(stmt, col);

		if (NULL == cn) { cn = ""; }
		if (NULL != fb)
		{
			slot_names[col] = DeftemplateSlotExistP(tmpl, cn) ? cn : NULL;
		}
		else if (NULL != ib)
		{
			if (0 == strcmp("name", cn)) { cn = "_name"; }
			slot_names[col] = SlotExistP(cls, cn, true) ? cn : NULL;
		}
		else { slot_names[col] = cn; }
	}

	mb = CreateMultifieldBuilder(theEnv, 0);

	if (MULTIFIELD_TYPE == kind && headers)
	{
		for (col = 0; col < col_count; col++) { MBAppendString(mb, slot_names[col]); }
	}

	/* sqlite3_data_count answers 0 unless the last step left a row ready */
	have_row = sqlite3_data_count(stmt) > 0;

	for (;;)
	{
		bool row_ok = true;

		if (!have_row)
		{
			int rc = sqlite3_step(stmt);

			if (SQLITE_DONE == rc) { finished = true; break; }
			if (SQLITE_ROW != rc)
			{
				WriteString(theEnv, STDERR, fn);
				WriteString(theEnv, STDERR, ": the statement failed while it was being stepped: ");
				WriteString(theEnv, STDERR, sqlite3_errmsg(sqlite3_db_handle(stmt)));
				WriteString(theEnv, STDERR, "\n");
				break;
			}
		}
		have_row = false;

		for (col = 0; col < col_count; col++)
		{
			CLIPSValue cv;
			PutSlotError pse;

			if (NULL == slot_names[col]) continue;

			SqliteColumnToCLIPSValue(theEnv, stmt, col, &cv);

			if (NULL == fb && NULL == ib)
			{
				MBAppend(mb, &cv);
				continue;
			}

			pse = (NULL != fb) ? FBPutSlot(fb, slot_names[col], &cv)
			                   : IBPutSlot(ib, slot_names[col], &cv);
			if (PSE_NO_ERROR == pse) continue;

			row_ok = false;
			if (!reported)
			{
				reported = true;
				WriteString(theEnv, STDERR, fn);
				WriteString(theEnv, STDERR, ": slot ");
				WriteString(theEnv, STDERR, slot_names[col]);
				WriteString(theEnv, STDERR, " of ");
				WriteString(theEnv, STDERR, name);
				WriteString(theEnv, STDERR, " would not take the value in column ");
				WriteInteger(theEnv, STDERR, (long long)col);
				WriteString(theEnv, STDERR, "; those rows are skipped\n");
			}
			break;
		}

		if (NULL != fb)
		{
			Fact *f;

			if (!row_ok) { FBAbort(fb); }
			else if (NULL != (f = FBAssert(fb))) { MBAppendFact(mb, f); }
			else
			{
				SqliteWMReportRowLost(theEnv, fn, "no fact of", name, &reported);
				SetEvaluationError(theEnv, errorWas);
				SetHaltExecution(theEnv, haltWas);
			}
		}
		else if (NULL != ib)
		{
			Instance *i;

			if (!row_ok) { IBAbort(ib); }
			else if (NULL != (i = IBMake(ib, SqliteInstanceNameForRow(names, row))))
			{
				MBAppendInstance(mb, i);
			}
			else
			{
				IBAbort(ib);
				SqliteWMReportRowLost(theEnv, fn, "no instance of", name, &reported);
				SetEvaluationError(theEnv, errorWas);
				SetHaltExecution(theEnv, haltWas);
			}
		}

		row++;
	}

	/* A statement stepped to SQLITE_DONE refuses a new binding until it is
	   reset, so a walk that reached the end leaves the statement reset: ready
	   to be bound and run again, and holding no lock on the database.  One
	   that stopped on an error is left as it is, so sqlite-reset can report
	   what went wrong. */
	if (finished) { sqlite3_reset(stmt); }

	if (NULL != fb) { FBDispose(fb); }
	if (NULL != ib) { IBDispose(ib); }
	genfree(theEnv, slot_names, ((size_t)col_count + 1) * sizeof(const char *));

	returnValue->multifieldValue = MBCreate(mb);
	MBDispose(mb);
}

/* Reads the optional headers flag the two multifield forms take */
static bool SqliteWMReadHeaderFlag(Environment *theEnv, UDFContext *context,
                                   const char *fn, bool *headers,
                                   UDFValue *returnValue)
{
	UDFValue theArg;

	if (!UDFHasNextArgument(context)) return true;

	UDFNextArgument(context, SYMBOL_BIT, &theArg);
	if (theArg.header->type != SYMBOL_TYPE
	    || (theArg.lexemeValue != TrueSymbol(theEnv)
	        && theArg.lexemeValue != FalseSymbol(theEnv)))
	{
		WriteString(theEnv, STDERR, fn);
		WriteString(theEnv, STDERR, ": the headers argument must be TRUE or FALSE\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return false;
	}

	*headers = (theArg.lexemeValue == TrueSymbol(theEnv));
	return true;
}

static void SqliteStmtToWMUDF(Environment *theEnv, UDFContext *context,
                              UDFValue *returnValue, const char *fn,
                              unsigned short kind)
{
	UDFValue theArg;
	sqlite3_stmt *stmt;
	SqliteInstanceNames names = { NULL, 0 };
	const char *construct;

	returnValue->lexemeValue = FalseSymbol(theEnv);

	UDFNextArgument(context, EXTERNAL_ADDRESS_BIT, &theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, fn);
		WriteString(theEnv, STDERR, ": first arg must be a statement pointer\n");
		return;
	}

	if (!(stmt = (sqlite3_stmt *) theArg.externalAddressValue->contents))
	{
		WriteString(theEnv, STDERR, fn);
		WriteString(theEnv, STDERR, ": statement pointer is NULL\n");
		return;
	}

	if (MULTIFIELD_TYPE == kind)
	{
		bool headers = false;

		if (!SqliteWMReadHeaderFlag(theEnv, context, fn, &headers, returnValue)) return;
		SqliteStmtToWorkingMemory(theEnv, fn, stmt, kind, NULL, NULL, headers, returnValue);
		return;
	}

	UDFNextArgument(context, LEXEME_BITS, &theArg);
	if (theArg.header->type != STRING_TYPE && theArg.header->type != SYMBOL_TYPE)
	{
		WriteString(theEnv, STDERR, fn);
		WriteString(theEnv, STDERR, ": second arg must be the name of the ");
		WriteString(theEnv, STDERR, SqliteWMNoun(kind));
		WriteString(theEnv, STDERR, "\n");
		return;
	}
	construct = theArg.lexemeValue->contents;

	if (INSTANCE_ADDRESS_TYPE == kind && UDFHasNextArgument(context))
	{
		UDFValue nameArg;

		UDFNextArgument(context, MULTIFIELD_BIT | LEXEME_BITS | INSTANCE_NAME_BIT, &nameArg);
		if (!SqliteWMNamesFromValue(theEnv, fn, &nameArg, &names, returnValue)) return;
	}

	SqliteStmtToWorkingMemory(theEnv, fn, stmt, kind, construct, &names, false, returnValue);
	SqliteFreeInstanceNames(theEnv, &names);
}

static void SqliteQueryToWMUDF(Environment *theEnv, UDFContext *context,
                               UDFValue *returnValue, const char *fn,
                               unsigned short kind)
{
	UDFValue theArg;
	sqlite3 *db;
	sqlite3_stmt *stmt = NULL;
	sqlite3_stmt *rest = NULL;
	const char *query;
	const char *tail = NULL;
	const char *given = NULL;
	char *inferred = NULL;
	SqliteInstanceNames names = { NULL, 0 };
	bool namesGiven = false;
	bool headers = false;
	int rc;

	returnValue->lexemeValue = FalseSymbol(theEnv);

	UDFNextArgument(context, EXTERNAL_ADDRESS_BIT, &theArg);
	if (theArg.header->type != EXTERNAL_ADDRESS_TYPE)
	{
		WriteString(theEnv, STDERR, fn);
		WriteString(theEnv, STDERR, ": first arg must be a database pointer\n");
		return;
	}

	if (!(db = (sqlite3 *) theArg.externalAddressValue->contents))
	{
		WriteString(theEnv, STDERR, fn);
		WriteString(theEnv, STDERR, ": database pointer is NULL\n");
		return;
	}

	UDFNextArgument(context, LEXEME_BITS, &theArg);
	if (theArg.header->type != STRING_TYPE)
	{
		WriteString(theEnv, STDERR, fn);
		WriteString(theEnv, STDERR, ": second arg must be a query string\n");
		return;
	}
	query = theArg.lexemeValue->contents;

	if (MULTIFIELD_TYPE == kind
	    && !SqliteWMReadHeaderFlag(theEnv, context, fn, &headers, returnValue))
	{
		return;
	}

	if (MULTIFIELD_TYPE != kind && UDFHasNextArgument(context))
	{
		UDFNextArgument(context,
		                (INSTANCE_ADDRESS_TYPE == kind)
		                  ? (MULTIFIELD_BIT | LEXEME_BITS | INSTANCE_NAME_BIT)
		                  : LEXEME_BITS,
		                &theArg);

		if (INSTANCE_ADDRESS_TYPE == kind && MULTIFIELD_TYPE == theArg.header->type)
		{
			if (!SqliteWMNamesFromValue(theEnv, fn, &theArg, &names, returnValue)) return;
			namesGiven = true;
		}
		else if (theArg.header->type != STRING_TYPE && theArg.header->type != SYMBOL_TYPE)
		{
			WriteString(theEnv, STDERR, fn);
			WriteString(theEnv, STDERR, ": third arg must be the name of the ");
			WriteString(theEnv, STDERR, SqliteWMNoun(kind));
			WriteString(theEnv, STDERR, "\n");
			return;
		}
		else { given = theArg.lexemeValue->contents; }
	}

	if (INSTANCE_ADDRESS_TYPE == kind && UDFHasNextArgument(context))
	{
		UDFValue nameArg;

		if (namesGiven)
		{
			WriteString(theEnv, STDERR, fn);
			WriteString(theEnv, STDERR, ": the instance names were given twice; the multifield third argument is already them\n");
			SqliteFreeInstanceNames(theEnv, &names);
			return;
		}

		UDFNextArgument(context, MULTIFIELD_BIT | LEXEME_BITS | INSTANCE_NAME_BIT, &nameArg);
		if (!SqliteWMNamesFromValue(theEnv, fn, &nameArg, &names, returnValue)) return;
	}

	rc = sqlite3_prepare_v2(db, query, -1, &stmt, &tail);
	if (SQLITE_OK != rc)
	{
		WriteString(theEnv, STDERR, fn);
		WriteString(theEnv, STDERR, ": prepare failed: ");
		WriteString(theEnv, STDERR, sqlite3_errmsg(db));
		WriteString(theEnv, STDERR, "\n");
		SqliteFreeInstanceNames(theEnv, &names);
		return;
	}
	if (NULL == stmt)
	{
		WriteString(theEnv, STDERR, fn);
		WriteString(theEnv, STDERR, ": the query holds no statement\n");
		SqliteFreeInstanceNames(theEnv, &names);
		return;
	}

	/* One statement at a time.  sqlite3_prepare_v2 compiles the first one and
	   hands back the rest; anything there but whitespace and comments is a
	   second statement the caller meant to run, and dropping it on the floor
	   would be worse than refusing. */
	if (NULL != tail && SQLITE_OK == sqlite3_prepare_v2(db, tail, -1, &rest, NULL) && NULL != rest)
	{
		sqlite3_finalize(rest);
		WriteString(theEnv, STDERR, fn);
		WriteString(theEnv, STDERR, ": the query holds more than one statement; run them one at a time\n");
		sqlite3_finalize(stmt);
		SqliteFreeInstanceNames(theEnv, &names);
		return;
	}

	if (MULTIFIELD_TYPE != kind && NULL == given)
	{
		if (NULL == (inferred = SqliteInferConstructName(theEnv, fn, stmt, kind)))
		{
			sqlite3_finalize(stmt);
			SqliteFreeInstanceNames(theEnv, &names);
			return;
		}
		given = inferred;
	}

	SqliteStmtToWorkingMemory(theEnv, fn, stmt, kind, given, &names, headers, returnValue);

	sqlite3_finalize(stmt);
	if (NULL != inferred) { genfree(theEnv, inferred, strlen(inferred) + 1); }
	SqliteFreeInstanceNames(theEnv, &names);
}

void SqliteStmtToFactsFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	SqliteStmtToWMUDF(theEnv, context, returnValue, "sqlite-stmt-to-facts", FACT_ADDRESS_TYPE);
}

void SqliteStmtToInstancesFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	SqliteStmtToWMUDF(theEnv, context, returnValue, "sqlite-stmt-to-instances", INSTANCE_ADDRESS_TYPE);
}

void SqliteStmtToMultifieldFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	SqliteStmtToWMUDF(theEnv, context, returnValue, "sqlite-stmt-to-multifield", MULTIFIELD_TYPE);
}

void SqliteQueryToFactsFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	SqliteQueryToWMUDF(theEnv, context, returnValue, "sqlite-query-to-facts", FACT_ADDRESS_TYPE);
}

void SqliteQueryToInstancesFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	SqliteQueryToWMUDF(theEnv, context, returnValue, "sqlite-query-to-instances", INSTANCE_ADDRESS_TYPE);
}

void SqliteQueryToMultifieldFunction(Environment *theEnv, UDFContext *context, UDFValue *returnValue)
{
	SqliteQueryToWMUDF(theEnv, context, returnValue, "sqlite-query-to-multifield", MULTIFIELD_TYPE);
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
	if (theArg.header->type == INTEGER_TYPE)
	{
		if (theArg.integerValue->contents < 0 || theArg.integerValue->contents > 11)
		{
			WriteString(theEnv, STDERR, "sqlite-limit: id must be between 0 and 11\n");
			returnValue->lexemeValue = FalseSymbol(theEnv);
			return;
		}
		id = theArg.integerValue->contents;
	}
	else if (theArg.header->type != SYMBOL_TYPE && theArg.header->type != STRING_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-limit: second arg must be an integer, a symbol, or a string\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
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
		WriteString(theEnv, STDERR, "sqlite-limit: unknown id ");
		WriteString(theEnv, STDERR, theArg.lexemeValue->contents);
		WriteString(theEnv, STDERR, "\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

	if (UDFHasNextArgument(context))
	{
		UDFNextArgument(context, INTEGER_BIT, &theArg);
		if (theArg.header->type != INTEGER_TYPE)
		{
			WriteString(theEnv, STDERR, "sqlite-limit: third arg must be an integer\n");
			returnValue->lexemeValue = FalseSymbol(theEnv);
			return;
		}
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
	if (theArg.header->type != INTEGER_TYPE)
	{
		WriteString(theEnv, STDERR, "sqlite-backup-step: second arg must be an integer\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

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
	int rc;

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
	rc = sqlite3_backup_finish((sqlite3_backup *)theArg.externalAddressValue->contents);

	/* sqlite3_backup_finish releases the backup object whatever it answers:
	   anything but SQLITE_OK is the error a step left behind, reported once
	   more on the way out.  So the handle is emptied either way, and the code
	   is described by name -- the object it belonged to is already gone. */
	theArg.externalAddressValue->contents = NULL;

	if (rc != SQLITE_OK)
	{
		WriteString(theEnv, STDERR, "sqlite-backup-finish: could not finish backup: ");
		WriteString(theEnv, STDERR, sqlite3_errstr(rc));
		WriteString(theEnv, STDERR, "\n");
		returnValue->lexemeValue = FalseSymbol(theEnv);
		return;
	}

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
	AddUDF(env,"sqlite-stmt-to-facts","bm",2,2,";e;sy",SqliteStmtToFactsFunction,"SqliteStmtToFactsFunction",NULL);
	AddUDF(env,"sqlite-stmt-to-instances","bm",2,3,";e;sy;mnsy",SqliteStmtToInstancesFunction,"SqliteStmtToInstancesFunction",NULL);
	AddUDF(env,"sqlite-stmt-to-multifield","bm",1,2,";e;b",SqliteStmtToMultifieldFunction,"SqliteStmtToMultifieldFunction",NULL);
	AddUDF(env,"sqlite-query-to-facts","bm",2,3,";e;s;sy",SqliteQueryToFactsFunction,"SqliteQueryToFactsFunction",NULL);
	AddUDF(env,"sqlite-query-to-instances","bm",2,4,";e;s;mnsy;mnsy",SqliteQueryToInstancesFunction,"SqliteQueryToInstancesFunction",NULL);
	AddUDF(env,"sqlite-query-to-multifield","bm",2,3,";e;s;b",SqliteQueryToMultifieldFunction,"SqliteQueryToMultifieldFunction",NULL);
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
