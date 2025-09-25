(println
	"SQLite version "
	(sqlite-libversion)
	" ("
	(sqlite-libversion-number)
	") with amalgamation version "
	(sqlite-sourceid)
	crlf
	"Threadsafe: "
	(sqlite-threadsafe))

(deffunction expect (?expected ?actual ?failure-message)
	(if (eq ?expected ?actual) then (print ".") else (println crlf "FAILURE: " ?failure-message crlf tab "Expected: " ?expected crlf tab "Actual: " ?actual)))

(expect
	0
	(sqlite-memory-used)
	"Expected Memory Used before usage to be 0")
(expect
	0
	(sqlite-memory-highwater)
	"Expected Memory Highwater before setting to be 0")
(expect
	DEFAULT_RECURSIVE_TRIGGERS
	(sqlite-compileoption-get 10)
	"Expected compileoption 10 to be DEFAULT_RECURSIVE_TRIGGERS")

(expect
	TRUE
	(sqlite-compileoption-used DEFAULT_RECURSIVE_TRIGGERS)
	"Expected compileoption DEFAULT_RECURSIVE_TRIGGERS to have been used")

(defglobal ?*db* = (sqlite-open :memory:))
(expect
	1000000000
	(sqlite-limit ?*db* 0)
	"Checking 0 limit")
(expect
	1000000000
	(sqlite-limit ?*db* SQLITE_LIMIT_LENGTH)
	"Checking SQLITE_LIMIT_LENGTH limit")
(expect
	1000000000
	(sqlite-limit ?*db* 0 999999999)
	"Setting 0 limit")
(expect
	999999999
	(sqlite-limit ?*db* 0)
	"Checking 0 limit")
(expect
	999999999
	(sqlite-limit ?*db* SQLITE_LIMIT_LENGTH 999999998)
	"Setting SQLITE_LIMIT_LENGTH limit")
(expect
	999999998
	(sqlite-limit ?*db* 0)
	"Checking 0 limit")
(expect
	999999998
	(sqlite-limit ?*db* SQLITE_LIMIT_LENGTH)
	"Checking SQLITE_LIMIT_LENGTH limit")
(expect
	1000000000
	(sqlite-limit ?*db* 1)
	"Checking 1 limit")
(expect
	1000000000
	(sqlite-limit ?*db* SQLITE_LIMIT_SQL_LENGTH)
	"Checking SQLITE_LIMIT_SQL_LENGTH limit")
(expect
	2000
	(sqlite-limit ?*db* 2)
	"Checking 2 limit")
(expect
	2000
	(sqlite-limit ?*db* SQLITE_LIMIT_COLUMN)
	"Checking SQLITE_LIMIT_COLUMN limit")
(expect
	1000
	(sqlite-limit ?*db* 3)
	"Checking 3 limit")
(expect
	1000
	(sqlite-limit ?*db* SQLITE_LIMIT_EXPR_DEPTH)
	"Checking SQLITE_LIMIT_EXPR_DEPTH limit")
(expect
	500
	(sqlite-limit ?*db* 4)
	"Checking 4 limit")
(expect
	500
	(sqlite-limit ?*db* SQLITE_LIMIT_COMPOUND_SELECT)
	"Checking SQLITE_LIMIT_COMPOUND_SELECT limit")
(expect
	250000000
	(sqlite-limit ?*db* 5)
	"Checking 5 limit")
(expect
	250000000
	(sqlite-limit ?*db* SQLITE_LIMIT_VDBE_OP)
	"Checking SQLITE_LIMIT_VDBE_OP limit")
(expect
	127
	(sqlite-limit ?*db* 6)
	"Checking 6 limit")
(expect
	127
	(sqlite-limit ?*db* SQLITE_LIMIT_FUNCTION_ARG)
	"Checking SQLITE_LIMIT_FUNCTION_ARG limit")
(expect
	10
	(sqlite-limit ?*db* 7)
	"Checking 7 limit")
(expect
	10
	(sqlite-limit ?*db* SQLITE_LIMIT_ATTACHED)
	"Checking SQLITE_LIMIT_ATTACHED limit")
(expect
	50000
	(sqlite-limit ?*db* 8)
	"Checking 8 limit")
(expect
	50000
	(sqlite-limit ?*db* SQLITE_LIMIT_LIKE_PATTERN_LENGTH)
	"Checking SQLITE_LIMIT_LIKE_PATTERN_LENGTH limit")
