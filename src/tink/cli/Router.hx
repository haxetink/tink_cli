package tink.cli;

using tink.CoreApi;

class Router<T> {
	var command:T;
	public function new(command) {
		this.command = command;
	}
	
	public function process(args:Array<String>):ExitCode {
		return Noise;
	}
	
	function processArgs(args:Array<String>):Array<String> {
		var rest = [];
		var i = 0;
		while(i < args.length) {
			var arg = args[i];
			if(arg.charCodeAt(0) == '-'.code)
				if(arg.charCodeAt(1) == '-'.code)
					i += processFlag(args, i);
				else
					i += processAlias(args, i);
			else
				rest.push(arg);
			i++;
		}
		return rest;
	}
	
	function processFlag(args:Array<String>, index:Int) {
		return 0;
	}
	
	function processAlias(args:Array<String>, index:Int) {
		return 0;
	}
}