package tink.cli.prompt;

import haxe.io.Bytes;
import tink.io.Sink;
import tink.io.Source;
import tink.cli.Prompt;

using tink.CoreApi;

class RetryPrompt implements Prompt {
	var trials:Int;
	
	public function new(trials) {
		this.trials = trials;
	}
	
	public function prompt(type:PromptType):Promise<String> {
		var simple = new SimplePrompt();
		
		return switch type {
			case Simple(_):
				simple.prompt(type);
			case MultipleChoices(v, c):
				Future.async(function(cb) {
					var remaining = trials;
					function next() {
						remaining--;
						function retry() {
							if(remaining > 0) next();
								else cb(Failure(new Error('Maximum retries reached')));
						}
						
						simple.prompt(type).handle(function(o) switch o {
							case Success(result):
								if(c.indexOf(result) == -1)
									retry();
								else
									cb(Success(result));
							case Failure(f):
								retry();
						});
					}
					next();
				});
		}
		
	}
}