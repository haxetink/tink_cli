package;

import tink.Cli;
import tink.cli.Prompt;

using tink.CoreApi;

class TempCommand {
	static function main() {
		trace('entry');
		Cli.process(Sys.args(), new TempCommand()).handle(Cli.exit);
	}
	
	public function new() {}
	
	@:defaultCommand
	public function run(prompt:Prompt) {
		return prompt.prompt(Password('Enter password'))
			.next(function(pw) {
				trace(pw);
				return Noise;
			});
	}
}