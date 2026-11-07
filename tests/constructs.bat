; ------------------------------------------------------------
; Templates and classes the suites map result rows onto.
;
; sqlite-row-to-fact and sqlite-row-to-instance take the column names of the
; current row as slot names, so every template here is named after the query
; that fills it rather than after anything in SQLite.  A column the shape has
; no slot for is a hard failure inside the builder, which is why these are
; kept next to the queries instead of being reused loosely.
; ------------------------------------------------------------

; SELECT 1 AS a, 2.5 AS b, 'x' AS c
(deftemplate row-abc (slot a) (slot b) (slot c))
(defclass ROW-ABC (is-a USER) (role concrete) (slot a) (slot b) (slot c))

; every SQLite storage class in one row, so the type mapping is asserted
; against a single shape: integer, real, text, blob, null
(deftemplate row-types (slot i) (slot f) (slot t) (slot b) (slot n))
(defclass ROW-TYPES (is-a USER) (role concrete)
  (slot i) (slot f) (slot t) (slot b) (slot n))

; ------------------------------------------------------------
; "name" is not an ordinary column for sqlite-row-to-instance: an instance's
; name is not a slot, so a column called "name" is written to a differently
; named slot -- "_name" unless the caller names another one.  Both spellings
; get a class here so the default and the override can be told apart.
; ------------------------------------------------------------

; takes the default replacement
(defclass ROW-NAMED (is-a USER) (role concrete) (slot _name) (slot v))
; takes an explicit replacement passed as the fourth argument
(defclass ROW-NAMED-ALT (is-a USER) (role concrete) (slot nm) (slot v))

; ------------------------------------------------------------
; Bind sources.  sqlite-bind takes slot names as the named parameters of the
; statement, so these slots are spelled with SQLite's parameter prefixes.
; ------------------------------------------------------------

(deftemplate bind-params (slot :a) (slot :b))
(defclass BIND-PARAMS (is-a USER) (role concrete) (slot :a) (slot :b))

; a subclass, for the inherit flag: :a is inherited, :c is its own.  With
; inheritance on both are bound; with it off only :c is.
(defclass BIND-PARAMS-SUB (is-a BIND-PARAMS) (role concrete) (slot :c))

; @-prefixed parameters, to prove the prefix is not special-cased
(deftemplate bind-at-params (slot @a) (slot @b))

; a template whose slots match nothing in the statement: every slot is skipped
; and the bind still succeeds
(deftemplate bind-unrelated (slot nothing-matches) (slot neither-does-this))

; a template whose slots can hold what has no SQL equivalent -- a multislot,
; an address -- or a nil: each is bound as NULL rather than refused
(deftemplate bind-typed (slot :a) (slot :b) (multislot :c))

; ------------------------------------------------------------
; Shapes for the whole-statement wrappers, sqlite-stmt-to-facts and the five
; beside it.  The query-taking forms infer the deftemplate from the table the
; result's columns come from, and the defclass as that name uppercased, so
; wm_orders and WM_ORDERS are spelled after the table the suite creates.
; ------------------------------------------------------------

(deftemplate wm_orders (slot id) (slot product) (slot amount))
(defclass WM_ORDERS (is-a USER) (role concrete)
  (slot id) (slot product) (slot amount))

; a slot for one column of the query and none for the rest
(deftemplate wm_partial (slot id))
(defclass WM_PARTIAL (is-a USER) (role concrete) (slot id))

; no slot for any column of the query
(deftemplate wm_unrelated (slot nothing))

; constraints some rows satisfy and some do not
(deftemplate wm_ranged (slot id (type INTEGER) (range 0 10)))
(defclass WM_RANGED (is-a USER) (role concrete)
  (slot id (type INTEGER) (range 0 10)))
(deftemplate wm_strict (slot id (type INTEGER)) (slot label (type SYMBOL)))

; a class no instance can be made of, and one that holds a name
(defclass WM_ABSTRACT (is-a USER) (role abstract) (slot id))
(defclass WM_NAME_HOLDER (is-a USER) (role concrete) (slot id))

; a "name" column lands in _name, as it does for sqlite-row-to-instance
(defclass WM_NAMED (is-a USER) (role concrete) (slot _name) (slot v))
