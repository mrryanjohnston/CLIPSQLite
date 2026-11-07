; ============================================================
; WORKING MEMORY
;
; sqlite-stmt-to-facts / -to-instances / -to-multifield and their
; query-taking halves: one call that walks every row a statement has left
; and answers a multifield of what it made.  The row-mapping suite covers the
; type mapping, which these share with sqlite-row-to-fact; what is under test
; here is the walk -- which rows, in what order, what a lost row costs, and
; what a query-taking call infers when it is not told the construct.
;
; Every refusal below is bound on a line of its own and asserted on the next,
; for the reason tests/test.bat gives.
; ============================================================

(defglobal
  ?*wm-db* = FALSE
  ?*wm-st* = FALSE
  ?*wm-r*  = nothing
  ?*wm-f*  = FALSE
  ?*wm-i*  = FALSE
  ?*wm-m*  = FALSE)

(bind ?*wm-db* (sqlite-open :memory:))
(expect "the connection opened" TRUE (pointerp ?*wm-db*))

; ------------------------------------------------------------
; fixtures
;
; A statement that answers no rows -- a CREATE, an INSERT -- still walks to
; SQLITE_DONE and answers an empty multifield, which makes the multifield form
; the shortest way to run one.  That the answer is empty is the first check.
; ------------------------------------------------------------

(bind ?*wm-r* (sqlite-query-to-multifield ?*wm-db*
  "CREATE TABLE wm_orders(id INTEGER, product TEXT, amount REAL);"))
(expect "a CREATE runs and answers an empty multifield" (create$) ?*wm-r*)
(bind ?*wm-r* (sqlite-query-to-multifield ?*wm-db*
  "INSERT INTO wm_orders VALUES (1,'widget',19.99),(2,'gadget',49.5),(3,NULL,99.0);"))
(expect "and so does an INSERT" (create$) ?*wm-r*)
(expect "which wrote its rows" 3 (sqlite-changes ?*wm-db*))

; a second table with no deftemplate and no defclass of its own, for the
; refusals that need one
(bind ?*wm-r* (sqlite-query-to-multifield ?*wm-db* "CREATE TABLE wm_plain(id INTEGER);"))
(expect "a table with no deftemplate" (create$) ?*wm-r*)

; ------------------------------------------------------------
; the fact form, with the deftemplate named
; ------------------------------------------------------------

(bind ?*wm-f* (sqlite-query-to-facts ?*wm-db*
  "SELECT id, product, amount FROM wm_orders ORDER BY id;" wm_orders))
(expect "one fact per row" 3 (length$ ?*wm-f*))
(expect "the answer holds fact addresses" TRUE (fact-existp (nth$ 1 ?*wm-f*)))
(expect "an INTEGER column lands in its slot" 1 (fact-slot-value (nth$ 1 ?*wm-f*) id))
(expect "a TEXT column lands in its slot" "widget" (fact-slot-value (nth$ 1 ?*wm-f*) product))
(expect "a REAL column lands in its slot" 19.99 (fact-slot-value (nth$ 1 ?*wm-f*) amount))
(expect "in row order" 3 (fact-slot-value (nth$ 3 ?*wm-f*) id))
(expect "and a NULL cell is nil" nil (fact-slot-value (nth$ 3 ?*wm-f*) product))

; the facts are in working memory, not merely described
(expect "the facts are in working memory" 1
        (length$ (find-all-facts ((?f wm_orders)) (= ?f:id 2))))

; the statement was finalized on the way out: the connection is not holding
; a read lock on wm_orders, so it can be dropped and recreated at will
(bind ?*wm-r* (sqlite-query-to-multifield ?*wm-db* "DROP TABLE wm_plain;"))
(expect "the query form finalizes its statement" (create$) ?*wm-r*)
(bind ?*wm-r* (sqlite-query-to-multifield ?*wm-db* "CREATE TABLE wm_plain(id INTEGER);"))
(expect "so the schema can change after it" (create$) ?*wm-r*)

; a deftemplate may be given as a string as well as a symbol
(bind ?*wm-r* (sqlite-query-to-facts ?*wm-db*
  "SELECT id, product, amount FROM wm_orders ORDER BY id;" "wm_orders"))
(expect "the deftemplate may be a string" 3 (length$ ?*wm-r*))

; ------------------------------------------------------------
; a repeated row
;
; CLIPS refuses a duplicate fact, and the assert answers the fact that
; already holds the row rather than nothing.  So the answer stays row-aligned
; while working memory does not grow.
; ------------------------------------------------------------

