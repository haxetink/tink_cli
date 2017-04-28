# Quick Start

## Install

### With Haxelib

`haxelib install tink_cli`

### With Lix

`lix install haxelib:tink_cli`

## Basic Command Line

```haxe
import tink.Cli;

class Tool {
	static function main() {
		Cli.process(Sys.args(), new Tool()).handle(Cli.exit);
	}
	
	public var verbose:Bool;
	
	public function new() {}
	
	@:defaultCommand
	public function hello(name:String) {
		var out = 'Hello, $name! ';
		if(verbose) out += Date.now().toString();
		Sys.println(out);
	}
}
```

1. Copy the code above and save it as `Tool.hx`
1. Build it with: `haxe -js tool.js -lib hxnodejs -lib tink_cli -main Tool`
1. Run the cli tool: `node tool.js Tink` (prints `Hello, Tink!`)
1. Run the cli tool with additional flags: `node tool.js -v Tink` (prints `Hello, Tink! <Current Time>`)