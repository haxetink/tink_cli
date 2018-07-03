package;

import tink.Cli;
import tink.cli.Prompt;

using tink.CoreApi;

class Playground {
	static function main() {
        Cli.process(Sys.args(), new Playground()).handle(Cli.exit);
    }

    public function new() {}

    @:command
    public function simple(prompt:Prompt) {
        return prompt.prompt(Simple('Input'))
			.next(function(input) {
				trace(input);
				return Noise;
			});
    }
	
    @:command
    public function multiple(prompt:Prompt) {
        return prompt.prompt(MultipleChoices('Choose one:', ['y','n']))
			.next(function(input) {
				trace(input);
				return Noise;
			});
    }
	
    @:command
    public function secure(prompt:Prompt) {
        return prompt.prompt(Secure('Password'))
			.next(function(input) {
				trace(input);
				return Noise;
			});
    }
	
	@:defaultCommand
	public function help() {
		trace('missing command (simple/multiple/secure)');
	}
}