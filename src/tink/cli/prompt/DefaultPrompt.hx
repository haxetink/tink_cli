package tink.cli.prompt;

typedef DefaultPrompt = 
#if nodejs
	NodePrompt
#elseif sys
	SysPrompt
#else
	#error "Not Implemented"
#end
;