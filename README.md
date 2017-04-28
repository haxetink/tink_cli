# Tinkerbell Command Line

Write command line tools with ~~ease~~ Haxe.

## Quick Overview

To illustrate the usage, let's look at the follow quick mock-up of the Haxe command line.

```haxe
static function main() {
	Cli.process(Sys.args(), new MockupHaxe()).handle(Cli.exit);
}

@:alias(false)
class MockupHaxe {
	@:flag('-js')
	public var js:String;
	
	@:flag('-lib')
	public var lib:Array<String>;
	
	@:flag('-main')
	public var main:String;
	
	@:flag('-D')
	public var defines:Array<String>;
	
	public var help:Bool;
	
	@:flag('help-defines') 
	public var helpDefines:Bool;
	
	public function new() {}
	
	@:defaultCommand
	public function run(rest:Rest<String>) {
		Sys.println('js: $js');
		Sys.println('lib: $lib');
		Sys.println('main: $main');
		Sys.println('defines: $defines');
		Sys.println('help: $help');
		Sys.println('helpDefines: $helpDefines');
		Sys.println('rest: $rest');
	}
}
```

And then run with:

`./mockuphaxe -js bin/run.js -D release -D mobile -lib tink_core -lib tink_json Main`

Gives you:

```
js: bin/run.js
lib: [tink_core,tink_json]
main: null
defines: [release,mobile]
help: null
helpDefines: null
rest: [Main]
```

or: 
`./mockuphaxe --help-defines`

```
js: null
lib: null
main: null
defines: null
help: null
helpDefines: true
rest: []
```

Check out the [examples](https://github.com/haxetink/tink_cli/tree/master/examples) folder for the complete code.