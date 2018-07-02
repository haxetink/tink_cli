package tink.cli.prompt;

import tink.io.Worker;
import tink.Stringly;
import tink.cli.Prompt;

using tink.CoreApi;

class SysPrompt implements Prompt {
	
	var worker:Worker;
	
	public function new(?worker:Worker) {
		this.worker = worker.ensure();
	}
	
	public inline function print(v:String):Promise<Noise> {
		return worker.work(function() {
			Sys.print(v);
			return Success(Noise);
		});
	}
	
	public inline function println(v:String):Promise<Noise> {
		return worker.work(function() {
			Sys.println(v);
			return Success(Noise);
		});
	}
	
	public function prompt(type:PromptType):Promise<Stringly> {
		return worker.work(function() {
			return switch type {
				case Simple(v): 
					Sys.print('$v: ');
					Success(Sys.stdin().readLine());
					
				case Secure(v):
					Sys.print('$v: ');
					var s = [];
					do switch Sys.getChar(false) {
						case 10 | 13:
							Sys.println('');
							break;
						case 3 | 4: // ctrl+C, ctrl+D
							Sys.println('');
							Sys.exit(1);
						case 127:
							s.pop();
						case c if(c >= 0x20):
							s.push(c);
						case c:
							Sys.println('');
							return Failure(new Error('Invalid char $c'));
					} while(true);
					Success(s.map(String.fromCharCode).join(''));
					
				case MultipleChoices(v, c):
					Sys.print('$v [${c.join('/')}]: ');
					Success(Sys.stdin().readLine());
			}
		});
	}
}