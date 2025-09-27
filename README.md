<img width="860" height="800" alt="CLIPSQLite" src="https://github.com/user-attachments/assets/2371fd64-ee9d-4128-b806-c9177bc093aa" />

# CLIPSQLite

A SQLite library for CLIPS

## Installation

First, you will need `sqlite3.h` to be available in your system.
If you're on Ubuntu-based systems, for example:

```
sudo apt install libsqlite3-dev
```

To compile and run CLIPSQLite locally (without installing globally):

```
make
./vendor/clips/clips
```

You could install this globally on your system, too:

```
make
sudo make install
CLIPSQLite
```

You can find examples of usage in the `program.bat` file:

```
./vendor/clips/clips -f2 program.bat
```

## API

### `(sqlite-libversion)` -> `SYMBOL`

Returns the version of SQLite compiled into CLIPSQLite.

#### Example

```clips
(println "The SQLite version in use: " (sqlite-libversion))
```

### `(sqlite-libversion-number)` -> `INTEGER`

Returns an integer equal to `SQLITE_VERSION_NUMBER`.

#### Example

```clips
(println "The SQLite version integer: " (sqlite-libversion-number))
```

### `(sqlite-sourceid)` -> `SYMBOL`

Returns a pointer to a string constant whose value
is the same as the `SQLITE_SOURCE_ID` C preprocessor macro.

#### Example

```clips
(println "The SQLite aggregate: " (sqlite-sourceid))
```

### `(sqlite-threadsafe)` -> `BOOLEAN`

Returns whether or not SQLite was compiled with Mutexes or not.
**NOTE**: This does not say whether CLIPS is threadsafe or not;
CLIPS is not threadsafe.

#### Example

```clips
(println "Is the compiled SQLite threadsafe?: " (sqlite-threadsafe))
```

### `(sqlite-memory-used)` -> `INTEGER`

Returns the amount of memory currently used by SQLite in bytes.

#### Example

```clips
(println "The current amount of memory used: " (sqlite-memory-used))
```

### `(sqlite-memory-highwater [<SET>])` -> `INTEGER`

Returns the highest amount of memory used by SQLite in bytes.
If `<SET>` is `TRUE`, sets the memory highwater to the current
amount of bytes used by SQLite and returns the previous highest amount
before the set.

#### Arguments

- `<SET>` - A `BOOLEAN` value that, if included, sets the highwater number
  to the current amount of memory in use.

#### Example

```clips
(println "The highest amount of memory used so far by SQLite: " (sqlite-memory-highwater))
```

### `(sqlite-compileoption-get <OPTION-INTEGER>)` -> `SYMBOL`

Returns a `SYMBOL` that is the name of the compile option
whose constant represents the passed `<OPTION-INTEGER>`.

#### Arguments

- `<OPTION-INTEGER>` - An `INTEGER` for the name of the constant
  that should be returned.

#### Example

```clips
(println "Compile option 1: " (sqlite-compileoption-get 1))
```

### `(sqlite-compileoption-used <OPTION-LEXEME>)` -> `BOOLEAN`

Returns either `TRUE` or `FALSE` as to whether a given compile option
was set during compilation.

#### Arguments

- `<OPTION-LEXEME>` - A `SYMBOL` that represents the compile option constant
  that you want to determine whether or not it was included during compilation.

#### Example

```clips
(println "Was SQLite compiled with DEFAULT_RECURSIVE_TRIGGERS?: " (sqlite-compileoption-used DEFAULT_RECURSIVE_TRIGGERS))
```

### `(sqlite-open <LEXEME> [<FLAGS>] [<VFS>])` -> `INTEGER`

Opens a connection to either an in-memory or file-based database.

#### Arguments

- `<LEXEME>`: Either a `SYMBOL` or `STRING` that is a file path or `:memory:`
- `<FLAGS>`: A `SYMBOL` or `MULTIFIELD` of `SYMBOL`s of flags to open the database as.
  Available flags:
    - `SQLITE_OPEN_READONLY`
    - `SQLITE_OPEN_READWRITE`
    - `SQLITE_OPEN_CREATE`
    - `SQLITE_OPEN_URI`
    - `SQLITE_OPEN_MEMORY`
    - `SQLITE_OPEN_NOMUTEX`
    - `SQLITE_OPEN_FULLMUTEX`
    - `SQLITE_OPEN_SHAREDCACHE`
    - `SQLITE_OPEN_PRIVATECACHE`
    - `SQLITE_OPEN_EXRESCODE`
    - `SQLITE_OPEN_NOFOLLOW`

#### Returns

