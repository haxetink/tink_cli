package tink;

import haxe.macro.Expr;
import haxe.macro.Context;

import tink.cli.Prompt;
import tink.cli.Result;

#if macro
using tink.MacroApi;
#end

class Cli {
	public static macro function process<Target:{}>(args:ExprOf<Array<String>>, target:ExprOf<Target>, ?prompt:ExprOf<Prompt>):ExprOf<Result> {
		var ct = Context.toComplexType(Context.typeof(target));
		prompt = prompt.ifNull(macro new tink.cli.prompt.SimplePrompt());
		return macro new tink.cli.macro.Router<$ct>($target, $prompt).process($args);
	}
}