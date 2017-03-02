package;

import tink.Cli;

class Haxe {
	static function main() {
		Cli.process(Sys.args(), new Command()).handle(function(o) {});
	}
}

class Command {
	public var js:String;
	public var lib:Array<String>;
	public var main:String;
	
	public function new() {}
	
	@:defaultCommand
	public function run(rest:Array<String>) {
		trace('js: $js');
		trace('lib: $lib');
		trace('main: $main');
		trace('rest: $rest');
	}
}