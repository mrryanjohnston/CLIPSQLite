# Examples

Each of these is a program, not a snippet: `make test` runs every one of
them and checks what it printed against the `.expected` file beside it. An
example nobody runs is a claim nobody checks.

To run one by hand, with the binary the build produced:

```
./vendor/clips/clips -f2 examples/1-rules-over-sql.bat
```

Nothing here needs a server, a database file or a configuration of any
kind. The first two work in a `:memory:` database, which lives as long as
the connection; the third writes one file under `examples/tmp` and removes
it again on the way out. Run them from the top of the repository, which is
where those relative paths are resolved.

`make test-examples` runs only these. An example has to exit cleanly, write
nothing to `STDERR` -- everything in this library reports a refused call
there -- and print what its `.expected` file says it prints. A line there is
matched as a substring of some line of the output, which keeps the check on
what the example is demonstrating and away from what differs between
machines: a SQLite version, a page count, the order the agenda fired in.

| | |
| --- | --- |
| [1-rules-over-sql.bat](1-rules-over-sql.bat) | Rows become facts, and rules draw the conclusions |
| [2-prepared-statements.bat](2-prepared-statements.bat) | Placeholders, and why a value out of a fact needs one |
| [3-backup-to-disk.bat](3-backup-to-disk.bat) | Work done in memory, kept with the online backup API |
