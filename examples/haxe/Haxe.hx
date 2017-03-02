package;

import tink.cli.*;
import tink.Cli;

class Haxe {
	static function main() {
		Cli.process(Sys.args(), new Command()).handle(function(o) {});
	}
}

class Command {
	@:flag('-js')
	public var js:String;
	
	@:flag('-lib')
	public var lib:Array<String>;
	
	@:flag('-main')
	public var main:String;
	
	public function new() {}
	
	@:defaultCommand
	public function run(rest:Rest<String>) {
		Sys.println('js: $js');
		Sys.println('lib: $lib');
		Sys.println('main: $main');
		Sys.println('rest: $rest');
	}
}