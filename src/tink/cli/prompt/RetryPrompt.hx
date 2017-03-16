package tink.cli.prompt;

import tink.Stringly;
import tink.cli.Prompt;

using tink.CoreApi;

class RetryPrompt implements Prompt {
	var trials:Int;
	var proxy:Prompt;
	
	public function new(trials, ?proxy:Prompt) {
		this.trials = trials;
		this.proxy = proxy == null ? new SimplePrompt() : proxy;
	}
	
	public function print(v:String):Promise<Noise> {
		return proxy.print(v);
	}
	
	public function println(v:String):Promise<Noise> {
		return proxy.println(v);
	}
	
	public function prompt(type:PromptType):Promise<Stringly> {
		return switch type {
			case Simple(_):
				proxy.prompt(type);
			case MultipleChoices(v, c):
				Future.async(function(cb) {
					var remaining = trials;
					function next() {
						remaining--;
						function retry() {
							if(remaining > 0) next();
								else cb(Failure(new Error('Maximum retries reached')));
						}
						
						proxy.prompt(type).handle(function(o) switch o {
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