- A pointer to the opened database
- `FALSE` upon failure

#### Example

```clips
(defglobal ?*filedb* = (sqlite-open "./foo.db"))
(defglobal ?*in-memorydb* = (sqlite-open :memory:))
(defglobal ?*db-readonly* = (sqlite-open ./foo-readonly.db SQLITE_OPEN_READONLY))
(defglobal ?*db-readonly2* = (sqlite-open ./foo-readonly2.db (create$ SQLITE_OPEN_READONLY SQLITE_OPEN_NOFOLLOW)))
```

### `(sqlite-close <db-pointer>)`

Closes a connection to an opened database connection

#### Arguments

- `<db-pointer>`: Pointer to an opened database connection

#### Returns

- `TRUE` on successful close
- `FALSE` on failure

#### Example

```clips
(defglobal ?*filedb* = (sqlite-open "./foo.db"))
(println "Successfully closed ?*filedb* ?: " (sqlite-close ?*filedb*))
```

### `(sqlite-changes <DB-POINTER>)` -> `INTEGER` or `BOOLEAN`

Returns the number of changes that occurred in the database
due to the last run query.

#### Arguments

- `<DB-POINTER>` - A pointer to an opened connection.

#### Example

```clips
(defglobal ?*stmt* = (sqlite-prepare ?*db* "INSERT INTO foos (name) VALUES ('bar', 'baz')))
(sqlite-step ?*stmt*)
(println "Inserted " (sqlite-changes ?*db*) " records.") ; Inserted 2 records.
```

### `(sqlite-total-changes <DB-POINTER>)` -> `INTEGER` or `BOOLEAN`

Returns the total changes made so far on the database connection.

#### Arguments

- `<DB-POINTER>` - A pointer to an opened connection.

#### Returns

- `<INTEGER>` - The number of changes
- `<BOOLEAN>` - `FALSE` when something goes wrong

#### Example

```clips
(defglobal ?*stmt* = (sqlite-prepare ?*db* "INSERT INTO foos (name) VALUES ('bar', 'baz')))
(sqlite-step ?*stmt*)
(sqlite-finalize ?*stmt*)
(defglobal ?*stmt* = (sqlite-prepare ?*db* "INSERT INTO foos (name) VALUES ('zub', 'zab')))
(println "Inserted " (sqlite-total-changes ?*db*) " records total.") ; Inserted 4 records total.
```

### `(sqlite-last-insert-rowid <DB-POINTER>)` -> `INTEGER` or `BOOLEAN`

Returns the rowid of the last inserted record.
The rowid is always available as an undeclared column
named ROWID, OID, or _ROWID_
as long as those names are not also used by explicitly declared columns.
If the table has a column of type INTEGER PRIMARY KEY
then that column is another alias for the rowid.

#### Arguments

- `<DB-POINTER>` - A pointer to an opened connection.

#### Returns

- `<INTEGER>` - THe last inserted rowid
- `<BOOLEAN>` - `FALSE` if something goes wrong

#### Example

```clips
(defglobal ?*stmt* = (sqlite-prepare ?*db* "INSERT INTO foos (name) VALUES ('bar', 'baz')))
(sqlite-step ?*stmt*)
(println "Last inserted id: " (sqlite-last-insert-rowid ?*db*)) ; Last inserted id: 2
```

### `(sqlite-db-name <DB-POINTER> <INDEX>)` -> `STRING` or `BOOLEAN`

The name of a database at a given index on an open connection.

#### Arguments

- `<DB-POINTER>` - A pointer to an opened connection.
- `<INDEX>` - An `<INTEGER>` indicating the index of the database who's name to return

#### Returns

- `<STRING>` - The name of database on the open db-pointer connection at index.
- `<BOOLEAN>` - `FALSE` if index is out of bounds.

#### Examples

```clips
(sqlite-db-name ?*db-in-memory* 0) ; main
(sqlite-db-name ?*db-in-memory* 1) ; temp
(sqlite-db-name ?*db-in-memory* 2) ; FALSE
```

### `(sqlite-db-filename <DB-POINTER> <DB-NAME>)` -> `STRING` or `BOOLEAN`

Returns the name of a filename for the opened `<DB-POINTER>`.

#### Arguments

- `<DB-POINTER>` - A pointer to an opened connection.
- `<DB-NAME>` - A `<LEXEME>` that is the name of a database in the opened connection.

#### Returns

- `<STRING>` - The full path to the file for the opened database connection
- `<BOOLEAN>` - `FALSE` if is temporary or in-memory database.

#### Example

