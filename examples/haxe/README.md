# Psuedo Command Line Tool for the Haxe Complier

**Note:** Syntax is slightly different than the real one. Note that non-alias flags requires double dash `--`.

#### Example 1 (with main class)
`./haxe.sh --lib tink_core --js bin/index.js --main Main`

prints:

```
js: bin/index.js
lib: [tink_core]
main: Main
rest: []
```

#### Example 2 (without main class)
`./haxe.sh --lib tink_core --js bin/index.js Main`

prints:

```
js: bin/index.js
lib: [tink_core]
main: null
rest: [Main]
```