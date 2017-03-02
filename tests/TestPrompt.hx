package;

import tink.cli.Prompt;
import tink.cli.prompt.*;
using tink.CoreApi;

class TestPrompt {
	public function new() {}
	
	public function test() {
		var command = new PromptCommand();
		return tink.Cli.process(['hi'], command);
	}
}


class PromptCommand {
	public function new() {}
	
	@:defaultCommand
	public function run():Promise<String> {
		var result = new RetryPrompt(3).prompt(MultipleChoices('Install?', ['y','n']));
		result.handle(function(o) switch o {
			case Success(result): trace('Got: $result');
			case Failure(e): trace('Error: ' + e.toString());
		});
		return result;
	}
}