(bind ?*wm-r* (sqlite-query-to-facts ?*wm-db*
  "SELECT id, product, amount FROM wm_orders ORDER BY id;" wm_orders))
(expect "a repeated query still answers one entry per row" 3 (length$ ?*wm-r*))
(expect "naming the facts that already held those rows"
        (nth$ 1 ?*wm-f*) (nth$ 1 ?*wm-r*))
(expect "so working memory did not grow" 3
        (length$ (find-all-facts ((?f wm_orders)) TRUE)))

; ------------------------------------------------------------
; the deftemplate inferred from the table the columns come from
;
; SQLite knows which table each result column was read from, and when every
; column that came from a table came from the same one, that is the name.
; ------------------------------------------------------------

(bind ?*wm-r* (sqlite-query-to-facts ?*wm-db*
  "SELECT id, product, amount FROM wm_orders ORDER BY id;"))
(expect "the deftemplate is inferred from the table" 3 (length$ ?*wm-r*))
(expect "and is the same one the named call used" (nth$ 1 ?*wm-f*) (nth$ 1 ?*wm-r*))

; an expression column comes from no table and does not get in the way
(bind ?*wm-r* (sqlite-query-to-facts ?*wm-db*
  "SELECT id, product, sum(amount) AS amount FROM wm_orders GROUP BY id, product;"))
(expect "a GROUP BY with an aggregate still infers" 3 (length$ ?*wm-r*))

; an alias is not the name: the table is what the column was read from
(bind ?*wm-r* (sqlite-query-to-facts ?*wm-db* "SELECT o.id FROM wm_orders AS o;"))
(expect "an aliased table infers its real name" 3 (length$ ?*wm-r*))

; a self-join reads one table twice, which is still one table
(bind ?*wm-r* (sqlite-query-to-facts ?*wm-db*
  "SELECT a.id, b.product FROM wm_orders a JOIN wm_orders b ON a.id = b.id;"))
(expect "a self-join infers" 3 (length$ ?*wm-r*))

; a join whose selected columns all come from one table infers that table,
; whatever else the FROM clause reads
(bind ?*wm-r* (sqlite-query-to-facts ?*wm-db*
  "SELECT a.id FROM wm_orders a LEFT JOIN wm_plain b ON a.id = b.id;"))
(expect "a join selecting from one table infers it" 3 (length$ ?*wm-r*))

; ------------------------------------------------------------
; the instance form
; ------------------------------------------------------------

(bind ?*wm-i* (sqlite-query-to-instances ?*wm-db*
  "SELECT id, product, amount FROM wm_orders ORDER BY id;" WM_ORDERS))
(expect "one instance per row" 3 (length$ ?*wm-i*))
(expect "the answer holds instance addresses" TRUE (instance-addressp (nth$ 1 ?*wm-i*)))
(expect "of the class asked for" WM_ORDERS (class (nth$ 1 ?*wm-i*)))
(expect "a slot carries what the row held" 1 (send (nth$ 1 ?*wm-i*) get-id))
(expect "and so does a string slot" "widget" (send (nth$ 1 ?*wm-i*) get-product))
(expect "and a NULL is nil here too" nil (send (nth$ 3 ?*wm-i*) get-product))

; unlike facts, instances are not deduplicated: each call makes new ones
(bind ?*wm-r* (sqlite-query-to-instances ?*wm-db*
  "SELECT id, product, amount FROM wm_orders ORDER BY id;" WM_ORDERS))
(expect "a second call makes new instances" 3 (length$ ?*wm-r*))
(expect "which are not the first call's" FALSE (eq (nth$ 1 ?*wm-r*) (nth$ 1 ?*wm-i*)))

; the defclass is inferred as the table name uppercased, which is how class
; names are spelled everywhere else in CLIPS
(bind ?*wm-r* (sqlite-query-to-instances ?*wm-db*
  "SELECT id, product, amount FROM wm_orders ORDER BY id;"))
(expect "the defclass is inferred" 3 (length$ ?*wm-r*))
(expect "as the table name uppercased" WM_ORDERS (class (nth$ 1 ?*wm-r*)))

; ------------------------------------------------------------
; naming the instances
;
; A final argument says what the rows should be called.  It is positional:
; the nth name goes to the nth row, and a row with no name of its own --
; past the end of a short list, or every row when the argument is left out
; -- is named by CLIPS.  A single lexeme is the one-entry list, so it names
; the first row and nothing else.
; ------------------------------------------------------------