(expect
	250000
	(sqlite-limit ?*db* 9)
	"Checking 9 limit")
(expect
	250000
	(sqlite-limit ?*db* SQLITE_LIMIT_VARIABLE_NUMBER)
	"Checking SQLITE_LIMIT_VARIABLE_NUMBER limit")
(expect
	1000
	(sqlite-limit ?*db* 10)
	"Checking 10 limit")
(expect
	1000
	(sqlite-limit ?*db* SQLITE_LIMIT_TRIGGER_DEPTH)
	"Checking SQLITE_LIMIT_TRIGGER_DEPTH limit")
(expect
	0
	(sqlite-limit ?*db* 11)
	"Checking 11 limit")
(expect
	0
	(sqlite-limit ?*db* SQLITE_LIMIT_WORKER_THREADS)
	"Checking SQLITE_LIMIT_WORKER_THREADS limit")
(expect
	TRUE
	(sqlite-busy-timeout ?*db* 0)
	"Had issue setting busy timeout")

(defglobal ?*stmt-o* = (sqlite-prepare ?*db* "SELECT ?1, ?2, ?3"))
(expect
	"SELECT ?1, ?2, ?3"
	(sqlite-sql ?*stmt-o*)
	"Encountered an issue with sqlite-sql")
(expect
	"SELECT NULL, NULL, NULL"
	(sqlite-expanded-sql ?*stmt-o*)
	"Encountered an issue with sqlite-expanded-sql")
(expect
	FALSE
	(sqlite-close ?*db*)
	"Expected to not be able to close db connection yet")
(expect
	"unable to close due to unfinalized statements or unfinished backups"
	(sqlite-errmsg ?*db*)
	"Expected specific error message from sqlite-errmsg")
(expect
	TRUE
	(sqlite-bind ?*stmt-o* (create$ "alpha" 42 3.14))
	"Encountered issue with sqlite-bind")
(expect
	"SELECT 'alpha', 42, 3.14"
	(sqlite-expanded-sql ?*stmt-o*)
	"Encountered an issue with sqlite-expanded-sql after binding")
(expect
	TRUE
	(sqlite-clear-bindings ?*stmt-o*)
	"Encountered issue with sqlite-clear-bindings")
(expect
	"SELECT NULL, NULL, NULL"
	(sqlite-expanded-sql ?*stmt-o*)
	"Encountered an issue with sqlite-expanded-sql")
(expect
	TRUE
	(sqlite-bind ?*stmt-o* (create$ "alpha" 42 3.14))
	"Encountered issue with sqlite-bind")
(expect
	SQLITE_ROW
	(sqlite-step ?*stmt-o*)
	"Expected SQLITE_ROW for first sqlite-step")
(expect
	(create$ "alpha" 42 3.14)
	(sqlite-row-to-multifield ?*stmt-o*)
	"Expected multifield of row")
(expect
	FALSE
	(sqlite-column-database-name ?*stmt-o* 1)
	"Expected FALSE when getting database name from column")
(expect
	FALSE
	(sqlite-column-table-name ?*stmt-o* 1)
	"Expected FALSE when getting table name from column")
(expect
	FALSE
	(sqlite-column-origin-name ?*stmt-o* 1)
	"Expected FALSE when getting origin name from column")
(expect
	SQLITE_DONE
	(sqlite-step ?*stmt-o*)
	"Expected SQLITE_DONE for second sqlite-step")
(expect
	TRUE
	(sqlite-reset ?*stmt-o*)
	"Expected to be able to reset statement")
(expect
	SQLITE_ROW
	(sqlite-step ?*stmt-o*)
	"Expected SQLITE_ROW for first sqlite-step")
(expect
	SQLITE_DONE
	(sqlite-step ?*stmt-o*)
	"Expected SQLITE_DONE for second sqlite-step")
(expect
	TRUE
	(sqlite-reset ?*stmt-o*)
	"Expected to be able to reset statement")
(expect
	SQLITE_ROW
	(sqlite-step ?*stmt-o*)
	"Expected SQLITE_ROW for first sqlite-step")
(expect
	TRUE
	(sqlite-reset ?*stmt-o*)
	"Expected to be able to reset statement")
(expect
	SQLITE_ROW
	(sqlite-step ?*stmt-o*)
	"Expected SQLITE_ROW for first sqlite-step after reset")
(expect
	3
	(sqlite-column-count ?*stmt-o*)
	"Expected 3 columns for sqlite-column-count")
