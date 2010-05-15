/*
 * Author: Landon Fuller <landonf@plausiblelabs.com>
 * Copyright (c) 2008 Plausible Labs Cooperative, Inc.
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

 /**
  * Modifications made by Appcelerator, Inc. licensed under the
  * same license as above.
  */

#import "iPhoneSimulator.h"
#import "nsprintf.h"

/**
 * A simple iPhoneSimulatorRemoteClient framework.
 */
@implementation iPhoneSimulator

/**
 * Print usage.
 */
- (void) printUsage {
	fprintf(stderr, "Usage: iphonesim <options> <command> ...\n");
	fprintf(stderr, "Commands:\n");
	fprintf(stderr, "  showsdks\n");
	fprintf(stderr, "  launch <application path>\n");
	fprintf(stderr, "Options:\n");
	fprintf(stderr, "  -sdkVersion <sdk version>\n");
	fprintf(stderr, "  -family <family>\n");
	fprintf(stderr, "  -uuid <uuid>\n");
	fprintf(stderr, "  -stderr <stderr redirection>\n");
	fprintf(stderr, "  -stdout <stdout redirection>\n");
	fprintf(stderr, "  -debug <YES|NO>\n");
	fprintf(stderr, "  -gdbcommands <gdb commands file>\n");

}


/**
 * List available SDK roots.
 */
- (int) showSDKs {
	NSArray *roots = [DTiPhoneSimulatorSystemRoot knownRoots];

	nsprintf(@"Simulator SDK Roots:");
	for (DTiPhoneSimulatorSystemRoot *root in roots) {
		nsfprintf(stderr, @"'%@' (%@)\n\t%@", [root sdkDisplayName], [root sdkVersion], [root sdkRootPath]);
	}

	return EXIT_SUCCESS;
}

- (void)session:(DTiPhoneSimulatorSession *)session didEndWithError:(NSError *)error {
	nsprintf(@"Session did end with error %@", error);

	if (error != nil)
		exit(EXIT_FAILURE);

	exit(EXIT_SUCCESS);
}


- (void)session:(DTiPhoneSimulatorSession *)session didStart:(BOOL)started withError:(NSError *)error {
	if (started) {
		nsprintf(@"Session started with pid %@", [session simulatedApplicationPID]);
		if (debug) {
			// launch gdb (and continue execution) maybe we should fork and exec?
			NSString *command = [NSString stringWithFormat:@"/usr/bin/gdb --pid %@", [session simulatedApplicationPID]];
			if (gdbcommands) {
				command = [command stringByAppendingString:[NSString stringWithFormat:@" -x %@", gdbcommands]];
			}
			nsprintf(command);
			system([command UTF8String]);
		}
	} else {
		nsprintf(@"Session could not be started: %@", error);
		exit(EXIT_FAILURE);
	}
}


/**
 * Launch the given Simulator binary.
 */
