package;

import tink.io.Source;
import tink.io.Sink;
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
			.map(function(_) return assert('y' == command.result()));
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

class FakePrompt extends IoPrompt<Noise, Noise> {
	public function new(src) {
		super(src, Sink.BLACKHOLE);
	}
}