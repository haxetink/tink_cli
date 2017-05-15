package tink.cli.prompt;

import tink.io.Sink;
import tink.io.Source;
import tink.Stringly;
import tink.cli.Prompt;
import js.Node.*;
import js.node.Buffer;

using tink.CoreApi;

class NodePrompt extends IoPrompt {
	public function new() {
		super(
			Source.ofNodeStream('stdin', process.stdin), 
			Sink.ofNodeStream('stdout', process.stdout)
		);
	}
	
	override function secureInput(prompt:String):Promise<Stringly> {
		return Future.async(function(cb) {
			
			var rl:Dynamic = js.node.Readline.createInterface({
				input: process.stdin,
				output: process.stdout
			});

			function hidden(query, callback) {
				var stdin = untyped process.openStdin();
				process.stdin.on('data', function(buf:Buffer) {
					var char = buf.toString();
					switch (char) {
						case '\n' | '\r' | '\u0004':
							stdin.pause();
						default:
							process.stdout.write('\033[2K\033[200D' + query);
					}
				});

				rl.question(query, function(value) {
					rl.history = rl.history.slice(1);
					callback(value);
				});
			}

			hidden(prompt, function(password:Stringly) cb(Success(password)));
		});
	}
}