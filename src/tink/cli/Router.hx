package tink.cli;

using tink.CoreApi;

class Router<T> {
	var command:T;
	var prompt:Prompt;
	
	public function new(command, prompt) {
		this.command = command;
		this.prompt = prompt;
	}
	
	public function process(args:Array<String>):ExitCode {
		return Noise;
	}
	
	function processArgs(args:Array<String>):Outcome<Array<String>, Error> {
		return Error.catchExceptions(function() {
			var rest = [];
			var i = 0;
			while(i < args.length) {
				var arg = args[i];
				
				switch processFlag(args, i) {
					case -1: // unrecognized flag
						if(arg.charCodeAt(0) == '-'.code)
							switch processAlias(args, i) {
								case -1: throw 'Unrecognized flag "$arg"';
								case v: i += v + 1;
							}
						else {
							rest.push(arg);
							i++;
						}
					case v:
						i += v + 1;
				}
			}
			return rest;
		});
	}
	
	function processFlag(args:Array<String>, index:Int) {
		return -1;
	}
	
	function processAlias(args:Array<String>, index:Int) {
		return -1;
	}
}