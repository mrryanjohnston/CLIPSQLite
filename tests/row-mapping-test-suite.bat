; ============================================================
; MAPPING A ROW ONTO CLIPS
;
; Three wrappers turn the row under the cursor into something the rule engine
; can match: a multifield, an asserted fact, or a made instance.  All three
; read the same row through the same type mapping, so what separates them is
; how they are addressed -- a multifield by position, a fact and an instance
; by the row's column names.
;
; Name-addressing is the part with sharp edges.  A column the shape has no
; slot for is dropped without a word, a slot no column filled keeps its
; default, and for an instance a column called "name" cannot be a slot at all.
; ============================================================

(defglobal
  ?*rm-db* = FALSE
  ?*rm-st* = FALSE
  ?*rm-r*  = nothing
  ?*rm-f*  = FALSE
  ?*rm-i*  = FALSE)

(bind ?*rm-db* (sqlite-open :memory:))
(expect "the connection opened" TRUE (pointerp ?*rm-db*))

; ------------------------------------------------------------
; to a multifield
;
; Addressed by position, so it needs no template and drops nothing.  It is the
; only one of the three that carries a row whose column names would not be
; legal slot names.
; ------------------------------------------------------------

(bind ?*rm-st* (sqlite-prepare ?*rm-db*
  "SELECT 7 AS i, 2.5 AS f, 'text' AS t, x'414243' AS b, NULL AS n;"))
(expect "the query prepared" TRUE (pointerp ?*rm-st*))
(expect "stepping" SQLITE_ROW (sqlite-step ?*rm-st*))

(bind ?*rm-r* (sqlite-row-to-multifield ?*rm-st*))
(expect "the row becomes a multifield" MULTIFIELD (type ?*rm-r*))
(expect "with one field per column" 5 (length$ ?*rm-r*))
(expect "in column order, typed as CLIPS values"
        (create$ 7 2.5 "text" "ABC" nil) ?*rm-r*)
(expect "the integer stayed an integer" INTEGER (type (nth$ 1 ?*rm-r*)))
(expect "the real stayed a float" FLOAT (type (nth$ 2 ?*rm-r*)))
(expect "the text stayed a string" STRING (type (nth$ 3 ?*rm-r*)))
(expect "and the NULL is the symbol nil" SYMBOL (type (nth$ 5 ?*rm-r*)))

(expect "finalizing it" TRUE (sqlite-finalize ?*rm-st*))

; a statement with no columns maps to an empty multifield rather than refusing
(bind ?*rm-st* (sqlite-prepare ?*rm-db* "CREATE TABLE t (a, b, c);"))
(bind ?*rm-r* (sqlite-row-to-multifield ?*rm-st*))
(expect "a statement with no columns gives an empty multifield"
        0 (length$ ?*rm-r*))
(expect "running the CREATE" SQLITE_DONE (sqlite-step ?*rm-st*))
(expect "finalizing it" TRUE (sqlite-finalize ?*rm-st*))

; ------------------------------------------------------------
; to a fact
; ------------------------------------------------------------

(bind ?*rm-st* (sqlite-prepare ?*rm-db* "SELECT 1 AS a, 2.5 AS b, 'three' AS c;"))
(expect "stepping" SQLITE_ROW (sqlite-step ?*rm-st*))

(bind ?*rm-f* (sqlite-row-to-fact ?*rm-st* row-abc))
(expect "the row is asserted as a fact" FACT-ADDRESS (type ?*rm-f*))
(expect "with the column values in the slots the columns named"
        1 (fact-slot-value ?*rm-f* a))
(expect "each keeping its type" 2.5 (fact-slot-value ?*rm-f* b))
(expect "including the text" "three" (fact-slot-value ?*rm-f* c))
(expect "and the fact is in the fact base" TRUE (fact-existp ?*rm-f*))

(bind ?*rm-r* (sqlite-row-to-fact ?*rm-st* not-a-deftemplate))
(expect "a template that does not exist is refused" FALSE ?*rm-r*)

