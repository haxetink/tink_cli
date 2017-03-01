package tink.cli;

class Router<T> {
	var command:T;
	public function new(command) {
		this.command = command;
	}
	
	public function process(args:Array<String>):ExitCode {
		return 0;
	}
}