(bind ?*wm-r* (sqlite-query-to-instances ?*wm-db*
  "SELECT id, product, amount FROM wm_orders ORDER BY id;" WM_ORDERS
  (create$ WM-N-A WM-N-B WM-N-C)))
(expect "a name apiece still makes one instance per row" 3 (length$ ?*wm-r*))
(expect "the first row takes the first name" [WM-N-A] (instance-name (nth$ 1 ?*wm-r*)))
(expect "in row order" [WM-N-B] (instance-name (nth$ 2 ?*wm-r*)))
(expect "to the last of them" [WM-N-C] (instance-name (nth$ 3 ?*wm-r*)))
(expect "and the named instance holds the row" 1 (send (nth$ 1 ?*wm-r*) get-id))

; shorter than the result: the rows past the end are named by CLIPS
(bind ?*wm-r* (sqlite-query-to-instances ?*wm-db*
  "SELECT id FROM wm_orders ORDER BY id;" WM_ORDERS (create$ WM-N-SHORT)))
(expect "a short list still makes every row" 3 (length$ ?*wm-r*))
(expect "naming the rows it has entries for" [WM-N-SHORT] (instance-name (nth$ 1 ?*wm-r*)))
(expect "and leaving the rest to CLIPS" FALSE
        (eq (instance-name (nth$ 2 ?*wm-r*)) [WM-N-SHORT]))

; longer than the result is not a refusal either: the surplus is never asked for
(bind ?*wm-r* (sqlite-query-to-instances ?*wm-db*
  "SELECT id FROM wm_orders ORDER BY id;" WM_ORDERS
  (create$ WM-N-L1 WM-N-L2 WM-N-L3 WM-N-L4 WM-N-L5)))
(expect "a long list makes no more rows than the result has" 3 (length$ ?*wm-r*))
(expect "and the surplus names nothing" 0
        (length$ (find-all-instances ((?i WM_ORDERS)) (eq (instance-name ?i) [WM-N-L4]))))

; an empty multifield is the argument left out
(bind ?*wm-r* (sqlite-query-to-instances ?*wm-db*
  "SELECT id FROM wm_orders ORDER BY id;" WM_ORDERS (create$)))
(expect "an empty list names nothing" 3 (length$ ?*wm-r*))

; one lexeme is the one-entry list, so it names the first row only
(bind ?*wm-r* (sqlite-query-to-instances ?*wm-db*
  "SELECT id FROM wm_orders ORDER BY id;" WM_ORDERS WM-N-ONE))
(expect "a single symbol names the first row" [WM-N-ONE] (instance-name (nth$ 1 ?*wm-r*)))
(expect "and leaves the rest to CLIPS" FALSE
        (eq (instance-name (nth$ 2 ?*wm-r*)) [WM-N-ONE]))

; a STRING and an INSTANCE-NAME are taken as readily as a SYMBOL
(bind ?*wm-r* (sqlite-query-to-instances ?*wm-db*
  "SELECT id FROM wm_orders ORDER BY id;" WM_ORDERS
  (create$ "WM-N-STR" [WM-N-INS] WM-N-SYM)))
(expect "a string names a row" [WM-N-STR] (instance-name (nth$ 1 ?*wm-r*)))
(expect "so does an instance name" [WM-N-INS] (instance-name (nth$ 2 ?*wm-r*)))
(expect "and a symbol" [WM-N-SYM] (instance-name (nth$ 3 ?*wm-r*)))

; a multifield argument can arrive as a window onto a longer one -- rest$
; hands one over -- so the names are read from where the window starts
(bind ?*wm-r* (sqlite-query-to-instances ?*wm-db*
  "SELECT id FROM wm_orders ORDER BY id;" WM_ORDERS
  (rest$ (create$ WM-N-SKIPPED WM-N-SL1 WM-N-SL2))))
(expect "a sliced list starts where the slice does" [WM-N-SL1]
        (instance-name (nth$ 1 ?*wm-r*)))
(expect "and does not read the field in front of it" [WM-N-SL2]
        (instance-name (nth$ 2 ?*wm-r*)))
(expect "so the name outside the slice names nothing" 0
        (length$ (find-all-instances ((?i WM_ORDERS)) (eq (instance-name ?i) [WM-N-SKIPPED]))))

; a multifield in the third position is the names and not the class: a class
; is one lexeme and a name list is a multifield, so the two cannot be
; confused, and this is how a caller names rows and still lets the class be
; inferred
(bind ?*wm-r* (sqlite-query-to-instances ?*wm-db*
  "SELECT id FROM wm_orders ORDER BY id;" (create$ WM-N-INF)))