; an ordered fact's template has no named slots to put columns in
(assert (rm-ordered 1 2 3))
(bind ?*rm-r* (sqlite-row-to-fact ?*rm-st* rm-ordered))
(expect "and so is the implied template of an ordered fact" FALSE ?*rm-r*)

(expect "finalizing it" TRUE (sqlite-finalize ?*rm-st*))

; ------------------------------------------------------------
; columns and slots that do not line up
;
; Neither direction is an error: a column with no slot is dropped and a slot
; with no column keeps its default.  A caller who misspells a column name
; therefore gets a fact, not a failure, which is worth knowing before relying
; on one.
; ------------------------------------------------------------

(bind ?*rm-st* (sqlite-prepare ?*rm-db* "SELECT 1 AS a, 2 AS b, 3 AS c, 4 AS unmatched;"))
(expect "stepping" SQLITE_ROW (sqlite-step ?*rm-st*))
(bind ?*rm-f* (sqlite-row-to-fact ?*rm-st* row-abc))
(expect "a column the template has no slot for does not stop the assert"
        FACT-ADDRESS (type ?*rm-f*))
(expect "the slots that did match are filled" 1 (fact-slot-value ?*rm-f* a))
(expect "and the extra column is simply gone"
        FALSE (member$ unmatched (fact-slot-names ?*rm-f*)))
(expect "finalizing it" TRUE (sqlite-finalize ?*rm-st*))

(bind ?*rm-st* (sqlite-prepare ?*rm-db* "SELECT 1 AS a;"))
(expect "stepping" SQLITE_ROW (sqlite-step ?*rm-st*))
(bind ?*rm-f* (sqlite-row-to-fact ?*rm-st* row-abc))
(expect "a template slot no column filled is left at its default"
        nil (fact-slot-value ?*rm-f* b))
(expect "while the one that was filled holds its value" 1 (fact-slot-value ?*rm-f* a))
(expect "finalizing it" TRUE (sqlite-finalize ?*rm-st*))

; ------------------------------------------------------------
; before the first step there is no row, only a shape
;
; sqlite3_column_type answers SQLITE_NULL for every column of a statement that
; has not been stepped, so mapping one produces a fact of nothing but nils
; rather than a refusal.  This is the shape of the bug a caller writes when
; they forget the step, and it is silent.
; ------------------------------------------------------------

(bind ?*rm-st* (sqlite-prepare ?*rm-db* "SELECT 1 AS a, 2 AS b, 3 AS c;"))
(bind ?*rm-f* (sqlite-row-to-fact ?*rm-st* row-abc))
(expect "mapping an unstepped statement still asserts a fact"
        FACT-ADDRESS (type ?*rm-f*))
(expect "whose slots are all nil" nil (fact-slot-value ?*rm-f* a))
(expect "every one of them" nil (fact-slot-value ?*rm-f* c))
(expect "finalizing it" TRUE (sqlite-finalize ?*rm-st*))

; ------------------------------------------------------------
; to an instance
; ------------------------------------------------------------

(bind ?*rm-st* (sqlite-prepare ?*rm-db* "SELECT 1 AS a, 2.5 AS b, 'three' AS c;"))
(expect "stepping" SQLITE_ROW (sqlite-step ?*rm-st*))

(bind ?*rm-i* (sqlite-row-to-instance ?*rm-st* ROW-ABC))
(expect "the row is made into an instance" TRUE (instance-addressp ?*rm-i*))
(expect "of the class it was asked for" ROW-ABC (class ?*rm-i*))
(expect "with the column values in the slots the columns named"
        1 (send ?*rm-i* get-a))
(expect "each keeping its type" 2.5 (send ?*rm-i* get-b))
(expect "including the text" "three" (send ?*rm-i* get-c))

(bind ?*rm-r* (sqlite-row-to-instance ?*rm-st* NOT-A-DEFCLASS))
(expect "a class that does not exist is refused" FALSE ?*rm-r*)

