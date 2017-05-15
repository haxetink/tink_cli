package tink.cli.prompt;

typedef DefaultPrompt = 
#if nodejs
	NodePrompt
#else
	#error "Not Implemented"
#end
;