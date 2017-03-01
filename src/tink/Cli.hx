package tink;

import haxe.macro.Expr;
import haxe.macro.Context;

import tink.cli.ExitCode;

class Cli {
	public static macro function process<Target:{}>(args:ExprOf<Array<String>>, target:ExprOf<Target>):ExprOf<ExitCode> {
		var ct = Context.toComplexType(Context.typeof(target));
		return macro new tink.cli.macro.Router<$ct>($target).process($args);
	}
}