(expect "a multifield third argument still infers the class" WM_ORDERS
        (class (nth$ 1 ?*wm-r*)))
(expect "and names the rows" [WM-N-INF] (instance-name (nth$ 1 ?*wm-r*)))

; reusing a name is CLIPS's own rule: the old instance of the same class is
; deleted and a new one takes the name, so three rows sharing one name leave
; one instance behind and two stale addresses in the answer
(bind ?*wm-r* (sqlite-query-to-instances ?*wm-db*
  "SELECT id FROM wm_orders ORDER BY id;" WM_ORDERS
  (create$ WM-N-DUP WM-N-DUP WM-N-DUP)))
(expect "a repeated name answers a row apiece" 3 (length$ ?*wm-r*))
(expect "but leaves one instance holding the name" 1
        (length$ (find-all-instances ((?i WM_ORDERS)) (eq (instance-name ?i) [WM-N-DUP]))))
(expect "and it is the last row's" 3 (send (nth$ 3 ?*wm-r*) get-id))

; a name already held by an instance of another class loses that row and
; only that row: CLIPS refuses the build and halts, and the halt is undone so
; the row after it gets its own attempt.  The [INSMNGR16] line on stderr is
; CLIPS's own account of it.
(make-instance [WM-N-TAKEN] of WM_NAME_HOLDER)
(bind ?*wm-r* (sqlite-query-to-instances ?*wm-db*
  "SELECT id FROM wm_orders ORDER BY id;" WM_ORDERS
  (create$ WM-N-TAKEN WM-N-AFTER1 WM-N-AFTER2)))
(expect "a name another class holds loses its own row" 2 (length$ ?*wm-r*))
(expect "and only its own row" [WM-N-AFTER1] (instance-name (nth$ 1 ?*wm-r*)))
(expect "with the row after that intact too" [WM-N-AFTER2] (instance-name (nth$ 2 ?*wm-r*)))
(expect "and the instance holding the name is untouched" WM_NAME_HOLDER (class [WM-N-TAKEN]))

; a name that is not a lexeme is refused before any row is built, so the
; call leaves nothing half-named behind
(bind ?*wm-r* (sqlite-query-to-instances ?*wm-db*
  "SELECT id FROM wm_orders;" WM_ORDERS (create$ WM-N-BAD1 7 WM-N-BAD3)))
(expect "a non-lexeme name refuses the call" FALSE ?*wm-r*)
(expect "and builds nothing before it refuses" 0
        (length$ (find-all-instances ((?i WM_ORDERS)) (eq (instance-name ?i) [WM-N-BAD1]))))

; the names cannot be given twice: a multifield third argument is already them
(bind ?*wm-r* (sqlite-query-to-instances ?*wm-db*
  "SELECT id FROM wm_orders;" (create$ WM-N-X) (create$ WM-N-Y)))
(expect "the names given twice refuses" FALSE ?*wm-r*)

; ------------------------------------------------------------
; a column called "name"
;
; An instance's name is not a slot, so a "name" column goes to "_name", the
; same default sqlite-row-to-instance has.  A class with no _name slot drops
; the column like any other column with nowhere to go.
; ------------------------------------------------------------

(bind ?*wm-r* (sqlite-query-to-instances ?*wm-db*
  "SELECT 'from the row' AS name, 7 AS v;" WM_NAMED))
(expect "a name column is made" 1 (length$ ?*wm-r*))
(expect "and lands in the _name slot" "from the row" (send (nth$ 1 ?*wm-r*) get-_name))
(expect "while the other columns are unaffected" 7 (send (nth$ 1 ?*wm-r*) get-v))
(expect "and the instance's own name is untouched by it" FALSE
        (eq (str-cat (instance-name (nth$ 1 ?*wm-r*))) "from the row"))

(bind ?*wm-r* (sqlite-query-to-instances ?*wm-db*
  "SELECT 'from the row' AS name, 7 AS id;" WM_ORDERS))
(expect "a class with no _name slot still gets its instance" 1 (length$ ?*wm-r*))
(expect "with the name column dropped" 7 (send (nth$ 1 ?*wm-r*) get-id))

; ------------------------------------------------------------
; the multifield form
;
; One flat multifield of the values, row by row.  The column names are
; opt-in: values alone is the shape a caller indexes arithmetically, and
; prepending names would silently shift every one of those indices.
; ------------------------------------------------------------