```clips
(defglobal ?*db-file* = (sqlite-open ./foo2.db))
(defglobal ?*filename* = (sqlite-db-filename ?*db-file* "main"))
(sub-string (- (str-length ?*filename*) 7) (str-length ?*filename*) ?*filename*) ; "/foo2.db"
```

### `(sqlite-db-readonly <DB-POINTER> <DB-NAME>)` -> `BOOLEAN`

Returns whether or not a database is readonly.

#### Arguments

- `<DB-POINTER>` - A pointer to an opened connection.
- `<DB-NAME>` - A `<LEXEME>` that is the name of a database in the opened connection.

#### Returns

- `<BOOLEAN>` - `TRUE` if database is readonly on the connection, `FALSE` if it is not readonly.

```clips
(defglobal ?*db* = (sqlite-open ./foo-readonly.db))
(sqlite-db-readonly ?*db* "main") ; FALSE
(sqlite-close ?*db*)
(defglobal ?*db* = (sqlite-open ./foo-readonly.db SQLITE_OPEN_READONLY))
(sqlite-db-readonly ?*db* "main") ; TRUE
```

### `(sqlite-db-exists <DB-POINTER> <DB-NAME>)` -> `INTEGER` or `BOOLEAN`

Returns whether or not a database exists on the connection.

#### Arguments

- `<DB-POINTER>` - A pointer to an opened connection.
- `<DB-NAME>` - A `<LEXEME>` that is the name of a database in the opened connection.

#### Returns

- `<BOOLEAN>` - `TRUE` if database exists on the connection, `FALSE` if it does not exist.

#### Example

```clips
(defglobal ?*db* = (sqlite-open :memory:))
(sqlite-db-exists ?*db* main) ; TRUE
(sqlite-db-exists ?*db* "temp") ; TRUE
(sqlite-db-exists ?*db* "asdf") ; FALSE
```

### `(sqlite-prepare <DB-POINTER> <SQL-QUERY>)` -> `STATEMENT-POINTER` or `BOOLEAN`

Prepares a SQL statement to be executed in database

#### Arguments

- `<DB-POINTER>`: Pointer to an opened database connection
- `<SQL-QUERY>`: A SQL statement `STRING`

#### Returns

- `<statement-pointer>`: A pointer to the prepared statement
- `FALSE` on failure

#### Example

```clips
(sqlite-prepare ?*db* "SELECT * FROM foos WHERE id=?")
```

### `(sqlite-stmt-explain <STATEMENT-POINTER> <INTEGER>)` -> `BOOLEAN`

Set the explain mode. This will cause the query to include an `EXPLAIN`
which provides information about the query in the results instead of the results.

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.
- `<INTEGER>` - Mode to set for explain level. Possible modes:
    - `0` - Original prepared statement
    - `1` - Behaves as if its SQL text began with "EXPLAIN"
    - `2` - Behaves as if its SQL text began with "EXPLAIN QUERY PLAN"

#### Returns

- `<BOOLEAN>` - `TRUE` if explain set successfully, `FALSE` if unsuccessful

#### Example

```clips
(defglobal ?*stmt-m2* = (sqlite-prepare ?*db* "INSERT INTO foos (name) VALUES ('Foo baz'), ('Baz bat'), ('co cuz')"))
(sqlite-stmt-explain ?*stmt-m2* 2) ; TRUE
(sqlite-column ?*stmt-m2* 3) ; "SCAN 3-ROW VALUES CLAUSE"
```

### `(sqlite-stmt-isexplain <STATEMENT-POINTER>)` -> `STRING` or `BOOLEAN`

Returns the mode of explain for the prepared statement.

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

#### Returns

- `<STRING>` - `"EXPLAIN"` if `1` or `"EXPLAIN QUERY PLAN"` if `2`
- `<BOOLEAN>` - `FALSE` if not yet set on prepared statement

#### Example

```clips
(sqlite-stmt-isexplain ?*stmt*)
```

### `(sqlite-bind <STATEMENT-POINTER> <POSITION-NAME-OR-VALUE> [<VALUE>])` -> `BOOLEAN`

Binds values in place of variables in a prepared statement.

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.
- `<POSITION-NAME-OR-VALUE>` - If inserting positional values, this could be the first value. In this case, do not include `<VALUE>`.
  This can also be a multifield of positional values. This can also be an `<INTEGER>` representing the positional parameter
  to replace. This can also be the named parameter in the prepared statement to replace.
- `[<VALUE>]` - If argument 2 is the name of the parameter to replace in the prepared statement, this is the value for that parameter.

#### Example

