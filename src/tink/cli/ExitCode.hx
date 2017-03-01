package tink.cli;

using tink.CoreApi;

@:forward
abstract ExitCode(Future<Int>) from Future<Int> to Future<Int> {
	@:from
	public static inline function ofCode(v:Int):ExitCode
		return Future.sync(v);
		
	@:from
	public static inline function ofCodePromise(v:Promise<Int>):ExitCode
		return v.map(function(o) return o.orUse(1));
		
	@:from
	public static inline function ofPromise<T>(v:Promise<T>):ExitCode
		return v.map(function(o) return o.isSuccess() ? 0 : 1);
}