(expect
	SQLITE_TEXT
	(sqlite-column-type ?*stmt-o* 0)
	"Expected SQLITE_TEXT for column 0's type")
(expect
	"?1"
	(sqlite-column-name ?*stmt-o* 0)
	"Expected ?1 for column 0's name")
(expect
	SQLITE_INTEGER
	(sqlite-column-type ?*stmt-o* 1)
	"Expected SQLITE_INTEGER for column 1's type")
(expect
	"?2"
	(sqlite-column-name ?*stmt-o* 1)
	"Expected ?2 for column 1's name")
(expect
	SQLITE_FLOAT
	(sqlite-column-type ?*stmt-o* 2)
	"Expected SQLITE_FLOAT for column 2's type")
(expect
	"?3"
	(sqlite-column-name ?*stmt-o* 2)
	"Expected ?3 for column 2's name")
(expect
	SQLITE_NULL
	(sqlite-column-type ?*stmt-o* 3)
	"Expected SQLITE_NULL for column 3's type")
(expect
	FALSE
	(sqlite-column-name ?*stmt-o* 3)
	"Expected FALSE and an error message for column 3's name")
(expect
	TRUE
	(sqlite-finalize ?*stmt-o*)
	"Expected to be able to finalize ?*stmt-o*")

(println)

(defglobal ?*stmt-p* = (sqlite-prepare ?*db* "SELECT ?1, ?2"))
(expect
	"SELECT ?1, ?2"
	(sqlite-sql ?*stmt-p*)
	"Encountered an issue with sqlite-sql")
(expect
	"SELECT NULL, NULL"
	(sqlite-expanded-sql ?*stmt-p*)
	"Encountered an issue with sqlite-expanded-sql")
(expect
	TRUE
	(sqlite-bind ?*stmt-p* 1 "first")
	"Encountered an issue with binding to position 1")
(expect
	"SELECT 'first', NULL"
	(sqlite-expanded-sql ?*stmt-p*)
	"Encountered an issue with sqlite-expanded-sql")
(expect
	TRUE
	(sqlite-bind ?*stmt-p* 2 "second")
	"Encountered an issue with binding to position 2")
(expect
	"SELECT 'first', 'second'"
	(sqlite-expanded-sql ?*stmt-p*)
	"Encountered an issue with sqlite-expanded-sql")
(expect
	TRUE
	(sqlite-finalize ?*stmt-p*)
	"Expected to be able to finalize ?*stmt-p*")

(println)

;; 3) named bind (3 args; 2nd = lexeme like :name/@name/$name)
(defglobal ?*stmt-n* = (sqlite-prepare ?*db* "SELECT :x AS xx, :y AS yy"))
(expect
	:x
	(sqlite-bind-parameter-name ?*stmt-n* 1)
	"Expected to get first bind parameter name")
(expect
	:y
	(sqlite-bind-parameter-name ?*stmt-n* 2)
	"Expected to get second bind parameter name")
(expect
	1
	(sqlite-bind-parameter-index ?*stmt-n* :x)
	"Expected to be able to get index of :x bind parameter name")
(expect
	2
	(sqlite-bind-parameter-index ?*stmt-n* :y)
	"Expected to be able to get index of :y bind parameter name")
(expect
	SQLITE_NULL
	(sqlite-column-type ?*stmt-n* 0)
	"Expected SQLITE_NULL for column 0's type")
(expect
	"xx"
	(sqlite-column-name ?*stmt-n* 0)
	"Expected xx for column 0's name")
(expect
	SQLITE_NULL
	(sqlite-column-type ?*stmt-n* 1)
	"Expected SQLITE_NULL for column 1's type")
(expect
	"yy"
	(sqlite-column-name ?*stmt-n* 1)
	"Expected yy for column 1's name")
(expect
	SQLITE_NULL
	(sqlite-column-type ?*stmt-n* 2)
	"Expected SQLITE_NULL for column 2's type")
(expect
	FALSE
	(sqlite-column-name ?*stmt-n* 2)
	"Expected FALSE for column 2's name")
(expect
	"SELECT :x AS xx, :y AS yy"
	(sqlite-sql ?*stmt-n*)
	"Something went wrong with sqlite-sql")
(expect
	"SELECT NULL AS xx, NULL AS yy"
	(sqlite-expanded-sql ?*stmt-n*)
	"Something went wrong with sqlite-expanded-sql before binding")
