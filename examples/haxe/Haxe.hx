package;

import tink.cli.*;
import tink.Cli;

class Haxe {
	static function main() {
		Cli.process(Sys.args(), new Command()).handle(Cli.exit);
	}
}

@:alias(false)
class Command {
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