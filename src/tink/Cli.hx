package tink;

import haxe.macro.Expr;
import haxe.macro.Context;

import tink.cli.Prompt;
import tink.cli.Result;
import tink.cli.DocFormatter;

using tink.CoreApi;
#if macro
using tink.MacroApi;
#end

class Cli {
	public static macro function process<Target:{}>(args:ExprOf<Array<String>>, target:ExprOf<Target>, ?prompt:ExprOf<Prompt>):ExprOf<Result> {
		var ct = Context.toComplexType(Context.typeof(target));
		prompt = prompt.ifNull(macro new tink.cli.prompt.SimplePrompt());
		return macro new tink.cli.macro.Router<$ct>($target, $prompt).process($args);
	}
	
	public static macro function getDoc<Target:{}, T>(target:ExprOf<Target>, ?formatter:ExprOf<DocFormatter<T>>):ExprOf<T> {
		formatter = formatter.ifNull(macro new tink.cli.doc.DefaultFormatter());
		var doc = tink.cli.Macro.buildDoc(Context.typeof(target));
		return macro $formatter.format($doc);
	}
	
	public static function exit(result:Outcome<Noise, Error>) {
		switch result {
			case Success(_): Sys.exit(0);
			case Failure(e):
				var message = e.message;
				if(e.data != null) message += ', ${e.data}';
				Sys.println(message); Sys.exit(e.code);
		}
	}
}