(expect
	TRUE
	(sqlite-bind ?*stmt-n* :x "hello")
	"Encountered an issue with binding to named parameter :x")
(expect
	"SELECT 'hello' AS xx, NULL AS yy"
	(sqlite-expanded-sql ?*stmt-n*)
	"Something went wrong with sqlite-expanded-sql after first binding")
(expect
	TRUE
	(sqlite-bind ?*stmt-n* :y 123)
	"Encountered an issue with binding to named parameter :y")
(expect
	"SELECT 'hello' AS xx, 123 AS yy"
	(sqlite-expanded-sql ?*stmt-n*)
	"Something went wrong with sqlite-expanded-sql after second binding")
(expect
	TRUE
	(sqlite-reset ?*stmt-n*)
	"Expected to be able to reset statement")
(expect
	SQLITE_ROW
	(sqlite-step ?*stmt-n*)
	"Expected to be able to sqlite-step ?*stmt-n*")
(expect
	SQLITE_TEXT
	(sqlite-column-type ?*stmt-n* 0)
	"Expected SQLITE_TEXT for column 0's type")
(expect
	SQLITE_INTEGER
	(sqlite-column-type ?*stmt-n* 1)
	"Expected SQLITE_INTEGER for column 1's type")
(expect
	SQLITE_NULL
	(sqlite-column-type ?*stmt-n* 2)
	"Expected SQLITE_NULL for column 2's type")
(expect
	TRUE
	(sqlite-finalize ?*stmt-n*)
	"Expected to be able to finalize ?*stmt-n*")

(println)

(defglobal ?*stmt-m1* = (sqlite-prepare ?*db* "CREATE TABLE foos(id integer primary key autoincrement, name text)"))
(expect
	SQLITE_DONE
	(sqlite-step ?*stmt-m1*)
	"Expected SQLITE_DONE from CREATE TABLE statement")

(expect 0
	(sqlite-changes ?*db*)
	"Expected no changes yet")

(expect 0
	(sqlite-total-changes ?*db*)
	"Expected no total-changes yet")

(expect 0
	(sqlite-last-insert-rowid ?*db*)
	"No idea what this should be")

(defglobal ?*stmt-m2* = (sqlite-prepare ?*db* "INSERT INTO foos (name) VALUES ('Foo baz'), ('Baz bat'), ('co cuz')"))
(expect
	SQLITE_DONE
	(sqlite-step ?*stmt-m2*)
	"Expected SQLITE_DONE from INSERT INTO statement")

(expect 3
	(sqlite-changes ?*db*)
	"Expected 3 changes from first INSERT")

(expect 3
	(sqlite-total-changes ?*db*)
	"Expected 3 total-changes after first INSERT")

(expect 3
	(sqlite-last-insert-rowid ?*db*)
	"Last inserted rowid should be 3 after first 3 inserted records")

(defglobal ?*stmt-m3* = (sqlite-prepare ?*db* "INSERT INTO foos (name) VALUES ('one more')"))
(expect
	SQLITE_DONE
	(sqlite-step ?*stmt-m3*)
	"Expected SQLITE_DONE from INSERT INTO statement")

(expect 1
	(sqlite-changes ?*db*)
	"Expected 1 changes from second INSERT")

(expect 4
	(sqlite-total-changes ?*db*)
	"Expected 4 total-changes after second INSERT")

(expect 4
	(sqlite-last-insert-rowid ?*db*)
	"Last inserted rowid should be 4 after second INSERT")

(defglobal ?*stmt-m4* = (sqlite-prepare ?*db* "SELECT * FROM foos WHERE id=? AND name LIKE ?"))

(expect
	2
	(sqlite-bind-parameter-count ?*stmt-m4*)
	"Expected number of bind parameters to be 2")

(expect
	TRUE
	(sqlite-bind ?*stmt-m4* 1 1)
	"Expected to be able to bind 1 to the first column id")
(expect
	TRUE
	(sqlite-bind ?*stmt-m4* 2 "%oo b%")
	"Expected to be able to bind '%oo b%' to the first column name")

(expect
	"SELECT * FROM foos WHERE id=? AND name LIKE ?"
	(sqlite-sql ?*stmt-m4*)
	"Issue when running sqlite-sql")

(expect
	"SELECT * FROM foos WHERE id=1 AND name LIKE '%oo b%'"
	(sqlite-expanded-sql ?*stmt-m4*)
	"Expected id and LIKE to be replaced by bindings")

