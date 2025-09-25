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

### `(sqlite-libversion-number)` -> `INTEGER`

Returns an integer equal to `SQLITE_VERSION_NUMBER`.

### `(sqlite-sourceid)` -> `SYMBOL`

Returns a pointer to a string constant whose value
is the same as the `SQLITE_SOURCE_ID` C preprocessor macro.

### `(sqlite-threadsafe)` -> `BOOLEAN`

Returns whether or not SQLite was compiled with Mutexes or not.
**NOTE**: This does not say whether CLIPS is threadsafe or not;
CLIPS is not threadsafe.

### `(sqlite-memory-used)` -> `INTEGER`

Returns the amount of memory currently used by SQLite in bytes.

### `(sqlite-memory-highwater [<SET>])` -> `INTEGER`

Returns the highest amount of memory used by SQLite in bytes.
If `<SET>` is `TRUE`, sets the memory highwater to the current
amount of bytes used by SQLite and returns the previous highest amount
before the set.

#### Arguments

- `<SET>` - A `BOOLEAN` value that, if included, sets the highwater number
  to the current amount of memory in use.

### `(sqlite-compileoption-get <OPTION-INTEGER>)` -> `SYMBOL`

Returns a `SYMBOL` that is the name of the compile option
whose constant represents the passed `<OPTION-INTEGER>`.

#### Arguments

- `<OPTION-INTEGER>` - An `INTEGER` for the name of the constant
  that should be returned.

### `(sqlite-compileoption-used <OPTION-LEXEME>)` -> `BOOLEAN`

Returns either `TRUE` or `FALSE` as to whether a given compile option
was set during compilation.

#### Arguments

- `<OPTION-LEXEME>` - A `SYMBOL` that represents the compile option constant
  that you want to determine whether or not it was included during compilation.

### `(sqlite-open <LEXEME>)` -> `INTEGER`

Opens a connection to either an in-memory or file-based database.

#### Arguments

- `<LEXEME>`: Either a `SYMBOL` or `STRING` that is a file path or `:memory:`

#### Returns

- A pointer to the opened database
- `FALSE` upon failure

#### Example

```clips
(defglobal ?*filedb* = (sqlite-open "./foo.db"))
(defglobal ?*in-memorydb* = (sqlite-open :memory:))
```

### `(sqlite-close <db-pointer>)`

Closes a connection to an opened database connection

#### Arguments

- `<db-pointer>`: Pointer to an opened database connection

#### Returns

- `TRUE` on successful close
- `FALSE` on failure

### `(sqlite-changes <DB-POINTER>)` -> `INTEGER` or `BOOLEAN`

Returns the number of changes that occurred in the database
due to the last run query.

#### Arguments

- `<DB-POINTER>` - A pointer to an opened connection.

### `(sqlite-total-changes <DB-POINTER>)` -> `INTEGER` or `BOOLEAN`

#### Arguments

- `<DB-POINTER>` - A pointer to an opened connection.

### `(sqlite-last-insert-rowid <DB-POINTER>)` -> `INTEGER` or `BOOLEAN`

#### Arguments

- `<DB-POINTER>` - A pointer to an opened connection.

### `(sqlite-db-name <DB-POINTER> <INDEX>)` -> `INTEGER` or `BOOLEAN`

#### Arguments

- `<DB-POINTER>` - A pointer to an opened connection.

### `(sqlite-db-filename <DB-POINTER> <DB-NAME>)` -> `INTEGER` or `BOOLEAN`

#### Arguments

- `<DB-POINTER>` - A pointer to an opened connection.

### `(sqlite-db-readonly <DB-POINTER> <DB-NAME>)` -> `INTEGER` or `BOOLEAN`

#### Arguments

- `<DB-POINTER>` - A pointer to an opened connection.

### `(sqlite-db-exists <DB-POINTER> <DB-NAME>)` -> `INTEGER` or `BOOLEAN`

#### Arguments

- `<DB-POINTER>` - A pointer to an opened connection.

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

### `(sqlite-stmt-explain <STATEMENT-POINTER> <INTEGER>)` -> `SYMBOL`, `INTEGER`, or `BOOLEAN`

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

### `(sqlite-stmt-isexplain <STATEMENT-POINTER>)` -> `SYMBOL` or `BOOLEAN`

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

### `(sqlite-bind <STATEMENT-POINTER> <POSITION-NAME-OR-VALUE> [<VALUE>])` -> `BOOLEAN`

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

### `(sqlite-finalize <STATEMENT-POINTER>)` -> `BOOLEAN`

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

### `(sqlite-bind-parameter-count <STATEMENT-POINTER>)` -> `INTEGER` or `BOOLEAN`

#### Arguments

- `<STATEMENT-POINTER>` - A pointer to a prepared statement.

### `(sqlite-bind-parameter-index <STATEMENT-POINTER> <PARAMETER-NAME>)` -> `INTEGER` or `BOOLEAN`

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
