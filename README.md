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

#### Arguments

- `<DB-POINTER>` - A pointer to an opened connection.

#### Example

```clips
(defglobal ?*stmt* = (sqlite-prepare ?*db* "INSERT INTO foos (name) VALUES ('bar', 'baz')))
(sqlite-step ?*stmt*)
(sqlite-finalize ?*stmt*)
(defglobal ?*stmt* = (sqlite-prepare ?*db* "INSERT INTO foos (name) VALUES ('zub', 'zab')))
(println "Inserted " (sqlite-total-changes ?*db*) " records total.") ; Inserted 4 records total.
```

### `(sqlite-last-insert-rowid <DB-POINTER>)` -> `INTEGER` or `BOOLEAN`

#### Arguments

- `<DB-POINTER>` - A pointer to an opened connection.

#### Example

```clips
(defglobal ?*stmt* = (sqlite-prepare ?*db* "INSERT INTO foos (name) VALUES ('bar', 'baz')))
(sqlite-step ?*stmt*)
(println "Last inserted id: " (sqlite-last-insert-rowid ?*db*)) ; Last inserted id: 2
```

### `(sqlite-db-name <DB-POINTER> <INDEX>)` -> `INTEGER` or `BOOLEAN`

#### Arguments

- `<DB-POINTER>` - A pointer to an opened connection.

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
(sqlite-stmt-explain ?*stmt* 1) ; TRUE
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

### `(sqlite-bind-parameter-index <STATEMENT-POINTER> <PARAMETER-NAME>)` -> `INTEGER` or `BOOLEAN`

Returns the index of a named parameter in a prepared statement.

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

### `(sqlite-bind-parameter-name <STATEMENT-POINTER> <PARAMETER-INDEX>)` -> `SYMBOL` or `BOOLEAN`

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

### `(sqlite-sql <STATEMENT-POINTER>)` -> `STRING` or `BOOLEAN`

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

### `(sqlite-expanded-sql <STATEMENT-POINTER>)` -> `STRING` or `BOOLEAN`

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

### `(sqlite-normalized-sql <STATEMENT-POINTER>)` -> `STRING` or `BOOLEAN`

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

### `(sqlite-reset <STATEMENT-POINTER>)` -> `STRING` or `BOOLEAN`

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

### `(sqlite-clear-bindings <STATEMENT-POINTER>)` -> `STRING` or `BOOLEAN`

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

### `(sqlite-step <STATEMENT-POINTER>)` -> `STRING` or `BOOLEAN`

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

### `(sqlite-row-to-multifield <STATEMENT-POINTER>)` -> `MULTIFIELD` or `BOOLEAN`

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

### `(sqlite-row-to-fact <STATEMENT-POINTER> <DEFTEMPLATE-NAME>)` -> `FACT` or `BOOLEAN`

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

### `(sqlite-row-to-instance <STATEMENT-POINTER> <DEFCLASS-NAME> [<INSTANCE-NAME>] [<NAME-COLUMN-SLOT>])` -> `INSTANCE` or `BOOLEAN`

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

### `(sqlite-column-count <STATEMENT-POINTER>)` -> `INTEGER` or `BOOLEAN`

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

### `(sqlite-column-database-name <STATEMENT-POINTER> <COLUMN-INDEX>)` -> `STRING` or `BOOLEAN`

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

### `(sqlite-column-origin-name <STATEMENT-POINTER> <COLUMN-INDEX>)` -> `STRING` or `BOOLEAN`

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

### `(sqlite-column-table-name <STATEMENT-POINTER> <COLUMN-INDEX>)` -> `STRING` or `BOOLEAN`

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

### `(sqlite-column-name <STATEMENT-POINTER> <COLUMN-INDEX>)` -> `STRING` or `BOOLEAN`

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

### `(sqlite-column-type <STATEMENT-POINTER> <COLUMN-INDEX>)` -> `STRING` or `BOOLEAN`

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

### `(sqlite-column <STATEMENT-POINTER> <COLUMN-INDEX>)` -> `STRING`, `INTEGER`, `DOUBLE`, or `BOOLEAN`

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

### `(sqlite-errmsg <DATABASE-POINTER>)` -> `STRING` or `BOOLEAN`
### `(sqlite-busy-timeout <STATEMENT-POINTER> <MILLISECONDS>)` -> `BOOLEAN`

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

### `(sqlite-limit <STATEMENT-POINTER> <LIMIT> [<AMOUNT>])` -> `INTEGER` or `BOOLEAN`

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

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

#### Arguments

- `<BACKUP-POINTER>` - A pointer to an initialized backup.

### `(sqlite-backup-pagecount <BACKUP-POINTER>)` -> `INTEGER` or `BOOLEAN`

#### Arguments

- `<BACKUP-POINTER>` - A pointer to an initialized backup.

### `(sqlite-backup-remaining <BACKUP-POINTER>)` -> `INTEGER` or `BOOLEAN`

#### Arguments

- `<BACKUP-POINTER>` - A pointer to an initialized backup.

### `(sqlite-backup-finish <BACKUP-POINTER>)` -> `BOOLEAN`

#### Arguments

- `<BACKUP-POINTER>` - A pointer to an initialized backup.


## Development

```
make clean
```