```clips
(defglobal ?*stmt-o* = (sqlite-prepare ?*db* "SELECT ?1, ?2, ?3"))
(sqlite-bind ?*stmt-o* (create$ "alpha" 42 3.14))
(defglobal ?*stmt-n* = (sqlite-prepare ?*db* "SELECT :x AS xx, :y AS yy"))
(sqlite-bind ?*stmt-n* :y 123)
(sqlite-bind ?*stmt-n* :x "hello")
(defglobal ?*stmt-m4* = (sqlite-prepare ?*db* "SELECT * FROM foos WHERE id=? AND name LIKE ?"))
(sqlite-bind ?*stmt-m4* 1 1)
(sqlite-bind ?*stmt-m4* 2 "%oo b%")
```

### `(sqlite-finalize <STATEMENT-POINTER>)` -> `BOOLEAN`

Dispose of the prepared statement when done with it.

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

#### Returns

- `<BOOLEAN>` - `TRUE` if successfully finalized.

#### Example

```clips
(defglobal ?*stmt-o* = (sqlite-prepare ?*db* "SELECT ?1, ?2, ?3"))
(sqlite-finalize ?*stmt-o*) ; TRUE
```

### `(sqlite-bind-parameter-count <STATEMENT-POINTER>)` -> `INTEGER` or `BOOLEAN`

Return the number of parameters that can be bound to a prepared statement.

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

#### Returns

- `<INTEGER>` - Number of parameters
- `<BOOLEAN>` - `FALSE` if something went wrong

#### Example

```clips
(defglobal ?*stmt-m4* = (sqlite-prepare ?*db* "SELECT * FROM foos WHERE id=? AND name LIKE ?"))
(sqlite-bind-parameter-count ?*stmt-m4*) ; 2
```

### `(sqlite-bind-parameter-index <STATEMENT-POINTER> <PARAMETER-NAME>)` -> `INTEGER` or `BOOLEAN`

Returns the index of a named parameter in a prepared statement.

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.
- `<PARAMETER-NAME>` - The name of the parameter who's index to find.

#### Returns

- `<INTEGER>` - the index of the named parameter
- `<BOOLEAN>` - `FALSE` if parameter with this name is not present in prepared statement

#### Example

```clips
(defglobal ?*stmt-n* = (sqlite-prepare ?*db* "SELECT :x AS xx, :y AS yy"))
(sqlite-bind-parameter-index ?*stmt-n* :x) ; 1
(sqlite-bind-parameter-index ?*stmt-n* :y) ; 2
```

### `(sqlite-bind-parameter-name <STATEMENT-POINTER> <PARAMETER-INDEX>)` -> `SYMBOL` or `BOOLEAN`

Get the name of a parameter in a prepared statement at the specified index.

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.
- `<PARAMETER-INDEX>` - An `INTEGER` specifying the index of the parameter who's name to get

#### Returns

- `<SYMBOL>` - The name of the named parameter at the specified `<PARAMETER-INDEX>` in the prepared statement
- `<BOOLEAN>` - `FALSE` if something went wrong

#### Example

```clips
(defglobal ?*stmt-n* = (sqlite-prepare ?*db* "SELECT :x AS xx, :y AS yy"))
(sqlite-bind-parameter-name ?*stmt-n* 1) ; :x
(sqlite-bind-parameter-name ?*stmt-n* 2) ; :y
```

### `(sqlite-sql <STATEMENT-POINTER>)` -> `STRING` or `BOOLEAN`

Gets the query for the prepared statement before parameter replacement takes place.

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

#### Returns

- `<STRING>` - The SQL query before replacing any variables
- `<BOOLEAN>` - `FALSE` if something went wrong

#### Example

```clips
(defglobal ?*stmt-n* = (sqlite-prepare ?*db* "SELECT :x AS xx, :y AS yy"))
(sqlite-sql ?*stmt-n*) ; "SELECT :x AS xx, :y AS yy"
```

### `(sqlite-expanded-sql <STATEMENT-POINTER>)` -> `STRING` or `BOOLEAN`

Returns the query of a prepared statement after the bound parameters have been replaced

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

#### Returns

- `<STRING>` - The SQL query after replacing any variables
- `<BOOLEAN>` - `FALSE` if something went wrong

#### Example

```clips
(defglobal ?*stmt-n* = (sqlite-prepare ?*db* "SELECT :x AS xx, :y AS yy"))
(sqlite-expanded-sql ?*stmt-n*) ; "SELECT NULL AS xx, NULL AS yy"
(sqlite-bind ?*stmt-n* :x "hello")
(sqlite-expanded-sql ?*stmt-n*) ; "SELECT 'hello' AS xx, NULL AS yy"
(sqlite-bind ?*stmt-n* :y 123)
(sqlite-expanded-sql ?*stmt-n*) ; "SELECT 'hello' AS xx, 123 AS yy"
```