(bind ?*wm-m* (sqlite-query-to-multifield ?*wm-db*
  "SELECT id, product, amount FROM wm_orders ORDER BY id;"))
(expect "three rows of three, and no names" 9 (length$ ?*wm-m*))
(expect "the first field is the first value" 1 (nth$ 1 ?*wm-m*))
(expect "in column order" "widget" (nth$ 2 ?*wm-m*))
(expect "and the row after it follows" 2 (nth$ 4 ?*wm-m*))
(expect "a NULL cell is nil here too" nil (nth$ 8 ?*wm-m*))

; FALSE is the default spelled out
(bind ?*wm-m* (sqlite-query-to-multifield ?*wm-db*
  "SELECT id, product, amount FROM wm_orders ORDER BY id;" FALSE))
(expect "FALSE is what leaving it out means" 9 (length$ ?*wm-m*))
(expect "with the values in the same places" 1 (nth$ 1 ?*wm-m*))

; TRUE puts the column names in front of them
(bind ?*wm-m* (sqlite-query-to-multifield ?*wm-db*
  "SELECT id, product, amount FROM wm_orders ORDER BY id;" TRUE))
(expect "TRUE adds one field per column in front" 12 (length$ ?*wm-m*))
(expect "the first fields are the column names" "id" (nth$ 1 ?*wm-m*))
(expect "in column order" "product" (nth$ 2 ?*wm-m*))
(expect "all of them" "amount" (nth$ 3 ?*wm-m*))
(expect "then the first row's values" 1 (nth$ 4 ?*wm-m*))
(expect "shifted by exactly the column count" "widget" (nth$ 5 ?*wm-m*))

; a flag that is neither TRUE nor FALSE is refused rather than read as truthy
(defglobal ?*wm-maybe* = maybe)
(bind ?*wm-r* (sqlite-query-to-multifield ?*wm-db* "SELECT id FROM wm_orders;" ?*wm-maybe*))
(expect "a non-boolean headers flag refuses" FALSE ?*wm-r*)

; a query answering no rows answers nothing at all, or its header alone
(bind ?*wm-m* (sqlite-query-to-multifield ?*wm-db* "SELECT id FROM wm_orders WHERE 0;"))
(expect "an empty result is empty" 0 (length$ ?*wm-m*))
(bind ?*wm-m* (sqlite-query-to-multifield ?*wm-db* "SELECT id FROM wm_orders WHERE 0;" TRUE))
(expect "and headed by its column name when asked" (create$ "id") ?*wm-m*)

; a BLOB comes through as a string, as it does from sqlite-column
(bind ?*wm-m* (sqlite-query-to-multifield ?*wm-db* "SELECT x'414243' AS b;"))
(expect "a BLOB is a string" (create$ "ABC") ?*wm-m*)

; ------------------------------------------------------------
; the statement-taking half
;
; A prepared statement carries its own bindings, which is what the query
; form cannot offer: the SQL there is a string and nothing else.  So a
; parameterised query is prepared, bound, and handed over whole.
; ------------------------------------------------------------

(bind ?*wm-st* (sqlite-prepare ?*wm-db* "SELECT id, product, amount FROM wm_orders WHERE id > ? ORDER BY id;"))
(expect "the statement prepared" TRUE (pointerp ?*wm-st*))
(expect "and takes a binding" TRUE (sqlite-bind ?*wm-st* 1 1))

(bind ?*wm-r* (sqlite-stmt-to-facts ?*wm-st* wm_orders))
(expect "a statement converts the rows its binding selects" 2 (length$ ?*wm-r*))
(expect "starting at the first of them" 2 (fact-slot-value (nth$ 1 ?*wm-r*) id))

; the walk stepped the statement to SQLITE_DONE and reset it on the way out,
; so the same statement converts again, with the same binding, rather than
; answering nothing
(bind ?*wm-r* (sqlite-stmt-to-facts ?*wm-st* wm_orders))
(expect "a walked statement runs again" 2 (length$ ?*wm-r*))

; and, being reset, takes a fresh binding -- which a statement merely stepped
; to completion would refuse until someone reset it
(expect "rebinding" TRUE (sqlite-bind ?*wm-st* 1 0))
(bind ?*wm-r* (sqlite-stmt-to-instances ?*wm-st* WM_ORDERS))
(expect "a statement converts to instances" 3 (length$ ?*wm-r*))
(expect "under the new binding" 1 (send (nth$ 1 ?*wm-r*) get-id))

