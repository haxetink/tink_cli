package;

import tink.io.Source;
import tink.io.Sink;
import tink.cli.Prompt;
import tink.cli.Rest;
import tink.cli.prompt.*;
import tink.unit.Assert.*;

using tink.CoreApi;

class TestPromptAndRest {
	public function new() {}
	
	@:variant('a1 foo bar baz', 'a1:foo,bar,baz')
	@:variant('a2 foo bar baz', 'a2:baz,foo,bar')
	@:variant('a3 foo bar baz', 'a3:baz,foo,bar')
	@:variant('b1 foo bar baz', 'b1:foo,bar,baz')
	@:variant('b2 foo bar baz', 'b2:foo,bar,baz')
	@:variant('b3 foo bar baz', 'b3:baz,foo,bar')
	public function mixed(args:String, result:String) {
		var command = new PromptRestCommand();
		return tink.Cli.process(args.split(' '), command)
			.map(function(_) return assert(result == command.result()));
	}
}


class PromptRestCommand extends DebugCommand {
	
	@:defaultCommand
	public function run(prompt:Prompt):Promise<Noise> return Noise;
	
	@:command public function a1(a:String, rest:Rest<String>, prompt:Prompt):Promise<Noise> return handle('a1', a, rest);
	@:command public function a2(rest:Rest<String>, a:String, prompt:Prompt):Promise<Noise> return handle('a2', a, rest);
	@:command public function a3(rest:Rest<String>, prompt:Prompt, a:String):Promise<Noise> return handle('a3', a, rest);
	
	@:command public function b1(b:String, prompt:Prompt, rest:Rest<String>):Promise<Noise> return handle('b1', b, rest);
	@:command public function b2(prompt:Prompt, b:String, rest:Rest<String>):Promise<Noise> return handle('b2', b, rest);
	@:command public function b3(prompt:Prompt, rest:Rest<String>, b:String):Promise<Noise> return handle('b3', b, rest);
	
	function handle(cmd:String, s:String, rest:Rest<String>) {
		debug = '$cmd:';
		debug += s;
		for(v in rest) debug += ',$v';
		return Noise;
	}
}