(expect
	SQLITE_ROW
	(sqlite-step ?*stmt-m4*)
	"Expected SQLITE_ROW from SELECT statement")

(expect
	(create$ 1 "Foo baz")
	(sqlite-row-to-multifield ?*stmt-m4*)
	"Expected multifield of row")

(deftemplate row
	(slot id)
	(slot name))

(expect
	(assert (row (id 1) (name "Foo baz")))
	(sqlite-row-to-fact ?*stmt-m4* row)
	"Expected fact of row")

(defclass ROW
	(is-a USER)
	(slot id)
	(slot _name))

(defglobal ?*instance* = (sqlite-row-to-instance ?*stmt-m4* ROW))
(expect
	1
	(send ?*instance* get-id)
	"Expected instance of row with id 1")
(expect
	"Foo baz"
	(send ?*instance* get-_name)
	"Expected instance of row with name \"Foo baz\"")

(defglobal ?*instance* = (sqlite-row-to-instance ?*stmt-m4* ROW foo))

(expect
	[foo]
	(instance-name ?*instance*)
	"Expected instance with name [foo]")
(expect
	1
	(send ?*instance* get-id)
	"Expected instance of row with id 1")
(expect
	"Foo baz"
	(send ?*instance* get-_name)
	"Expected instance of row with name \"Foo baz\"")

(defclass ROW2
	(is-a USER)
	(slot id)
	(slot asdf))
(defglobal ?*instance* = (sqlite-row-to-instance ?*stmt-m4* ROW2 nil asdf))

(expect
	1
	(send ?*instance* get-id)
	"Expected instance of row with id 1")
(expect
	"Foo baz"
	(send ?*instance* get-asdf)
	"Expected instance of row with asdf \"Foo baz\"")
(expect
	TRUE
	(sqlite-db-exists ?*db* main)
	"Expected database \"main\" to exist in ?*db*")
(expect
	FALSE
	(sqlite-db-exists ?*db* "temp")
	"Expected database \"temp\" not to exist in ?*db*")
(expect
	FALSE
	(sqlite-db-exists ?*db* "asdf")
	"Expected database \"asdf\" not to exist in ?*db*")
(expect
	"main"
	(sqlite-column-database-name ?*stmt-m4* 1)
	"Expected database name for column to be \"main\"")
(expect
	"foos"
	(sqlite-column-table-name ?*stmt-m4* 1)
	"Expected table name for column to be \"foos\"")
(expect
	"name"
	(sqlite-column-origin-name ?*stmt-m4* 1)
	"Expected origin name for column to be \"name\"")
(expect
	1
	(sqlite-column ?*stmt-m4* 0)
	"Expected value 1 for first column id")

(expect
	"Foo baz"
	(sqlite-column ?*stmt-m4* 1)
	"Expected value 'Foo baz' for second column name")

(expect
	TRUE
	(sqlite-finalize ?*stmt-m1*)
	"Expected to be able to finalize CREATE TABLE statement")
(expect
	TRUE
	(sqlite-reset ?*stmt-m2*)
	"Expected to be able to reset INSERT statement before explaining with mode 1")
(expect
	FALSE
	(sqlite-stmt-isexplain ?*stmt-m2*)
	"Expected isexplain to be FALSE before setting it")
(expect
	TRUE
	(sqlite-stmt-explain ?*stmt-m2* 1)
	"Expected to be able to update INSERT statement into explain with mode 1")
(expect
	"EXPLAIN"
	(sqlite-stmt-isexplain ?*stmt-m2*)
	"Expected isexplain to be EXPLAIN after setting it with mode 1")
(expect
	SQLITE_ROW
	(sqlite-step ?*stmt-m2*)
	"Expected to be able to explain INSERT statement")
(expect
	0
	(sqlite-column ?*stmt-m2* 0)
	"Expected to be able to read program counter from explain INSERT statement")
(expect
	"Init"
	(sqlite-column ?*stmt-m2* 1)
	"Expected to be able to read name of operation from explain INSERT statement")
(expect
	1
	(sqlite-column ?*stmt-m2* 2)
	"Expected to be able to read p1 from explain INSERT statement")
(expect
	26
	(sqlite-column ?*stmt-m2* 3)
	"Expected to be able to read p2 from explain INSERT statement")
(expect
	0
	(sqlite-column ?*stmt-m2* 4)
	"Expected to be able to read p3 from explain INSERT statement")