; An abstract class passes the builder and fails at IBMake, which is a
; different path from the one above: the class was found, and COOL refused to
; construct it.  The wrapper used to read the *fact* builder's status to decide
; what had gone wrong, so when that happened to say "no error" it broke out of
; the error handling and returned the NULL as an instance address.
(bind ?*rm-r* (sqlite-row-to-instance ?*rm-st* USER))
(expect "an instance of an abstract class is refused" FALSE ?*rm-r*)

; and the refusal leaves the wrapper working, rather than the environment
(bind ?*rm-r* (sqlite-row-to-instance ?*rm-st* ROW-ABC))
(expect "the next call still makes an instance" TRUE (instance-addressp ?*rm-r*))

; the name may be given, and giving the same one twice replaces the instance
(bind ?*rm-i* (sqlite-row-to-instance ?*rm-st* ROW-ABC rm-named))
(expect "an instance may be given a name" [rm-named] (instance-name ?*rm-i*))
(bind ?*rm-i* (sqlite-row-to-instance ?*rm-st* ROW-ABC rm-named))
(expect "and making it again under that name replaces it"
        [rm-named] (instance-name ?*rm-i*))
(expect "leaving one instance under the name" 1
        (length$ (find-all-instances ((?x ROW-ABC)) (eq (instance-name ?x) [rm-named]))))

; nil in that position means "no name", the same as leaving it out
(bind ?*rm-i* (sqlite-row-to-instance ?*rm-st* ROW-ABC nil))
(expect "nil asks for a generated name" TRUE (instance-addressp ?*rm-i*))
(expect "not the literal name nil" FALSE (eq [nil] (instance-name ?*rm-i*)))

(expect "finalizing it" TRUE (sqlite-finalize ?*rm-st*))

; ------------------------------------------------------------
; a column called "name"
;
; An instance's name is not one of its slots, so a column called "name" cannot
; be written where its name says.  It goes to "_name" instead, or to whatever
; slot the fourth argument names -- and the fourth argument is only reachable
; by passing something in the third, which is what nil is for.
; ------------------------------------------------------------

(bind ?*rm-st* (sqlite-prepare ?*rm-db* "SELECT 'from the row' AS name, 7 AS v;"))
(expect "stepping" SQLITE_ROW (sqlite-step ?*rm-st*))

(bind ?*rm-i* (sqlite-row-to-instance ?*rm-st* ROW-NAMED))
(expect "a name column is made" TRUE (instance-addressp ?*rm-i*))
(expect "and lands in the _name slot by default"
        "from the row" (send ?*rm-i* get-_name))
(expect "while the other columns are unaffected" 7 (send ?*rm-i* get-v))
(expect "and the instance's own name is untouched by it"
        FALSE (eq (str-cat (instance-name ?*rm-i*)) (send ?*rm-i* get-_name)))

(bind ?*rm-i* (sqlite-row-to-instance ?*rm-st* ROW-NAMED-ALT nil nm))
(expect "the fourth argument names the slot instead" TRUE (instance-addressp ?*rm-i*))
(expect "and the name column lands there" "from the row" (send ?*rm-i* get-nm))

(bind ?*rm-i* (sqlite-row-to-instance ?*rm-st* ROW-NAMED-ALT rm-both nm))
(expect "the instance name and the slot are set independently"
        [rm-both] (instance-name ?*rm-i*))
(expect "the column going to the named slot" "from the row" (send ?*rm-i* get-nm))

; naming a slot the class does not have drops the column, the same as any
; other column with nowhere to go -- the instance is still made
(bind ?*rm-i* (sqlite-row-to-instance ?*rm-st* ROW-NAMED nil no-such-slot))
(expect "a replacement slot the class lacks does not stop the instance"
        TRUE (instance-addressp ?*rm-i*))
(expect "the name column is simply dropped" nil (send ?*rm-i* get-_name))
(expect "while the other columns still arrive" 7 (send ?*rm-i* get-v))

(expect "finalizing it" TRUE (sqlite-finalize ?*rm-st*))
(expect "closing the connection" TRUE (sqlite-close ?*rm-db*))
