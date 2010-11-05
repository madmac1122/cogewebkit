//
//  CoGeWebKitPlugIn.m
//  CoGeWebKit
//
//  Created by Tamas Nagy on 6/30/09.
//  Copyright (c) 2009 __MyCompanyName__. All rights reserved.
//

/* It's highly recommended to use CGL macros instead of changing the current context for plug-ins that perform OpenGL rendering */
#import <OpenGL/CGLMacro.h>

#import "CoGeWebKitPlugIn.h"

#define	kQCPlugIn_Name				@"CoGeWebKit"
#define	kQCPlugIn_Description		@"Renders the file at the given URL with WebKit. "


static void _TextureReleaseCallback(CGLContextObj cgl_ctx, GLuint name, void* info)
{
	// we dont delete our texture becauser we generate it once and update it via glSubTexImage2D.
	// we release during disableExecution.
	glDeleteTextures(1, &name);
}

@implementation CoGeWebKitPlugIn

@dynamic inputFilePath;
@dynamic inputShowWindow;

@dynamic inputWidth;
@dynamic inputHeight;
@dynamic inputJavascript;
@dynamic inputReexecuteJS;

@dynamic inputReload;
@dynamic inputForwardHistory;
@dynamic inputBackwardHistory;

// event input
@dynamic inputMouseScrollX;
@dynamic inputMouseScrollY;
@dynamic inputMouseX;
@dynamic inputMouseY;
@dynamic inputMouseRightDown;
@dynamic inputMouseLeftDown;

@dynamic outputJavascript;
@dynamic outputCurrentURL;
@dynamic outputImageUrls;
@dynamic outputHTMLStringSource;
@dynamic outputProgress;


@dynamic outputImage;
@dynamic outputDocWidth;
@dynamic outputDocHeight;

// class stuff
@synthesize theURLString;
@synthesize webBitmap1;
@synthesize workingOn1;
@synthesize urlList;
@synthesize stringHTMLSource;

/*
Here you need to declare the input / output properties as dynamic as Quartz Composer will handle their implementation
@dynamic inputFoo, outputBar;
*/

+ (NSDictionary*) attributes
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			kQCPlugIn_Name,QCPlugInAttributeNameKey,			
			kQCPlugIn_Description,QCPlugInAttributeDescriptionKey,
			nil];
}