(expect
	nil
	(sqlite-column ?*stmt-m2* 5)
	"Expected to be able to read p4 from explain INSERT statement")
(expect
	0
	(sqlite-column ?*stmt-m2* 6)
	"Expected to be able to read p5 from explain INSERT statement")
(expect
	nil
	(sqlite-column ?*stmt-m2* 7)
	"Expected to be able to read comment from explain INSERT statement")
(expect
	TRUE
	(sqlite-reset ?*stmt-m2*)
	"Expected to be able to reset INSERT statement before explaining with mode 2")
(expect
	TRUE
	(sqlite-stmt-explain ?*stmt-m2* 2)
	"Expected to be able to update INSERT statement into explain with mode 2")
(expect
	"EXPLAIN QUERY PLAN"
	(sqlite-stmt-isexplain ?*stmt-m2*)
	"Expected isexplain to be EXPLAIN QUERY PLAN after setting it with mode 2")
(expect
	SQLITE_ROW
	(sqlite-step ?*stmt-m2*)
	"Expected to be able to explain INSERT statement")
(expect
	9
	(sqlite-column ?*stmt-m2* 0)
	"Expected to be able to read selectid from explain INSERT statement")
(expect
	0
	(sqlite-column ?*stmt-m2* 1)
	"Expected to be able to read order from explain INSERT statement")
(expect
	0
	(sqlite-column ?*stmt-m2* 2)
	"Expected to be able to read from from explain INSERT statement")
(expect
	"SCAN 3-ROW VALUES CLAUSE"
	(sqlite-column ?*stmt-m2* 3)
	"Expected to be able to read description of how SQLite plans to execute the query from explain INSERT statement")
(expect
	TRUE
	(sqlite-finalize ?*stmt-m2*)
	"Expected to be able to finalize INSERT statement")

(expect
	TRUE
	(sqlite-finalize ?*stmt-m3*)
	"Expected to be able to finalize INSERT statement")

(expect
	TRUE
	(sqlite-finalize ?*stmt-m4*)
	"Expected to be able to finalize SELECT statement")

(println)

(defglobal ?*db-in-memory* = (sqlite-open :memory:))

(expect
	"main"
	(sqlite-db-name ?*db-in-memory* 0)
	"Something went wrong with sqlite-db-name")
(expect
	"temp"
	(sqlite-db-name ?*db-in-memory* 1)
	"Something went wrong with sqlite-db-name")
(expect
	FALSE
	(sqlite-db-name ?*db-in-memory* 2)
	"Something went wrong with sqlite-db-name")
(expect
	FALSE
	(sqlite-db-filename ?*db-in-memory* "main")
	"Something went wrong with sqlite-db-filename getting main database from db-in-memory")
(expect
	FALSE
	(sqlite-db-filename ?*db-in-memory* "temp")
	"Something went wrong with sqlite-db-filename getting temp database from db-in-memory")

(expect
	TRUE
	(sqlite-close ?*db-in-memory*)
	"Expected to be able to close db-in-memory connection")

(defglobal ?*db-file* = (sqlite-open ./foo2.db))

(expect
	"main"
	(sqlite-db-name ?*db-file* 0)
	"Something went wrong with sqlite-db-name")
(expect
	"temp"
	(sqlite-db-name ?*db-file* 1)
	"Something went wrong with sqlite-db-name")
(expect
	FALSE
	(sqlite-db-name ?*db-file* 2)
	"Something went wrong with sqlite-db-name")

(defglobal ?*filename* = (sqlite-db-filename ?*db-file* "main"))
(expect
	"/foo2.db"
	(sub-string (- (str-length ?*filename*) 7) (str-length ?*filename*) ?*filename*)
	"Something went wrong with sqlite-db-filename when getting filename for main")
(expect
	FALSE
	(sqlite-db-filename ?*db-file* "temp")
	"Something went wrong with sqlite-db-filename when getting filename for temp")

