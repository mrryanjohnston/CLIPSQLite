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