; the same name argument, in the same shape
(bind ?*wm-r* (sqlite-stmt-to-instances ?*wm-st* WM_ORDERS (create$ WM-N-R1 WM-N-R2)))
(expect "a statement names its rows the same way" 3 (length$ ?*wm-r*))
(expect "from the same positional list" [WM-N-R1] (instance-name (nth$ 1 ?*wm-r*)))
(expect "and runs off the end the same way" [WM-N-R2] (instance-name (nth$ 2 ?*wm-r*)))
(bind ?*wm-r* (sqlite-stmt-to-instances ?*wm-st* WM_ORDERS WM-N-R-ONE))
(expect "or one name for the first row" [WM-N-R-ONE] (instance-name (nth$ 1 ?*wm-r*)))

(bind ?*wm-r* (sqlite-stmt-to-multifield ?*wm-st* TRUE))
(expect "a statement converts to a multifield" 12 (length$ ?*wm-r*))
(expect "and takes the headers flag too" "id" (nth$ 1 ?*wm-r*))

; The row under the cursor is not skipped.  A caller who stepped once, to
; look at the first row, and then hands the statement over gets that row
; and the rest -- not the rest alone.
(expect "stepping to the first row" SQLITE_ROW (sqlite-step ?*wm-st*))
(expect "which is row 1" 1 (sqlite-column ?*wm-st* 0))
(bind ?*wm-r* (sqlite-stmt-to-multifield ?*wm-st*))
(expect "the row under the cursor is the first converted" 1 (nth$ 1 ?*wm-r*))
(expect "and the rest follow it" 9 (length$ ?*wm-r*))

; the statement-taking half has no query to read a table name from, so the
; construct is not optional there: this is checked by the restriction string
; at parse time and needs no run-time guard of its own

(expect "finalizing it" TRUE (sqlite-finalize ?*wm-st*))

; a statement with no columns walks to done and answers nothing
(bind ?*wm-st* (sqlite-prepare ?*wm-db* "CREATE TABLE wm_scratch(a);"))
(bind ?*wm-r* (sqlite-stmt-to-multifield ?*wm-st* TRUE))
(expect "a statement with no columns answers an empty multifield" 0 (length$ ?*wm-r*))
(bind ?*wm-r* (sqlite-query-to-multifield ?*wm-db* "SELECT count(*) FROM wm_scratch;"))
(expect "and was run" (create$ 0) ?*wm-r*)
(expect "finalizing it" TRUE (sqlite-finalize ?*wm-st*))

; ------------------------------------------------------------
; refusals
;
; Nothing is put into working memory by a refused call: the construct and
; the names are checked before the first row is read.
; ------------------------------------------------------------

; a query with no column from a table has no name to infer
(bind ?*wm-r* (sqlite-query-to-facts ?*wm-db* "SELECT 42 AS id;"))
(expect "a query over no table cannot infer a name" FALSE ?*wm-r*)

; nor has one whose columns come from two
(bind ?*wm-r* (sqlite-query-to-facts ?*wm-db*
  "SELECT a.id, b.id AS other FROM wm_orders a JOIN wm_plain b ON a.id = b.id;"))
(expect "columns from two tables cannot either" FALSE ?*wm-r*)

; a named construct that does not exist
(bind ?*wm-r* (sqlite-query-to-facts ?*wm-db* "SELECT id FROM wm_orders;" wm_nosuch))
(expect "an absent deftemplate refuses" FALSE ?*wm-r*)
(bind ?*wm-r* (sqlite-query-to-instances ?*wm-db* "SELECT id FROM wm_orders;" WM_NOSUCH))
(expect "an absent defclass refuses" FALSE ?*wm-r*)

; an ordered fact's template has no named slots to put columns in
(assert (wm_ordered 1 2 3))
(bind ?*wm-r* (sqlite-query-to-facts ?*wm-db* "SELECT id FROM wm_orders;" wm_ordered))
(expect "the implied template of an ordered fact refuses" FALSE ?*wm-r*)

; an inferred name with no construct behind it, which is the shape a caller
; hits when they lean on inference
(bind ?*wm-r* (sqlite-query-to-facts ?*wm-db* "SELECT id FROM wm_plain;"))
(expect "an inferred name with no deftemplate refuses" FALSE ?*wm-r*)
(bind ?*wm-r* (sqlite-query-to-instances ?*wm-db* "SELECT id FROM wm_plain;"))
(expect "and one with no defclass refuses" FALSE ?*wm-r*)