(defglobal ?*backup* = (sqlite-backup-init ?*db-file* "main" ?*db* "main"))
(defglobal ?*select* = (sqlite-prepare ?*db-file* "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))
(expect
	SQLITE_ROW
	(sqlite-step ?*select*)
	"Expected ?*select* to execute successfully and get number of tables")

(expect
	0
	(sqlite-column ?*select* 0)
	"Expected ?*db-file* database to not have any tables yet")

(defglobal ?*pagecount* = (sqlite-backup-pagecount ?*backup*))
(defglobal ?*previous-pages* = (sqlite-backup-remaining ?*backup*))

(expect
	?*pagecount*
	?*previous-pages*
	"Expected pagecount and number of pages remaining to be the same before stepping through backup")

(expect
	SQLITE_DONE
	(sqlite-backup-step ?*backup* -1)
	"Expected negative number to backup all remaining pages")

(defglobal ?*new-pages* = (sqlite-backup-remaining ?*backup*))
(expect
	0
	?*new-pages*
	"Expected no more remaining pages for backup")

(if (>= ?*previous-pages* ?*new-pages*) then (print ".") else (println crlf "FAILURE: expected previous pages to be bigger than new pages."))
(expect
	TRUE
	(sqlite-reset ?*select*)
	"Expected to be able to reset ?*select*")

(expect
	SQLITE_ROW
	(sqlite-step ?*select*)
	"Expected ?*select* to execute successfully and get number of tables after backup")

(expect
	1
	(sqlite-column ?*select* 0)
	"Expected ?*db-file* database to have a single table after backup")

(expect
	TRUE
	(sqlite-finalize ?*select*)
	"Expected to be able to finalize SELECT statement")

(expect
	TRUE
	(sqlite-backup-finish ?*backup*)
	"Expected to be able to finish db-file backup")

(expect
	TRUE
	(sqlite-close ?*db-file*)
	"Expected to be able to close db-file connection")

(expect
	FALSE
	(sqlite-db-readonly ?*db* "main")
	"Expected main db in ?*db* to not be readonly")

(expect
	FALSE
	(sqlite-db-readonly ?*db* "temp")
	"Expected main db in ?*db* to not have temp db")

(if (> (sqlite-memory-used) 0) then (print ".") else (println crlf "FAILURE: expected memory used to be greater than 0."))

(defglobal ?*previous-highwater* = (sqlite-memory-highwater TRUE))

(if (> ?*previous-highwater* (sqlite-memory-highwater TRUE)) then (print ".") else (println crlf "FAILURE: expected previous memory highwater to be greater what it is now."))

(expect
	(sqlite-memory-used)
	(sqlite-memory-highwater)
	"Expected new highwater to equal memory used now")

(expect
	TRUE
	(sqlite-close ?*db*)
	"Expected to be able to close db connection")

(defglobal ?*db-readonly* = (sqlite-open ./foo-readonly.db))

(expect
	FALSE
	(sqlite-db-readonly ?*db-readonly* "main")
	"Expected main db in ?*db-readonly* to not be readonly")
(expect
	TRUE
	(sqlite-close ?*db-readonly*)
	"Expected to be able to close ?*db-readonly* connection before re-opening as READONLY")
(defglobal ?*db-readonly* = (sqlite-open ./foo-readonly.db SQLITE_OPEN_READONLY))

(expect
	TRUE
	(sqlite-db-readonly ?*db-readonly* "main")
	"Expected main db in ?*db-readonly* to be readonly")

(expect
	TRUE
	(sqlite-close ?*db-readonly*)
	"Expected to be able to close ?*db-readonly* connection")

(defglobal ?*db-readonly2* = (sqlite-open ./foo-readonly2.db))

(expect
	FALSE
	(sqlite-db-readonly ?*db-readonly2* "main")
	"Expected main db in ?*db-readonly2* to not be readonly")
(expect
	TRUE
	(sqlite-close ?*db-readonly2*)
	"Expected to be able to close ?*db-readonly2* connection before re-opening as READONLY")
(defglobal ?*db-readonly2* = (sqlite-open ./foo-readonly2.db (create$ SQLITE_OPEN_READONLY)))

(expect
	TRUE
	(sqlite-db-readonly ?*db-readonly2* "main")
	"Expected main db in ?*db-readonly2* to be readonly")

(expect
	TRUE
	(sqlite-close ?*db-readonly2*)
	"Expected to be able to close ?*db-readonly2* connection")

(defglobal ?*ms* = (sqlite-sleep 100))
(if (>= ?*ms* 100) then (print ".") else (println crlf "FAILURE: sqlite-sleep 100 should be 100 or more, was " ?*ms*))

(expect
	0
	(sqlite-memory-used)
	"Expected Memory Used after closing all databases to be 0")

(println)
(system "rm ./foo2.db ./foo-readonly.db ./foo-readonly2.db ")
