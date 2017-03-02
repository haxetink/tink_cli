# Psuedo Command Line Tool for the Haxe Complier

#### Example 1 (with main class)
`./haxe.sh -lib tink_core -lib tink_cli -js bin/index.js -main Main`

prints:

```
js: bin/index.js
lib: [tink_core,tink_cli]
main: Main
rest: []
```

#### Example 2 (without main class)
`./haxe.sh -lib tink_core -lib tink_cli -js bin/index.js Main Util AnotherClass`

prints:

```
js: bin/index.js
lib: [tink_core,tink_cli]
main: null
rest: [Main,Util,AnotherClass]
```