### `(sqlite-normalized-sql <STATEMENT-POINTER>)` -> `STRING` or `BOOLEAN`

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

### `(sqlite-reset <STATEMENT-POINTER>)` -> `BOOLEAN`

Returns the prepared statement to the state it was in
before any `sqlite-step` functions were called on it.

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

#### Returns

- `<BOOLEAN>` - `TRUE` if successfully reset, `FALSE` if something went wrong

#### Example

```clips
(sqlite-reset ?*stmt-n*) ; TRUE
(sqlite-step ?*stmt-n*) ; SQLITE_ROW
(sqlite-step ?*stmt-n*) ; SQLITE_DONE
(sqlite-reset ?*stmt-n*) ; TRUE
(sqlite-step ?*stmt-n*) ; SQLITE_ROW
```

### `(sqlite-clear-bindings <STATEMENT-POINTER>)` -> `BOOLEAN`

Clear bound variables from a prepared statement.

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

#### Returns

- `<BOOLEAN>` - `TRUE` if successfully cleared bound variables, `FALSE` if not

#### Example

```clips
(sqlite-expanded-sql ?*stmt-o*) ; "SELECT 'alpha', 42, 3.14"
(sqlite-clear-bindings ?*stmt-o*)
(sqlite-expanded-sql ?*stmt-o*) ; "SELECT NULL, NULL, NULL"
```

### `(sqlite-step <STATEMENT-POINTER>)` -> `SYMBOL` or `BOOLEAN`

"Executes" the SQL query, moving to the next row of results.
Call this multiple times to iterate through results of a `SELECT`.

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

#### Returns

- `SQLITE_ROW` - The statement is now pointed at a result row
- `SQLITE_DONE` - There are no more results to iterate

```clips
(defglobal ?*stmt-o* = (sqlite-prepare ?*db* "SELECT ?1, ?2, ?3"))
(sqlite-bind ?*stmt-o* (create$ "alpha" 42 3.14))
(sqlite-step ?*stmt-o*) ; SQLITE_ROW
(sqlite-step ?*stmt-o*) ; SQLITE_DONE
```

### `(sqlite-row-to-multifield <STATEMENT-POINTER>)` -> `MULTIFIELD` or `BOOLEAN`

Returns a multifield with values from the current row of a prepared statement
after a `sqlite-step`.

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

#### Returns

- `<MULTIFIELD>` - A multifield with values from the current row of a prepared statemnt.
- `<BOOLEAN>` - `FALSE` if something went wrong

#### Example

```clips
(defglobal ?*stmt-m4* = (sqlite-prepare ?*db* "SELECT * FROM foos WHERE id=? AND name LIKE ?"))
(sqlite-bind ?*stmt-m4* 1 1)
(sqlite-bind ?*stmt-m4* 2 "%oo b%")
(sqlite-step ?*stmt-m4*)
(sqlite-row-to-multifield ?*stmt-m4*) ; (1 "Foo baz")
```

### `(sqlite-row-to-fact <STATEMENT-POINTER> <DEFTEMPLATE-NAME>)` -> `FACT` or `BOOLEAN`

Returns an asserted Fact with the slot values from the current row of a prepared statement.

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.
- `<DEFTEMPLATE-NAME>` - A symbol of a deftemplate of the fact that should be asserted from the current row of the prepared statement

#### Returns

- `<FACT>` - The asserted fact with values from the prepared statement row
- `<BOOLEAN>` - `FALSE` if something went wrong

#### Example

```clips
(defglobal ?*stmt-m4* = (sqlite-prepare ?*db* "SELECT * FROM foos WHERE id=? AND name LIKE ?"))
(sqlite-bind ?*stmt-m4* 1 1)
(sqlite-bind ?*stmt-m4* 2 "%oo b%")
(sqlite-step ?*stmt-m4*)
(deftemplate row
	(slot id)
	(slot name))
(sqlite-row-to-fact ?*stmt-m4* row) ; <Fact-1>
(ppfact 1) ; (row 
           ;    (id 1) 
           ;    (name "Foo baz"))
```

### `(sqlite-row-to-instance <STATEMENT-POINTER> <DEFCLASS-NAME> [<INSTANCE-NAME>] [<NAME-COLUMN-SLOT>])` -> `INSTANCE` or `BOOLEAN`