+ (NSDictionary*) attributesForPropertyPortWithKey:(NSString*)key
{
	/*
	Specify the optional attributes for property based ports (QCPortAttributeNameKey, QCPortAttributeDefaultValueKey...).
	*/
	
	if([key isEqualToString:@"inputFilePath"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:
				QCPortTypeString, QCPortAttributeTypeKey,
				@"URL", QCPortAttributeNameKey,
				@"http://coge.lovqc.hu",  QCPortAttributeDefaultValueKey,				
				nil];
	}
	
	if([key isEqualToString:@"inputWidth"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Width", QCPortAttributeNameKey,
				[NSNumber numberWithDouble:640], QCPortAttributeDefaultValueKey,
				[NSNumber numberWithDouble:1], QCPortAttributeMinimumValueKey,
				[NSNumber numberWithFloat:[[NSScreen mainScreen] frame].size.width], QCPortAttributeMaximumValueKey,
				nil];
	}

	if([key isEqualToString:@"inputReload"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Reload", QCPortAttributeNameKey, nil];

	if([key isEqualToString:@"inputBackwardHistory"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Go Back", QCPortAttributeNameKey, nil];
	
	if([key isEqualToString:@"inputForwardHistory"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Go Forward", QCPortAttributeNameKey, nil];

	if([key isEqualToString:@"inputHeight"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Height", QCPortAttributeNameKey,
				[NSNumber numberWithDouble:480], QCPortAttributeDefaultValueKey,
				[NSNumber numberWithDouble:1], QCPortAttributeMinimumValueKey,
				[NSNumber numberWithFloat:[[NSScreen mainScreen] frame].size.height], QCPortAttributeMaximumValueKey,
				nil];
	}
		
	if([key isEqualToString:@"inputJavascript"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:QCPortTypeString, QCPortAttributeTypeKey,
				@"Javascript", QCPortAttributeNameKey, nil];
	}
	
	if([key isEqualToString:@"inputReexecuteJS"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:QCPortTypeBoolean, QCPortAttributeTypeKey,
				[NSNumber numberWithInt:0], QCPortAttributeDefaultValueKey,
				@"Re-execute Javascript", QCPortAttributeNameKey, nil];
	}
	
	if([key isEqualToString:@"inputMouseX"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:QCPortTypeNumber, QCPortAttributeTypeKey,
				[NSNumber numberWithFloat:0.0], QCPortAttributeDefaultValueKey,
				@"Mouse X Position", QCPortAttributeNameKey, nil];
	}
	
	if([key isEqualToString:@"inputMouseY"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:QCPortTypeNumber, QCPortAttributeTypeKey,
				[NSNumber numberWithFloat:0.0], QCPortAttributeDefaultValueKey,
				@"Mouse Y Position", QCPortAttributeNameKey, nil];
	}
	
	if([key isEqualToString:@"inputMouseLeftDown"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:QCPortTypeNumber, QCPortAttributeTypeKey,
				[NSNumber numberWithFloat:0.0], QCPortAttributeDefaultValueKey,
				@"Mouse Left Button", QCPortAttributeNameKey, nil];
	}	
	
	if([key isEqualToString:@"inputMouseRightDown"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:QCPortTypeNumber, QCPortAttributeTypeKey,
				[NSNumber numberWithFloat:0.0], QCPortAttributeDefaultValueKey,
				@"Mouse Right Button", QCPortAttributeNameKey, nil];
	}	
	
	if([key isEqualToString:@"inputMouseScrollX"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:QCPortTypeNumber, QCPortAttributeTypeKey,
				[NSNumber numberWithFloat:0.0], QCPortAttributeDefaultValueKey,
				@"Mouse Scroll X", QCPortAttributeNameKey, nil];
	}

	if([key isEqualToString:@"inputMouseScrollY"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:QCPortTypeNumber, QCPortAttributeTypeKey,
				[NSNumber numberWithFloat:0.0], QCPortAttributeDefaultValueKey,
				@"Mouse Scroll Y", QCPortAttributeNameKey, nil];
	}
	
	
	if([key isEqualToString:@"inputShowWindow"])
	{
		return [NSDictionary dictionaryWithObjectsAndKeys:QCPortTypeBoolean, QCPortAttributeTypeKey,
				[NSNumber numberWithInt:0], QCPortAttributeDefaultValueKey,
				@"View Browser Window", QCPortAttributeNameKey, nil];
	}
	
	if([key isEqualToString:@"outputImage"])
		return [NSDictionary dictionaryWithObjectsAndKeys:QCPortTypeImage, QCPortAttributeTypeKey,@"Image", QCPortAttributeNameKey,nil];
	
	if([key isEqualToString:@"outputJavascript"])		
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Javascript Returns", QCPortAttributeNameKey, nil];
	
	if([key isEqualToString:@"outputDocWidth"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Document Width", QCPortAttributeNameKey, nil];
	
	if([key isEqualToString:@"outputDocHeight"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Document Height", QCPortAttributeNameKey, nil];	
	
	if([key isEqualToString:@"outputImageUrls"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Image Locations", QCPortAttributeNameKey, nil];	
	
	if([key isEqualToString:@"outputHTMLStringSource"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"HTML Source String", QCPortAttributeNameKey, nil];	
	
	if([key isEqualToString:@"outputProgress"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Download Progress", QCPortAttributeNameKey, nil];	

	if([key isEqualToString:@"outputCurrentURL"])
		return [NSDictionary dictionaryWithObjectsAndKeys:@"Current URL", QCPortAttributeNameKey, nil];	

	return nil;
}

+ (NSArray*) sortedPropertyPortKeys
{
	return [NSArray arrayWithObjects:@"inputFilePath",
			@"inputWidth",
			@"inputHeight",
			@"inputJavascript",
			@"inputReexecuteJS",
			@"inputShowWindow",
			@"inputBackwardHistory",
			@"inputForwardHistory",
			@"inputReload",
			@"inputMouseX",
			@"inputMouseY",
			@"inputMouseLeftDown",
			@"inputMouseRightDown",
			@"inputMouseScrollX",
			@"inputMouseScrollY",
			@"inputKeyDown",
			@"outputImage",
			@"outputDocWidth", 
			@"outputDocHeight",
			@"outputJavascript",
			@"outputImageUrls", 
			@"outputHTMLStringSource",
			@"outputProgress",	
			@"outputCurrentURL",
			nil];
}


+ (QCPlugInExecutionMode) executionMode
{
	/*
	Return the execution mode of the plug-in: kQCPlugInExecutionModeProvider, kQCPlugInExecutionModeProcessor, or kQCPlugInExecutionModeConsumer.
	*/
	
	return kQCPlugInExecutionModeProvider;
}

+ (QCPlugInTimeMode) timeMode
{
	/*
	Return the time dependency mode of the plug-in: kQCPlugInTimeModeNone, kQCPlugInTimeModeIdle or kQCPlugInTimeModeTimeBase.
	*/
	
	return kQCPlugInTimeModeIdle;
}

-(void)initWebViewOnMainThread {

	WebViewNib = [[NSNib alloc] initWithNibNamed:@"WebWindow" bundle:[NSBundle bundleForClass:[self class]]];
	
	[WebViewNib instantiateNibWithOwner:self topLevelObjects:nil];
	
	[offscreenWindow setInitialFirstResponder:theWebView];
	[offscreenWindow display];
	
	// set delegates
	//we need to know the page download state
	[theWebView setFrameLoadDelegate:self];
	
	//delegate to make popup works
	[theWebView setPolicyDelegate:self];
	[theWebView setUIDelegate:self];
	

}

- (id) init
{
	if(self = [super init])
	{
		/*
		Allocate any permanent resource required by the plug-in.
		*/		
		
		//init on the main thread
		[self performSelectorOnMainThread:@selector(initWebViewOnMainThread) withObject:nil waitUntilDone:YES];
		
		lock1 = [[NSRecursiveLock alloc] init];
		
		[self setWorkingOn1:NO];
		
		
		[self setStringHTMLSource:@""];
		[self setUrlList:[NSMutableArray array]];
		
		updateOneshotOutputPorts = NO;
		
		JSOut = @"";
	}
	
	return self;
}

- (void) finalize
{
	/*
	Release any non garbage collected resources created in -init.
	*/
	
	
	[super finalize];
}

- (void) dealloc
{
	/*
	Release any resources created in -init.
	*/
	
	[self setStringHTMLSource:nil];
	[self setUrlList:nil];

	
	[theWebView setFrameLoadDelegate:nil];
	[theWebView setPolicyDelegate:nil];
	[theWebView setUIDelegate:nil];
	
	
	[lock1 release];
	
	[offscreenWindow close];
	[offscreenWindow release];
	[WebViewNib release];
	
	
	[super dealloc];
}


@end

@implementation CoGeWebKitPlugIn (Execution)

- (void) buildWebTexture1:(CGLContextObj)context
{
	CGLContextObj cgl_ctx = context;
	CGLLockContext(cgl_ctx);
	
	[lock1 lock];
	
	// create our image data.
	[theWebView lockFocus];
	NSBitmapImageRep* bitmap = [[NSBitmapImageRep alloc] initWithFocusedViewRect:[theWebView bounds]];
	[self setWebBitmap1:bitmap];
	[bitmap release];
	[theWebView unlockFocus];
	
//	NSLog (@"bitmap data format: isPlanar:%d, samplesPerPixel:%d, bitsPerPixel:%d, bytesPerRow:%d, bytesPerPlane:%d",[bitmap isPlanar], [bitmap samplesPerPixel], [bitmap bitsPerPixel], [bitmap bytesPerRow], [bitmap bytesPerPlane]);
	
	// create our texture 
	glEnable(GL_TEXTURE_RECTANGLE_EXT);
	glGenTextures(1, &webTexture1);
	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, webTexture1);
	
	// with storage hints & texture range -- assuming image depth should be 32 (8 bit rgba + 8 bit alpha ?). Sounds right.
	// glTextureRangeAPPLE(GL_TEXTURE_RECTANGLE_EXT,  self.inputWidth * self.inputHeight * (32 >> 3), [[self webBitmap1] bitmapData]); 
	// glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_STORAGE_HINT_APPLE , GL_STORAGE_CACHED_APPLE);
	glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_TRUE);
	
	// proper tex params.
	glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	
	
	// Set proper unpacking row length for bitmap
	//glPixelStorei(GL_UNPACK_ROW_LENGTH, width);	
	
	// Set byte aligned unpacking (needed for 3 byte per pixel bitmaps)
	//glPixelStorei (GL_UNPACK_ALIGNMENT, 1);
	
	// this definitely works
	glTexImage2D( GL_TEXTURE_RECTANGLE_EXT, 0, [[self webBitmap1] samplesPerPixel] == 4 ? GL_RGBA8 : GL_RGB8, width, height, 0, [[self webBitmap1] samplesPerPixel] == 4 ? GL_RGBA : GL_RGB, GL_UNSIGNED_BYTE, [[self webBitmap1] bitmapData]);
	
	// unset our client storage options storage
	// these fucks were causing our FBOs to fail.
	//glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_STORAGE_HINT_APPLE , GL_STORAGE_PRIVATE_APPLE);
	glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_FALSE);
	
	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, 0);
	
	//[bitmap release];
	
	[lock1 unlock];
	CGLUnlockContext(cgl_ctx);
}



- (BOOL) startExecution:(id<QCPlugInContext>)context
{
	/*
	Called by Quartz Composer when rendering of the composition starts: perform any required setup for the plug-in.
	Return NO in case of fatal failure (this will prevent rendering of the composition to start).
	*/
	
	
	width = self.inputWidth;
	height = self.inputHeight;
	
		
	return YES;
}

- (void) enableExecution:(id<QCPlugInContext>)context
{
	/*
	Called by Quartz Composer when the plug-in instance starts being used by Quartz Composer.
	*/
	//we are going to init our textures, and use client storage optimizations
	CGLContextObj cgl_ctx = [context CGLContextObj];
	CGLLockContext(cgl_ctx);
	
	[self buildWebTexture1:cgl_ctx];
	
	CGLUnlockContext(cgl_ctx);
	
}

-(void)executeJavascriptWithString:(NSString *)string{

	[theWebView stringByEvaluatingJavaScriptFromString:string];
}

-(void)setOutputWidthAndHeight {

	self.outputDocWidth = [[theWebView stringByEvaluatingJavaScriptFromString:@"document.width"] doubleValue];
	self.outputDocHeight = [[theWebView stringByEvaluatingJavaScriptFromString:@"document.height"] doubleValue];
}

-(void)webviewScrollY:(NSNumber *)value {

	NSPoint currentScrollPosition = [[[[[[theWebView mainFrame] frameView] documentView] enclosingScrollView] contentView] bounds].origin;
	
	if ([value doubleValue]<lastScrollValueY) {
		
		[[[[[[theWebView mainFrame] frameView] documentView] enclosingScrollView] documentView] scrollPoint:CGPointMake(currentScrollPosition.x, currentScrollPosition.y+50)];;
		
	} else {
		
		[[[[[[theWebView mainFrame] frameView] documentView] enclosingScrollView] documentView] scrollPoint:CGPointMake(currentScrollPosition.x, currentScrollPosition.y-50)];;
	}

	lastScrollValueY = [value doubleValue];

//	NSLog(@"scrollY %f", lastScrollValueY);
}

-(void)webviewScrollX:(NSNumber *)value {

	NSPoint currentScrollPosition = [[[[[[theWebView mainFrame] frameView] documentView] enclosingScrollView] contentView] bounds].origin;
	
	if ([value doubleValue]>lastScrollValueX) {
		
		[[[[[[theWebView mainFrame] frameView] documentView] enclosingScrollView] documentView] scrollPoint:CGPointMake(currentScrollPosition.x+50, currentScrollPosition.y)];;
		
	} else {
		
		[[[[[[theWebView mainFrame] frameView] documentView] enclosingScrollView] documentView] scrollPoint:CGPointMake(currentScrollPosition.x-50, currentScrollPosition.y)];;
		
	}

	lastScrollValueX = [value doubleValue];
	
	//NSLog(@"scrollX %f", lastScrollValueX);

}

-(void)webviewSetFrame {

	[theWebView setFrame:NSMakeRect(0, 0, width, height)];
}

-(void)webviewLoadRequest {

	[theWebView setDrawsBackground:NO];
	[[theWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.inputFilePath]]];
	

}

-(void)loadHTMLOnMainThread:(NSString *)htmlstring {
	
	[[theWebView mainFrame] loadHTMLString:htmlstring baseURL:[NSURL URLWithString:@""]];
	
	[theWebView reload:nil];
	[theWebView setDrawsBackground:NO];
	
}

-(void)webviewExecuteJS {

	JSOut = [theWebView stringByEvaluatingJavaScriptFromString:self.inputJavascript];
}



- (BOOL) execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments
{
	/*
	Called by Quartz Composer whenever the plug-in instance needs to execute.
	Only read from the plug-in inputs and produce a result (by writing to the plug-in outputs or rendering to the destination OpenGL context) within that method and nowhere else.
	Return NO in case of failure during the execution (this will prevent rendering of the current frame to complete).
	
	The OpenGL context for rendering can be accessed and defined for CGL macros using:
	CGLContextObj cgl_ctx = [context CGLContextObj];
	*/

	CGLContextObj cgl_ctx = [context CGLContextObj];
	// lock for thread saftey
	CGLLockContext(cgl_ctx);

	
	//if filepath changed, reload
	if ([self didValueForInputKeyChange:@"inputShowWindow"])
	{
		if(self.inputShowWindow)
		{
			[offscreenWindow center];
			[offscreenWindow orderFront:nil];
		}
		else
		{
			[offscreenWindow orderOut:nil];
		}	
			
	}
	
	//history handling
	if ([self didValueForInputKeyChange:@"inputBackwardHistory"] && (self.inputBackwardHistory == TRUE)) {
		
		[theWebView performSelectorOnMainThread:@selector(goBack:) withObject:nil waitUntilDone:YES];
		
		self.outputCurrentURL = [theWebView mainFrameURL];
	}

	if ([self didValueForInputKeyChange:@"inputForwardHistory"] && (self.inputForwardHistory == TRUE)) {
		
		[theWebView performSelectorOnMainThread:@selector(goForward:) withObject:nil waitUntilDone:YES];

		self.outputCurrentURL = [theWebView mainFrameURL];
}

	if ([self didValueForInputKeyChange:@"inputReload"] && (self.inputReload == TRUE)) {
		
		[theWebView performSelectorOnMainThread:@selector(reload:) withObject:nil waitUntilDone:YES];
		
		self.outputCurrentURL = [theWebView mainFrameURL];
	}
	
	//put the progress
	self.outputProgress = ([theWebView estimatedProgress]) ? [theWebView estimatedProgress] : 0; 
	
	if ([self didValueForInputKeyChange:@"inputFilePath"])
	{
		
		//stops swf playing - this actually stops current swf audio playing
		//needed in any situation
		
		// special case flash handling:
		if ([[self fileKind:self.inputFilePath] isEqualToString:@"Shockwave Flash Movie"])
		{

			[self performSelectorOnMainThread:@selector(handleLoadingFlashSetup) withObject:nil waitUntilDone:YES];
			
		}
		else
		{	
			
			
			//load content
			[self setTheURLString:self.inputFilePath];
			
			[self performSelectorOnMainThread:@selector(webviewLoadRequest) withObject:nil waitUntilDone:YES];
		}
		
		//for pure swf, we need to set the filepath on the transparent window's textfield, weird...
		[offscreenWindow setNaviPath:self.inputFilePath];
		
		self.outputCurrentURL = [NSString stringWithString:self.inputFilePath];

		
		NSLog(@"filepath changed, reload it...");
	}
	
	
	if(updateOneshotOutputPorts)
	{
		self.outputImageUrls = urlList;
		self.outputHTMLStringSource = stringHTMLSource;
		
		[self performSelectorOnMainThread:@selector(setOutputWidthAndHeight) withObject:nil waitUntilDone:YES];

		updateOneshotOutputPorts = NO;
	}
	
#pragma mark input event handling - this needs MAJOR CLEANUP
	
	if([self didValueForInputKeyChange:@"inputMouseX"] || [self didValueForInputKeyChange:@"inputMouseX"] || [self didValueForInputKeyChange:@"inputMouseLeftDown"] || [self didValueForInputKeyChange:@"inputMouseRightDown"])
	{
		NSPoint location = [self normalizedMouseLocationForMouseX:self.inputMouseX mouseY:self.inputMouseY isFlippedY:NO];
		NSView* hitView = [(NSView*)theWebView hitTest:location];
		NSUInteger type = 0;
		NSUInteger flag = 0;
		NSUInteger clickCount = 0;
		SEL selector; 
		
		
		// now we switch through the possible mouse combinations and build flag and event lists.
		// left mouse drag
		if(([self didValueForInputKeyChange:@"inputMouseX"] || [self didValueForInputKeyChange:@"inputMouseY"]) && self.inputMouseLeftDown)
		{
			type = NSLeftMouseDragged;
			flag = NSLeftMouseDraggedMask;
			clickCount = 0;
			selector = NSSelectorFromString(@"mouseDragged:");
		}
		// right mouse drag
		else if(([self didValueForInputKeyChange:@"inputMouseX"] || [self didValueForInputKeyChange:@"inputMouseY"]) && self.inputMouseRightDown)
		{
			type = NSRightMouseDragged;
			flag = NSRightMouseDraggedMask;
			clickCount = 0;
			selector = NSSelectorFromString(@"rightMouseDragged:");
		}
		// left mouse down/up
		else if([self didValueForInputKeyChange:@"inputMouseLeftDown"])
		{
			if(self.inputMouseLeftDown)
			{
				type = NSLeftMouseDown;
				flag = NSLeftMouseDownMask;
				clickCount = 1;
				selector = NSSelectorFromString(@"mouseDown:");
			}
			else
			{
				type = NSLeftMouseUp;
				flag = NSLeftMouseUpMask;
				clickCount = 0;
				selector = NSSelectorFromString(@"mouseUp:");
			}
		}
		// right mouse down/up
		else if(self.inputMouseRightDown)
		{
			if(self.inputMouseLeftDown)
			{
				type = NSRightMouseDown;
				flag = NSRightMouseDownMask;
				clickCount = 1;
				selector = NSSelectorFromString(@"rightMouseDown:");
			}
			else
			{
				type = NSRightMouseUp;
				flag = NSRightMouseUpMask;
				clickCount = 0;
				selector = NSSelectorFromString(@"rightMouseUp:");
			}
		}
		// mouse moved
		else
		{
			type = NSMouseMoved;
			flag = NSMouseMovedMask;
			clickCount = 0;
			// odd that mouseDragged works in Java. Should really be mouseMoved but..
			// this seems to work for now...
			selector = NSSelectorFromString(@"mouseDragged:");
		}
		
			

		NSEvent* mouseEvent = [NSEvent mouseEventWithType:type 
												 location:location 
											modifierFlags:flag
												timestamp:(NSTimeInterval)CFAbsoluteTimeGetCurrent()
											 windowNumber:[[hitView window] windowNumber]	// dont assume offScreenWindow
												  context:[[hitView window] graphicsContext] // ^^
											  eventNumber:0 // % INT32_MAX;
											   clickCount:clickCount
												 pressure:0.0];
		
		
		if(hitView)
		{
		//	NSLog(@"hitView class is:%@ at point:%@", [hitView className], NSStringFromPoint(location));
			
			[offscreenWindow makeFirstResponder:hitView];
			
			// dont allow clicks on UI items that mess up the offscreen window, OR if its a plugin..
			if([hitView isMemberOfClass:[NSPopUpButton class]] || [hitView isMemberOfClass:[NSScroller class]])
			{
				NSLog(@"is an NSControl no clicky");
			}
			else
			{
				[hitView performSelectorOnMainThread:selector withObject:mouseEvent waitUntilDone:YES];
			}
		}
		else
		{
			[theWebView performSelectorOnMainThread:selector withObject:mouseEvent waitUntilDone:YES];
			//[theWebView performSelector:selector withObject:mouseEvent];
		}
			
		
		
	}
	
	//if width or height changed
	if (([self didValueForInputKeyChange:@"inputWidth"]) || ([self didValueForInputKeyChange:@"inputHeight"])) {
		
		// NSLog(@"need new width or height, do it...");
		
		width = floorf(self.inputWidth);
		height = floorf(self.inputHeight);
		
		//set new size
		[offscreenWindow setContentSize:NSMakeSize(width, height + 38.0)];
		
		[self performSelectorOnMainThread:@selector(webviewSetFrame) withObject:nil waitUntilDone:YES];
		
		needsrebuild = YES;
	}

#pragma mark Scroll handling
	
	//inital mouse scroll handle
	if ([self didValueForInputKeyChange:@"inputMouseScrollY"]) {
	
		//NSLog(@"mouse scroll");
		
		[self performSelectorOnMainThread:@selector(webviewScrollY:) withObject:[NSNumber numberWithDouble:self.inputMouseScrollY] waitUntilDone:YES];
	
	}

	if ([self didValueForInputKeyChange:@"inputMouseScrollX"]) {
		
		//NSLog(@"mouse scroll");

		[self performSelectorOnMainThread:@selector(webviewScrollX:) withObject:[NSNumber numberWithDouble:self.inputMouseScrollX] waitUntilDone:YES];
		
	}
	
	
	
#pragma mark javascript
	
	//the boolean value is a trigger!
	if ([self didValueForInputKeyChange:@"inputReexecuteJS"])
	{
		needJSExecute = YES;
	}
	
	//if javascript command changed, execute it
	if (([self didValueForInputKeyChange:@"inputJavascript"]) || (needJSExecute))
	{
		//be safe
		if ([self.inputJavascript rangeOfString:@"window.close"].location == NSNotFound) {
			NSLog(@"safe javascript :)");
		[self performSelectorOnMainThread:@selector(webviewExecuteJS) withObject:nil waitUntilDone:YES];
			self.outputJavascript = JSOut;
		}
		else
			self.outputJavascript = @"hey, don't kill our plugin with a window.close, dude!";
		
		needJSExecute = NO;
	}

	
#pragma mark Image provider
	
	{
		
		if (needsrebuild) 
		{
			//bounds changed, destroy current texture
			[self buildWebTexture1:cgl_ctx];
			
			needsrebuild = NO;
		}
		
		
		if (![self workingOn1])
		{	// create our image data.
		//	NSLog(@"firing copyWebViewToBitmap1InBackground");
			[self performSelectorInBackground:@selector(copyWebViewToBitmap1InBackground) withObject:webBitmap1];
		}
		
	//	if (![self workingOn1])
		{
			
			// update our texture
			glPushAttrib(GL_COLOR_BUFFER_BIT | GL_TRANSFORM_BIT | GL_VIEWPORT);
			
			glGenTextures(1, &webTexture1);
			glEnable(GL_TEXTURE_RECTANGLE_EXT);
			glBindTexture(GL_TEXTURE_RECTANGLE_EXT, webTexture1);
					
			//GLint xOffset = 0;
			//GLint yOffset = 0;
			
			@synchronized(webBitmap1)
			{

				glTexImage2D( GL_TEXTURE_RECTANGLE_EXT, 0, [[self webBitmap1] samplesPerPixel] == 4 ? GL_RGBA8 : GL_RGB8, width, height, 0, [[self webBitmap1] samplesPerPixel] == 4 ? GL_RGBA : GL_RGB, GL_UNSIGNED_BYTE, [[self webBitmap1] bitmapData]);
			}
			
			glFlushRenderAPPLE();
			
		 
		#if __BIG_ENDIAN__
		#define CogePrivatePlugInPixelFormat QCPlugInPixelFormatARGB8
		#else
		#define CogePrivatePlugInPixelFormat QCPlugInPixelFormatBGRA8
		#endif
			
				self.outputImage =  [context outputImageProviderFromTextureWithPixelFormat:CogePrivatePlugInPixelFormat
																				pixelsWide:width
																				pixelsHigh:height
																					  name:webTexture1
																				   flipped:YES
																		   releaseCallback:_TextureReleaseCallback
																			releaseContext:NULL
																				colorSpace:CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB)
																		  shouldColorMatch:NO];
			
			glBindTexture(GL_TEXTURE_RECTANGLE_EXT, 0);
			glPopAttrib();
			
		}
	}
	
	// unlock to allow anything else to grab the context
	CGLUnlockContext(cgl_ctx);
	
	return YES;
}

- (void) disableExecution:(id<QCPlugInContext>)context
{
	/*
	Called by Quartz Composer when the plug-in instance stops being used by Quartz Composer.
	*/	
	
}

- (void) stopExecution:(id<QCPlugInContext>)context
{
	/*
	Called by Quartz Composer when rendering of the composition stops: perform any required cleanup for the plug-in.
	*/
	CGLContextObj cgl_ctx = [context CGLContextObj];
	CGLLockContext(cgl_ctx);
	// delete our texture
	glDeleteTextures(1, &webTexture1);
	CGLUnlockContext(cgl_ctx);
}

- (void) copyWebViewToBitmap1InBackground
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	[self setWorkingOn1:YES];
	
	[theWebView lockFocus];
	NSBitmapImageRep *newBitmap = [[NSBitmapImageRep alloc] initWithFocusedViewRect:[theWebView bounds]];
	[theWebView unlockFocus];
	
	// setters are atomic across threads, so this is thread safe weee...
	//[self performSelectorOnMainThread:@selector(setWebBitmap1:) withObject:newBitmap waitUntilDone:YES];
	
	@synchronized(webBitmap1)
	{
		[self setWebBitmap1:newBitmap];
	}
	[newBitmap release];
	
	[self setWorkingOn1:NO];
	
	[pool drain];
	
}

- (NSPoint) normalizedMouseLocationForMouseX:(double)inputMouseX mouseY:(double)inputMouseY isFlippedY:(BOOL)flippedy
{
	double mouseX = inputMouseX;
	double mouseY = inputMouseY;
	double aspect = self.inputHeight / self.inputWidth;

	// fix coordinates	
	mouseX /= 2.0;
	mouseX += 0.5;
	
	// handle aspect ratio conversion for QC coordinates since they normalize to x...
	mouseY += aspect;
	mouseY /= (aspect*2.0);
	
	mouseX *= self.inputWidth;
	//mouseY *= self.inputHeight;
	
	if (flippedy)
		mouseY = (self.inputHeight - (mouseY * self.inputHeight));
	else 
		mouseY *= self.inputHeight;
	
	NSPoint normalizedPoint = NSMakePoint((CGFloat) mouseX, (CGFloat) (mouseY));
	//NSLog(@"converted mouse coords are: %@", NSStringFromPoint(normalizedPoint));
	
	return normalizedPoint;
}

#pragma mark -
#pragma mark WebView Delegate Methods

//delegate to view javascript alert window
- (void)webView:(WebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WebFrame *)frame {
	
	//NSLog(@"alertpanel");
	
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	
	[alert addButtonWithTitle:@"OK"];	
	[alert setMessageText:@"Javascript says:"];	
	[alert setAlertStyle:NSWarningAlertStyle];	
	[alert setInformativeText:message];	
	[alert beginSheetModalForWindow:offscreenWindow modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
	
}

//alertpanel delegate
- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{	
}

- (WebView *)webView:(WebView *)sender createWebViewWithRequest:(NSURLRequest *)request
{
	//NSLog(@"create webview");	
	return theWebView;	
}

// getting image resources URL - ok, now only grab urls from html, not css 
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{	
	DOMNodeList *imgList = [[frame DOMDocument] getElementsByTagName:@"img"];
	// NSLog(@"img elements count: %d", [imgList length]);
	
	// autoreleased temp array.
	NSMutableArray * newURLArray = [NSMutableArray arrayWithCapacity:[imgList length]];	
	for (int i=0;i<[imgList length];i++)
	{
		// NSLog(@"src value for 1.%d element:%@",i, [[imgList item:i] valueForKey:@"src"]);
		[newURLArray insertObject:[[imgList item:i] valueForKey:@"src"] atIndex:i];
	}
	
	// update our oneshot ports
	[self setUrlList:newURLArray];
	[self setStringHTMLSource:[self sourceFromWebView:sender]];	
	updateOneshotOutputPorts = YES;

}

#pragma mark -
#pragma mark Helper Functions
- (NSString *)sourceFromWebView:(WebView *)webView
{
    return [[[[webView mainFrame] dataSource] representation] documentSource];
}

//found here: http://importantshock.wordpress.com/2007/01/07/cocoa-snippet-finding-a-files-kind/
- (NSString *)fileKind:(NSString *)path
{
	NSString *kind = nil;
	NSURL *url = [NSURL fileURLWithPath:[path stringByExpandingTildeInPath]];
	LSCopyKindStringForURL((CFURLRef)url, (CFStringRef *)&kind);
	return kind ? [kind autorelease] : @""; // If kind happens to be an empty string, don't autorelease it
}

- (void) handleLoadingFlashSetup
{
	//
	// ok, the method is load the wrapper - replace size and name - load the string for the webview
	//
	
	 NSLog(@"kind: %@", [self fileKind:self.inputFilePath]);
	// NSLog(@"path for wrapper: %@", [thisBundle pathForResource:@"wrapper" ofType:@"html"]);
	
	//load the wrapper to a string
	NSString *wrapper = [NSString stringWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"wrapper" ofType:@"html"] encoding:NSUTF8StringEncoding error:NULL];
	
	//replacing data
	NSString *html1 = [wrapper stringByReplacingOccurrencesOfString:@"thewidth" withString:[NSString stringWithFormat:@"%f",self.inputWidth]];
	NSString *html2 = [html1 stringByReplacingOccurrencesOfString:@"theheight" withString:[NSString stringWithFormat:@"%f",self.inputHeight]];
	
	
	NSString *htmlfull = [html2 stringByReplacingOccurrencesOfString:@"thefilename.swf" withString:self.inputFilePath];
	
	//	NSLog(@"html content: %@", htmlfull);
	//	NSLog(@"ok, 'upload' or html content...");
	
	//load with webframe
	
	[self performSelectorOnMainThread:@selector(loadHTMLOnMainThread:) withObject:htmlfull waitUntilDone:YES];
	
	[offscreenWindow setBackgroundColor:[NSColor clearColor]];
	[offscreenWindow setOpaque:NO];
		
	
	// set this to "fire" oneshot updates
	updateOneshotOutputPorts = YES;
}

@end