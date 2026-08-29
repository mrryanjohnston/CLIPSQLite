; ======================================================================
; Placeholders, and why a value out of a fact needs one.
;
; A prepared statement is SQL with holes in it.  The holes are filled in
; afterwards, by value, so a name with an apostrophe in it is a name and
; not a syntax error -- and a statement prepared once can be filled in
; again and again, which is what makes it the right way to write a lot of
; rows.
;
; CLIPSQLite will fill the holes from a fact or an instance directly, if
; its slots are named after the statement's parameters.  Rules produce
; facts; this is how a fact becomes a row.
;
;   ./vendor/clips/clips -f2 examples/2-prepared-statements.bat
; ======================================================================

; SQLite spells a named parameter with a leading :, @ or $, and the name a
; slot has to have here is the whole parameter including that prefix.  It
; looks odd in a deftemplate and it is what makes the binding automatic.
(deftemplate shipment
  (slot :ref)
  (slot :customer)
  (slot :qty))

(deffunction run-sql (?db ?sql)
  (bind ?stmt (sqlite-prepare ?db ?sql))
  (if (not ?stmt)
   then
     (println "cannot prepare: " (sqlite-errmsg ?db))
     (return FALSE))
  (sqlite-step ?stmt)
  (sqlite-finalize ?stmt))

(deffunction main ()
  (bind ?db (sqlite-open :memory:))
  (if (not ?db) then (println "cannot open the database") (return FALSE))

  (run-sql ?db (str-cat "CREATE TABLE shipment ("
                        "ref TEXT PRIMARY KEY, "
                        "customer TEXT, "
                        "qty INTEGER)"))

  ; --------------------------------------------------------------------
  ; One statement, filled in from each fact in turn.
  ;
  ; sqlite-reset puts a stepped statement back to the start so it can be
  ; filled in again.  Without it the second step would answer SQLITE_DONE
  ; and write nothing.  The bindings survive a reset, which is why every
  ; parameter is written on every pass.
  ; --------------------------------------------------------------------

  (assert (shipment (:ref "S-1") (:customer "Kowalski") (:qty 12)))
  (assert (shipment (:ref "S-2") (:customer "O'Hare & Sons") (:qty 3)))
  (assert (shipment (:ref "S-3") (:customer "Okonkwo") (:qty 40)))

  (bind ?insert (sqlite-prepare ?db
    "INSERT INTO shipment (ref, customer, qty) VALUES (:ref, :customer, :qty)"))

  (println "the statement has "
           (sqlite-bind-parameter-count ?insert) " parameters: "
           (sqlite-bind-parameter-name ?insert 1) " "
           (sqlite-bind-parameter-name ?insert 2) " "
           (sqlite-bind-parameter-name ?insert 3))
  (println)

  ; The fact goes in whole: each slot fills the parameter it is named
  ; after.  Nobody quotes anything, so "O'Hare & Sons" is a customer and
  ; not a broken statement.
  (do-for-all-facts ((?s shipment)) TRUE
    (sqlite-bind ?insert ?s)
    (sqlite-step ?insert)
    (sqlite-reset ?insert))

  (sqlite-finalize ?insert)
  (println "wrote " (sqlite-total-changes ?db) " rows")

  ; --------------------------------------------------------------------
  ; Reading them back, through a positional placeholder.
  ;
  ; A ? is filled in by position: argument 2 is which one, argument 3 is
  ; the value.  sqlite-expanded-sql shows the statement with the values
  ; written into it -- which is what a placeholder saves the caller from
  ; having to build by hand, and is worth looking at exactly once, here.
  ; --------------------------------------------------------------------

  (bind ?query (sqlite-prepare ?db
    "SELECT ref, customer, qty FROM shipment WHERE qty >= ? ORDER BY ref"))
  (sqlite-bind ?query 1 10)

  (println)
  (println "sent: " (sqlite-expanded-sql ?query))
  (println)

  (while (eq (sqlite-step ?query) SQLITE_ROW)
    (bind ?row (sqlite-row-to-multifield ?query))
    (println "  " (nth$ 1 ?row) "  " (nth$ 2 ?row) "  " (nth$ 3 ?row)))

  (sqlite-finalize ?query)

  ; --------------------------------------------------------------------
  ; The same statement, a different value.
  ;
  ; sqlite-clear-bindings throws away what was bound; without it a
  ; parameter nobody rebinds keeps the value it had, which is the bug this
  ; call exists to prevent.
  ; --------------------------------------------------------------------

  (bind ?one (sqlite-prepare ?db "SELECT customer FROM shipment WHERE ref = ?"))

  (println)
  (foreach ?ref (create$ "S-2" "S-3")
    (sqlite-clear-bindings ?one)
    (sqlite-bind ?one 1 ?ref)
    (sqlite-step ?one)
    (println ?ref " belongs to " (sqlite-column ?one 0))
    (sqlite-reset ?one))

  (sqlite-finalize ?one)
  (sqlite-close ?db))

(main)
(exit)
