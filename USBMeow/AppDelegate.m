#import "AppDelegate.h"
#include <IOKit/hid/IOHIDManager.h>
#include <IOKit/hid/IOHIDKeys.h>
#include <IOKit/serial/IOSerialKeys.h>

static BOOL canImeowNow;
static int position;
static int meowCount;

@interface AppDelegate () {
}

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[self startHIDNotification];
	meowCount = 14;
	position = arc4random_uniform(meowCount-1);
	canImeowNow = NO;
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		canImeowNow = YES;
	});
}

- (IBAction)play:(id)sender {
	[[AppDelegate class] meow];
}

- (IBAction)stealth:(id)sender {
	ProcessSerialNumber psn = { 0, kCurrentProcess };
	TransformProcessType(&psn, kProcessTransformToBackgroundApplication);
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
}

- (void)startHIDNotification {
	IOHIDManagerRef ioHIDManager = IOHIDManagerCreate ( kCFAllocatorDefault, kIOHIDManagerOptionNone  );
	CFMutableDictionaryRef matchingDict = IOServiceMatching(kIOHIDDeviceKey);
	CFDictionaryAddValue(matchingDict, CFSTR(kIOSerialBSDTypeKey), CFSTR(kIOSerialBSDRS232Type));
	IOHIDManagerSetDeviceMatching (ioHIDManager, matchingDict);
	IOHIDManagerRegisterDeviceMatchingCallback( ioHIDManager, AppleHIDDeviceWasAddedFunction, (__bridge void *)(self) );
	IOHIDManagerRegisterDeviceRemovalCallback( ioHIDManager, AppleHIDDeviceWasRemovedFunction, (__bridge void *)(self) );
	CFRunLoopRef hidNotificationRunLoop = CFRunLoopGetCurrent();
	IOHIDManagerScheduleWithRunLoop(ioHIDManager, hidNotificationRunLoop, kCFRunLoopDefaultMode);
}

+ (void)meow {
	if (canImeowNow) {
		NSString *filename = [NSString stringWithFormat:@"Meow %i", position];
		NSSound *sound = [NSSound soundNamed:filename];
		if (sound == nil) {
			NSLog(@"no sound found for %@", filename);
		}
		[sound setLoops:NO];
		[sound play];
		// NSLog(@"playing %@", filename);
		
		position++;
		position = position % meowCount;
		
		// A simple debounce, because connecting a USB hub creates A BIG ORGY.
		canImeowNow = NO;
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			canImeowNow = YES;
		});
	}
	
}

void AppleHIDDeviceWasAddedFunction(void *context, IOReturn result, void *sender, IOHIDDeviceRef device) {
	// NSLog(@"added USB HID device");
	[[AppDelegate class] meow];
}

void AppleHIDDeviceWasRemovedFunction(void * context, IOReturn result, void * sender, IOHIDDeviceRef device) {
	//NSLog(@"removed USB HID device");
}

@end