Returns the current row of the prepared statement as a COOL instance.

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.
- `<DEFCLASS-NAME>` - The name of the defclass for which the instance should be made from
- `[<INSTANCE-NAME>] - The name of the instance to make. Optional or `nil` to leave default
- `[<NAME-COLUMN-SLOT>]` - Since defclasses can't have a slot named `name`, this allows specifying the name of the slot which will be set with the value from the query result's `name` column. Leave empty to use the default `_name`

#### Returns

- `<INSTANCE>` - An instance for a given defclass with slots set to values from the columns of a result of the prepared statement
- `<BOOLEAN>` - `FALSE` if something went wrong

```clips
(defglobal ?*stmt-m4* = (sqlite-prepare ?*db* "SELECT * FROM foos WHERE id=? AND name LIKE ?"))
(sqlite-bind ?*stmt-m4* 1 1)
(sqlite-bind ?*stmt-m4* 2 "%oo b%")
(sqlite-step ?*stmt-m4*)
(defclass ROW
	(is-a USER)
	(slot id)
	(slot _name))
(defglobal ?*instance* = (sqlite-row-to-instance ?*stmt-m4* ROW))
(instance-name ?*instance*) ; [gen-1]
(send ?*instance* get-id) ; 1
(send ?*instance* get-_name) ; "Foo baz"
```

### `(sqlite-column-count <STATEMENT-POINTER>)` -> `INTEGER` or `BOOLEAN`

Returns the number of columns for the records of the prepared statement.

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

#### Returns

- `<INTEGER>` - The number of columns
- `<BOOLEAN>` - `FALSE` if something went wrong

#### Example

```clips
(defglobal ?*stmt-o* = (sqlite-prepare ?*db* "SELECT ?1, ?2, ?3"))
(sqlite-column-count ?*stmt-o*) ; 3
```

### `(sqlite-column-database-name <STATEMENT-POINTER> <COLUMN-INDEX>)` -> `STRING` or `BOOLEAN`

Returns the name of the database the column in the results is from

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.
- `<COLUMN-INDEX>` - The index of the column to return the name of the database from

#### Returns

- `<STRING>` - The name of the database the column is from
- `<BOOLEAN>` - `FALSE` if something goes wrong

#### Example

```clips
(defglobal ?*stmt-o* = (sqlite-prepare ?*db* "SELECT ?1, ?2, ?3"))
(sqlite-step ?*stmt-o*)
(sqlite-column-database-name ?*stmt-o* 1) ; FALSE
(defglobal ?*stmt-m4* = (sqlite-prepare ?*db* "SELECT * FROM foos WHERE id=? AND name LIKE ?"))
(sqlite-step ?*stmt-m4*)
(sqlite-column-database-name ?*stmt-m4* 1)
```

### `(sqlite-column-origin-name <STATEMENT-POINTER> <COLUMN-INDEX>)` -> `STRING` or `BOOLEAN`

Return the original name of the column that provides the values
for the given column index.

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.
- `<COLUMN-INDEX>` - The index of the column to return the column name from

#### Returns

- `<STRING>` - The name of the origin column
- `<BOOLEAN>` - `FALSE` if something goes wrong or if there is no origin column

#### Example

```clips
(defglobal ?*stmt-o* = (sqlite-prepare ?*db* "SELECT ?1, ?2, ?3"))
(sqlite-step ?*stmt-o*)
(sqlite-column-origin-name ?*stmt-o* 1) ; FALSE
(defglobal ?*stmt-m4* = (sqlite-prepare ?*db* "SELECT * FROM foos WHERE id=? AND name LIKE ?"))
(sqlite-step ?*stmt-m4*)
(sqlite-column-origin-name ?*stmt-m4* 1) ; "name"
```

### `(sqlite-column-table-name <STATEMENT-POINTER> <COLUMN-INDEX>)` -> `STRING` or `BOOLEAN`

Return the name of the table the column comes from in a prepared statement

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.
- `<COLUMN-INDEX>` - The index of the column to return the column name from

#### Returns

- `<STRING>` - The name of the table
- `<BOOLEAN>` - `FALSE` if something goes wrong or the column does not come from a table

#### Example

```clips
(defglobal ?*stmt-o* = (sqlite-prepare ?*db* "SELECT ?1, ?2, ?3"))
(sqlite-step ?*stmt-o*)
(sqlite-column-table-name ?*stmt-o* 1) ; FALSE
(defglobal ?*stmt-m4* = (sqlite-prepare ?*db* "SELECT * FROM foos WHERE id=? AND name LIKE ?"))
(sqlite-step ?*stmt-m4*)
(sqlite-column-table-name ?*stmt-m4* 1) ; "foos"
```

### `(sqlite-column-name <STATEMENT-POINTER> <COLUMN-INDEX>)` -> `STRING` or `BOOLEAN`

Returns the name of the column at column index in a statement

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.
- `<COLUMN-INDEX>` - The index of the column to return the column name from

#### Returns

- `<STRING>` - The name of the column
- `<BOOLEAN>` - `FALSE` if something goes wrong or the column does not have a name

#### Example

```clips
(defglobal ?*stmt-o* = (sqlite-prepare ?*db* "SELECT ?1, ?2, ?3"))
(sqlite-step ?*stmt-o*)
(sqlite-column-name ?*stmt-o* 0) ; ?1
(defglobal ?*stmt-n* = (sqlite-prepare ?*db* "SELECT :x AS xx, :y AS yy"))
(sqlite-step ?*stmt-n*)
(sqlite-column-name ?*stmt-n* 1) ; yy
```

### `(sqlite-column-type <STATEMENT-POINTER> <COLUMN-INDEX>)` -> `SYMBOL` or `BOOLEAN`

Returns the type of column at index

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.
- `<COLUMN-INDEX>` - The index of the column to return the column name from

#### Returns

- `<SYMBOL>` - The type of the column. Possible values:
  - `SQLITE_INTEGER`
  - `SQLITE_FLOAT`
  - `SQLITE_TEXT`
  - `SQLITE_BLOB`
  - `SQLITE_NULL`
- `<BOOLEAN>` - `FALSE` if something goes wrong or the column does not have a type

#### Example

```clips
(defglobal ?*stmt-o* = (sqlite-prepare ?*db* "SELECT ?1, ?2, ?3"))
(sqlite-step ?*stmt-o*)
(sqlite-column-type ?*stmt-o* 0) ; SQLITE_TEXT
(sqlite-column-type ?*stmt-o* 1) ; SQLITE_INTEGER
(sqlite-column-type ?*stmt-o* 2) ; SQLITE_FLOAT
```

### `(sqlite-column <STATEMENT-POINTER> <COLUMN-INDEX>)` -> `STRING`, `INTEGER`, `DOUBLE`, `nil`, or `BOOLEAN`

Returns the value of column at column index

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.
- `<COLUMN-INDEX>` - The index of the column to return the column name from

#### Returns

- `<STRING>` - `SQLITE_TEXT` or `SQLITE_BLOB`
- `<INTEGER>` - `SQLITE_INTEGER`
- `<DOUBLE>` - `SQLITE_FLOAT`
- `nil` - `SQLITE_NULL`
- `<BOOLEAN>` - `FALSE` if type is not recognized

#### Example

```clips
(defglobal ?*stmt-m4* = (sqlite-prepare ?*db* "SELECT * FROM foos WHERE id=? AND name LIKE ?"))
(sqlite-step ?*stmt-m4*)
(sqlite-column ?*stmt-m4* 1) ; "Foo baz"
```

### `(sqlite-errmsg <DB-POINTER>)` -> `STRING` or `BOOLEAN`

Returns the latest error that occurred in the database.

#### Arguments

- `<DB-POINTER>`: Pointer to an opened database connection

#### Returns

- `<STRING>` - A message describing the last error that occurred
- `<BOOLEAN>` - `FALSE` if something went wrong

#### Example

```clips
(defglobal ?*stmt-o* = (sqlite-prepare ?*db* "SELECT ?1, ?2, ?3"))
(sqlite-close ?*db*)
(sqlite-errmsg ?*db*) ; "unable to close due to unfinalized statements or unfinished backups"
```

### `(sqlite-busy-timeout <STATEMENT-POINTER> <MILLISECONDS>)` -> `BOOLEAN`

Sets the amount of time to wait for a busy query

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.
- `<MILLISECONDS>` - An `<INTEGER>` to set the number of milliseconds to wait

#### Returns

- `<BOOLEAN>` - `TRUE` on success or `FALSE` on failure

#### Example

```clips
(sqlite-busy-timeout ?*db* 0)
```

### `(sqlite-limit <STATEMENT-POINTER> <LIMIT> [<AMOUNT>])` -> `INTEGER` or `BOOLEAN`

Get or Set a SQLite limit.

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.
- `<LIMIT>` - An `<INTEGER>` or `<SYMBOL>` of a limit that may be set.
  You may set `<INTEGER>` value 0 through 11.
  Possible `<SYMBOL>` values:
  - `SQLITE_LIMIT_LENGTH`
  - `SQLITE_LIMIT_SQL_LENGTH`
  - `SQLITE_LIMIT_COLUMN`
  - `SQLITE_LIMIT_EXPR_DEPTH`
  - `SQLITE_LIMIT_COMPOUND_SELECT`
  - `SQLITE_LIMIT_VDBE_OP`
  - `SQLITE_LIMIT_FUNCTION_ARG`
  - `SQLITE_LIMIT_ATTACHED`
  - `SQLITE_LIMIT_LIKE_PATTERN_LENGTH`
  - `SQLITE_LIMIT_VARIABLE_NUMBER`
  - `SQLITE_LIMIT_TRIGGER_DEPTH`
  - `SQLITE_LIMIT_WORKER_THREADS`
- `<AMOUNT>` - An `<INTEGER>` to set to the limit

#### Returns

- `<INTEGER>` - The previous limit before running this command
- `<BOOLEAN>` - `FALSE` if something went wrong

#### Example

```clips
(sqlite-limit ?*db* 0) ; 1000000000
(sqlite-limit ?*db* SQLITE_LIMIT_LENGTH) ; 1000000000
(sqlite-limit ?*db* 0 999999999) ; 1000000000
(sqlite-limit ?*db* 0) ; 999999999
```

### `(sqlite-sleep <MILLISECONDS>)` -> `INTEGER` or `BOOLEAN`

Pause execution of the thread for a number of milliseconds.

#### Arguments

- `<MILLISECONDS>` - An `INTEGER` that is the number of milliseconds
  to sleep the current thread.

#### Returns

- `INTEGER` - The number of milliseconds of sleep actually requested from the operating system.
- `BOOLEAN` - `FALSE` if anything goes wrong.

### `(sqlite-backup-init <DESTINATION-DATABASE-POINTER> <DESTINATION-DATABASE-NAME> <SOURCE-DATABASE-POINTER> <SOURCE-DATABASE-NAME>)` -> `POINTER` or `BOOLEAN`

Initializes database backup from a source to destination database.

#### Arguments

- `<DESTINATION-DATABASE-POINTER>` - A pointer to a database connection which will receive the backup data.
- `<DESTINATION-DATABASE-NAME>` - The database into which the data will be added.
- `<SOURCE-DATABASE-POINTER>` - A pointer to a database connection who's data will be backed up.
- `<SOURCE-DATABASE-NAME>` - The database from which the data will be backed up.

#### Returns

- `<POINTER>` - A pointer to an initaizlied backup.
- `<BOOLEAN>` - `FALSE` if initialization failed.

### `(sqlite-backup-step <BACKUP-POINTER> <PAGES>)` -> `SYMBOL`, `INTEGER`, or `BOOLEAN`

Executes a "page" of backup

#### Arguments

- `<BACKUP-POINTER>` - A pointer to an initialized backup.
- `<PAGES>` - A number of pages to backup. A negative number means all remaining pages

#### Returns

- `<SYMBOL>` - The status after running a step of the backup
- `<INTEGER>` - Some other return code
- `<BOOLEAN>` - `FALSE` if something went wrong

#### Example

```clips
(sqlite-backup-step ?*backup* -1) ; SQLITE_DONE
```

### `(sqlite-backup-pagecount <BACKUP-POINTER>)` -> `INTEGER` or `BOOLEAN`

Returns how many pages total are in the backup

#### Arguments

- `<BACKUP-POINTER>` - A pointer to an initialized backup.

#### Returns

- `<INTEGER>` - The number of pages total in the backup
- `<BOOLEAN>` - `FALSE` if something went wrong

#### Example

```clips
(sqlite-backup-pagecount ?*backup*) ; 1
```

### `(sqlite-backup-remaining <BACKUP-POINTER>)` -> `INTEGER` or `BOOLEAN`

Returns how many pages of backing up are left before the backup is complete

#### Arguments

- `<BACKUP-POINTER>` - A pointer to an initialized backup.

#### Returns

- `<INTEGER>` - The number of pages remaining in the backup
- `<BOOLEAN>` - `FALSE` if something went wrong

#### Example

```clips
(sqlite-backup-remaining ?*backup*) ; 1
```

### `(sqlite-backup-finish <BACKUP-POINTER>)` -> `BOOLEAN`

Cleans up the backup once finished.

#### Arguments

- `<BACKUP-POINTER>` - A pointer to an initialized backup.

#### Returns

- `<BOOLEAN>` - `TRUE` on success, `FALSE` on failure

#### Example

```clips
(sqlite-backup-finish ?*backup*) ; TRUE
```

## Development

```
make clean
```