; a query that will not prepare fails with SQLite's own message
(bind ?*wm-r* (sqlite-query-to-facts ?*wm-db* "SELECT nonsense FROM"))
(expect "a query that will not parse refuses" FALSE ?*wm-r*)
(bind ?*wm-r* (sqlite-query-to-multifield ?*wm-db* "SELECT id FROM wm_nosuch_table;"))
(expect "and so does one over a table that is not there" FALSE ?*wm-r*)

; the query form runs one statement.  sqlite3_prepare compiles the first and
; hands back the rest, and a second statement dropped on the floor would be
; worse than a refusal.  Whitespace and a comment after the first are not a
; second statement.
(bind ?*wm-r* (sqlite-query-to-multifield ?*wm-db* "SELECT id FROM wm_orders; SELECT 1;"))
(expect "two statements in one query refuse" FALSE ?*wm-r*)
(bind ?*wm-r* (sqlite-query-to-multifield ?*wm-db* "SELECT id FROM wm_orders ORDER BY id;  -- one\n"))
(expect "a trailing comment is not a second statement" 3 (length$ ?*wm-r*))
(bind ?*wm-r* (sqlite-query-to-multifield ?*wm-db* "   "))
(expect "and a query with no statement in it refuses" FALSE ?*wm-r*)

; ------------------------------------------------------------
; a column with no slot to land in
;
; Passed over, not refused: the query decides what it selects and the
; deftemplate decides what it holds, and neither has to be a subset of the
; other.  Which columns are skipped is decided once, before the first row.
; ------------------------------------------------------------

(bind ?*wm-r* (sqlite-query-to-facts ?*wm-db*
  "SELECT id, product, amount FROM wm_orders ORDER BY id;" wm_partial))
(expect "the rows still land when a column has no slot" 3 (length$ ?*wm-r*))
(expect "the column that does have one carries its value" 1
        (fact-slot-value (nth$ 1 ?*wm-r*) id))
(expect "and the last row's too" 3 (fact-slot-value (nth$ 3 ?*wm-r*) id))

(bind ?*wm-r* (sqlite-query-to-instances ?*wm-db*
  "SELECT id, product, amount FROM wm_orders ORDER BY id;" WM_PARTIAL))
(expect "instances skip an unmatched column too" 3 (length$ ?*wm-r*))
(expect "keeping the slot they do have" 2 (send (nth$ 2 ?*wm-r*) get-id))

; when NO column matches, every row builds the same empty fact and CLIPS
; collapses the duplicates -- the answer stays row-aligned, working memory
; gains one fact.  This is the corner the skip rule implies; it is here so
; that it is a decision on the record rather than a surprise.
(bind ?*wm-r* (sqlite-query-to-facts ?*wm-db* "SELECT id, product FROM wm_orders;" wm_unrelated))
(expect "no column matching still answers one entry per row" 3 (length$ ?*wm-r*))
(expect "but the empty facts are all the same one" 1
        (length$ (find-all-facts ((?f wm_unrelated)) TRUE)))

; ------------------------------------------------------------
; a constraint the row does not satisfy
;
; The slot exists -- that was checked before any row was read -- so this is
; the value.  Such a row is skipped rather than asserted half-filled, and the
; answer is the record of what was made.
; ------------------------------------------------------------

(bind ?*wm-r* (sqlite-query-to-multifield ?*wm-db*
  "CREATE TABLE wm_strict(id INTEGER, label TEXT);"))
(expect "a table the strict template disagrees with" (create$) ?*wm-r*)
(bind ?*wm-r* (sqlite-query-to-multifield ?*wm-db*
  "INSERT INTO wm_strict VALUES (1,'ok'),(2,'also');"))
(expect "filled" (create$) ?*wm-r*)

(bind ?*wm-r* (sqlite-query-to-facts ?*wm-db* "SELECT id, label FROM wm_strict;" wm_strict))
(expect "a row whose value the slot refuses is skipped" 0 (length$ ?*wm-r*))
(expect "leaving no half-filled fact behind" 0
        (length$ (find-all-facts ((?f wm_strict)) TRUE)))

; A refused row must not take the rows around it with it, nor leave anything
; of itself in the next one: the builder is cleared and kept, which is what
; lets one builder serve the whole statement.
(bind ?*wm-r* (sqlite-query-to-multifield ?*wm-db* "CREATE TABLE wm_ranged(id INTEGER);"))
(expect "a table with one row outside the range" (create$) ?*wm-r*)
(bind ?*wm-r* (sqlite-query-to-multifield ?*wm-db* "INSERT INTO wm_ranged VALUES (5),(500),(7);"))
(expect "filled" (create$) ?*wm-r*)

