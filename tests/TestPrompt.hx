package;

import tink.io.Source;
import tink.io.Sink;
import tink.io.Duplex;
import tink.cli.Prompt;
import tink.cli.prompt.*;
import tink.unit.Assert.*;

using tink.CoreApi;

class TestPrompt {
	public function new() {}
	
	@:describe('Basic Input')
	public function testBasic() {
		var command = new PromptCommand();
		var prompt = new FakePrompt('y\n');
		return tink.Cli.process(['hi'], command, prompt)
			.map(function(_) return equals('y', command.result()));
	}
}


class PromptCommand extends DebugCommand {
	
	@:defaultCommand
	public function run(prompt:Prompt):Promise<String> {
		var result = prompt.prompt(MultipleChoices('Install?', ['y','n']));
		result.handle(function(o) switch o {
			case Success(result): debug = result;
			case Failure(e):
		});
		return result;
	}
}

class FakePrompt extends DuplexPrompt {
	public function new(input) {
		super(new FakeDuplex(input));
	}
}

class FakeDuplex implements Duplex {
	public var source(get, never):Source;
	public var sink(get, never):Sink;
	
	var _source:Source;
	
	public function new(input:Source) {
		_source = input;
	}
	
	public function close() {}
	
	inline function get_source() return _source;
	inline function get_sink() return tink.io.IdealSink.BlackHole.INST;
}