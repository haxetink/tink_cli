package tink.cli;

using tink.CoreApi;

@:forward
abstract ExitCode(Future<Int>) from Future<Int> to Future<Int> {
	@:from
	public static inline function ofCode(v:Int):ExitCode
		return Future.sync(v);
		
	// @:from
	// public static inline function ofCodeOutcome<E>(v:Outcome<Int, E>):ExitCode
	// 	return Future.sync(v.orUse(1));
		
	@:from
	public static inline function ofOutcome<T, E>(v:Outcome<T, E>):ExitCode
		return Future.sync(v.isSuccess() ? 0 : 1);
		
	// @:from
	// public static inline function ofCodePromise(v:Promise<Int>):ExitCode
	// 	return v.map(function(o) return o.orUse(1));
		
	@:from
	public static inline function ofPromise<T>(v:Promise<T>):ExitCode
		return v.map(function(o) return o.isSuccess() ? 0 : 1);
}