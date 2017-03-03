package;

import tink.cli.*;
import tink.Cli;

class Example {
	static function main() {
		Cli.process(Sys.args(), new Command()).handle(function(o) {});
	}
}

class Command {
	@:command
	public var sub = new SubCommand();
	
	public function new() {}
	
	@:defaultCommand
	public function run(rest:Rest<String>) {
		Sys.println('main $rest');
	}
}

class SubCommand {
	public function new() {}
	
	@:defaultCommand
	public function run(rest:Rest<String>) {
		Sys.println('sub $rest');
	}
}