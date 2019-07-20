package tink.cli;

using tink.CoreApi;

class Router<T> {
	var command:T;
	var prompt:Prompt;
	var hasFlags:Bool;
	
	public function new(command, prompt, hasFlags) {
		this.command = command;
		this.prompt = prompt;
		this.hasFlags = hasFlags;
	}
	
	public function process(args:Array<String>):Result {
		return Noise;
	}
	
	function processArgs(args:Array<String>):Outcome<Array<String>, Error> {
		return 
			if(!hasFlags)
				Success(args);
			else
				Error.catchExceptions(function() {
					var args = expandAssignments(args);
					var rest = [];
					var i = 0;
					var flagsEnded = false;
					while(i < args.length) {
						var arg = args[i];
						
						if(arg == '--') {
							flagsEnded = true;
							i++;
						} else if(!flagsEnded && arg.charCodeAt(0) == '-'.code) { 
							switch processFlag(args, i) {
								case -1: // unrecognized flag
									if(arg.charCodeAt(1) != '-'.code) {
										switch processAlias(args, i) {
											case -1: throw 'Unrecognized alias "$arg"';
											case v: i += v + 1;
										}
									} else {
										throw 'Unrecognized flag "$arg"';
									}
									
								case v:
									i += v + 1;
							}
						} else {
							rest.push(arg);
							i++;
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
	
	function promptRequired():Promise<Noise> {
		return Noise;
	}
	
	static function expandAssignments(args:Array<String>):Array<String> {
		var ret = [];
		for(arg in args)
			switch [arg.charCodeAt(0), arg.charCodeAt(1), arg.indexOf('=')] {
				case ['-'.code, '-'.code, i] if(i != -1):
					ret.push(arg.substr(0, i));
					ret.push(arg.substr(i + 1));
				case _:
					ret.push(arg);
			}
		return ret;
	}
}