- (int)launchApp:(NSString *)path withFamily:(NSString*)family uuid:(NSString*)uuid{
	DTiPhoneSimulatorApplicationSpecifier *appSpec;
	DTiPhoneSimulatorSessionConfig *config;
	DTiPhoneSimulatorSession *session;
	NSError *error;

	/* Create the app specifier */
	appSpec = [DTiPhoneSimulatorApplicationSpecifier specifierWithApplicationPath:path];
	if (appSpec == nil) {
		nsprintf(@"Could not load application specification for %@", path);
		return EXIT_FAILURE;
	}
	nsprintf(@"App Spec: %@", appSpec);

	/* Load the default SDK root */

	nsprintf(@"SDK Root: %@", sdkRoot);

	/* Set up the session configuration */
	config = [[[DTiPhoneSimulatorSessionConfig alloc] init] autorelease];
	[config setApplicationToSimulateOnStart:appSpec];
	[config setSimulatedSystemRoot:sdkRoot];
	[config setSimulatedApplicationShouldWaitForDebugger:debug];

	[config setSimulatedApplicationLaunchArgs:[NSArray array]];
	[config setSimulatedApplicationLaunchEnvironment:[NSDictionary dictionary]];

	[config setLocalizedClientName:@"TitaniumDeveloper"];

	/* redirect stderr, maybe this could be in a cli option? */
	if (sessionStderr) {
		[config setSimulatedApplicationStdErrPath:sessionStderr];
	}
	if (sessionStdout) {
		[config setSimulatedApplicationStdOutPath:sessionStdout];
	}

	// this was introduced in 3.2 of SDK
	if ([config respondsToSelector:@selector(setSimulatedDeviceFamily:)])
	{
		if (family == nil)
		{
			family = @"iphone";
		}

		nsprintf(@"using device family %@",family);

		if ([family isEqualToString:@"ipad"])
		{
			[config setSimulatedDeviceFamily:[NSNumber numberWithInt:2]];
		}
		else
		{
			[config setSimulatedDeviceFamily:[NSNumber numberWithInt:1]];
		}
	}

	/* Start the session */
	session = [[[DTiPhoneSimulatorSession alloc] init] autorelease];
	[session setDelegate: self];
	NSNumber *pid = [NSNumber numberWithInt: 35];
	[session setSimulatedApplicationPID:pid];
	if (uuid!=nil)
	{
		[session setUuid:uuid];
	}

	if (![session requestStartWithConfig: config timeout: 30 error: &error]) {
		nsprintf(@"Could not start simulator session: %@", error);
		return EXIT_FAILURE;
	}

	return EXIT_SUCCESS;
}


/**
 * Execute 'main'
 */
- (void)runWithArgc:(int)argc argv:(char **)argv {
	// Foundation way to parse args
	NSUserDefaults *args = [NSUserDefaults standardUserDefaults];

	/* Read the command */
	char *cmd = nil;
	int cmdIdx = -1;

	for (int i=1; i < argc; i++) {
		// first non option argument is the command
		if (argv[i][0] != '-') {
			cmd = argv[i];
			cmdIdx = i;
			break;
		}
	}
	if (!cmd) {
		[self printUsage];
		exit(EXIT_FAILURE);
	}

	// debug option (launch gdb)
	debug = [args boolForKey:@"debug"];
	gdbcommands = [args stringForKey:@"gdbcommands"];
	sessionStderr = [args stringForKey:@"stderr"];
	sessionStdout = [args stringForKey:@"stdout"];

	if (strcmp(cmd, "showsdks") == 0) {
		exit([self showSDKs]);
	} else if (strcmp(cmd, "launch") == 0) {
		/* Requires an additional argument */
		if (cmdIdx + 1 >= argc) {
			fprintf(stderr, "Missing application path argument\n");
			[self printUsage];
			exit(EXIT_FAILURE);
		}
		NSString* ver = [args stringForKey:@"sdkVersion"];
		if (ver) {
			NSArray *roots = [DTiPhoneSimulatorSystemRoot knownRoots];
			for (DTiPhoneSimulatorSystemRoot *root in roots) {
				NSString *v = [root sdkVersion];
				if ([v isEqualToString:ver])
				{
					sdkRoot = root;
					break;
				}
			}
			if (sdkRoot == nil)
			{
				fprintf(stderr,"Unknown or unsupported SDK version: %s\n",ver);
				[self showSDKs];
				exit(EXIT_FAILURE);
			}
		} else {
			sdkRoot = [DTiPhoneSimulatorSystemRoot defaultRoot];
		}

		/* Don't exit, adds to runloop */
		[self launchApp:[NSString stringWithUTF8String:argv[cmdIdx+1]] withFamily:[args stringForKey:@"family"] uuid:[args stringForKey:@"uuid"]];
	} else {
		fprintf(stderr, "Unknown command: '%s'\n", cmd);
		[self printUsage];
		exit(EXIT_FAILURE);
	}
}

@end
