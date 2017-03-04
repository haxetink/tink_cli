# Mockup Command Line Tool for the Haxe Complier

### Basic
`./haxe.sh -js bin/run.js -main Main`
```
js: bin/run.js
lib: null
main: Main
defines: null
help: null
helpDefines: null
rest: []
```

### Without main
`./haxe.sh -js bin/run.js Api`
```
js: bin/run.js
lib: null
main: null
defines: null
help: null
helpDefines: null
rest: [Api]
```

### With libaries and defines
`./haxe.sh -js bin/run.js -D release -D mobile -lib tink_core -lib tink_json -main Main`
```
js: bin/run.js
lib: [tink_core,tink_json]
main: Main
defines: [release,mobile]
help: null
helpDefines: null
rest: []
```

### Flags
`./haxe.sh --help`
```
js: null
lib: null
main: null
defines: null
help: true
helpDefines: null
rest: []
```
`./haxe.sh --help-defines`
```
js: null
lib: null
main: null
defines: null
help: null
helpDefines: true
rest: []
```