(bind ?*wm-r* (sqlite-query-to-facts ?*wm-db* "SELECT id FROM wm_ranged ORDER BY id;" wm_ranged))
(expect "the rows either side of a refused one still land" 2 (length$ ?*wm-r*))
(expect "the first of them keeps its own value" 5 (fact-slot-value (nth$ 1 ?*wm-r*) id))
(expect "and so does the one after the refusal" 7 (fact-slot-value (nth$ 2 ?*wm-r*) id))
(expect "and nothing else was asserted" 2 (length$ (find-all-facts ((?f wm_ranged)) TRUE)))

; the same for instances
(bind ?*wm-r* (sqlite-query-to-instances ?*wm-db* "SELECT id FROM wm_ranged ORDER BY id;" WM_RANGED))
(expect "an instance builder survives a refused row too" 2 (length$ ?*wm-r*))
(expect "with the row after it intact" 7 (send (nth$ 2 ?*wm-r*) get-id))

; A row can also be lost at the build itself rather than at a slot: an
; abstract class cannot be instantiated at all, so every row loses.  CLIPS
; writes its own [INSMNGR3] reason alongside, once per row, and the halt it
; raises is undone so the call -- and the suite -- carries on.
(bind ?*wm-r* (sqlite-query-to-instances ?*wm-db* "SELECT id FROM wm_ranged;" WM_ABSTRACT))
(expect "an abstract class makes no instance for any row" 0 (length$ ?*wm-r*))
(expect "leaving nothing behind" 0 (length$ (find-all-instances ((?i WM_ABSTRACT)) TRUE)))

; ------------------------------------------------------------
; a statement that fails part-way through
;
; A step can fail on a row rather than at the prepare -- an expression that
; overflows on one row and not the one before it.  The walk stops there and
; answers what it made up to that row, and the statement is left as it was
; found rather than reset, so sqlite-reset can still say what went wrong.
; ------------------------------------------------------------

(bind ?*wm-r* (sqlite-query-to-multifield ?*wm-db*
  "SELECT 1 AS id UNION ALL SELECT abs(-9223372036854775808);"))
(expect "the rows before the failure are answered" (create$ 1) ?*wm-r*)
(expect "and the connection says why it stopped" "integer overflow" (sqlite-errmsg ?*wm-db*))

(bind ?*wm-st* (sqlite-prepare ?*wm-db*
  "SELECT 1 AS id UNION ALL SELECT abs(-9223372036854775808);"))
(bind ?*wm-r* (sqlite-stmt-to-facts ?*wm-st* wm_partial))
(expect "the statement form stops at the same row" 1 (length$ ?*wm-r*))
(expect "holding the one before it" 1 (fact-slot-value (nth$ 1 ?*wm-r*) id))
(bind ?*wm-r* (sqlite-reset ?*wm-st*))
(expect "and leaves the statement for reset to report on" FALSE ?*wm-r*)
(expect "finalizing it" TRUE (sqlite-finalize ?*wm-st*))

; ------------------------------------------------------------
; rows lost to the rule network
;
; CLIPS will not assert while it is pattern matching, and a test CE runs
; while it is pattern matching.  Every row is refused at the assert, one
; line on stderr says so, and the answer is empty -- but it is an answer, so
; the test CE holds and the rule fires on it.  The fact form is the one
; that can lose a row this way; a row a slot refused never reaches the
; assert.  The answer is kept by a deffunction for the reason the
; row-mapping suite gives.
; ------------------------------------------------------------

(defglobal ?*wm-fired* = FALSE)
(deffunction wm-record (?v)
  (bind ?*wm-r* ?v))

(defrule wm-facts-while-matching
  (wm-trigger)
  (test (wm-record (sqlite-query-to-facts ?*wm-db* "SELECT id FROM wm_ranged;" wm_ranged)))
  =>
  (bind ?*wm-fired* TRUE))

(bind ?*wm-r* nothing)
(assert (wm-trigger))
(run)
(expect "no row can be asserted from inside a test CE" (create$) ?*wm-r*)
(expect "though the call answered, so the rule fired" TRUE ?*wm-fired*)
(expect "and working memory is as it was" 2 (length$ (find-all-facts ((?f wm_ranged)) TRUE)))

; ------------------------------------------------------------
; cleanup
; ------------------------------------------------------------

(expect "closing the connection" TRUE (sqlite-close ?*wm-db*))
