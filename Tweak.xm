#import <spawn.h>
#import <FrontBoardServices/FBSSystemService.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
@interface _UIActionSliderKnob : UIView
-(void)touchedAction;
@end
@interface FBSystemService : NSObject
+(id)sharedInstance;                        //existing presence of object
-(void)shutdownAndReboot:(BOOL)arg1;    //shutting down with the option to reboot (the boolean value)
-(void)exitAndRelaunch:(BOOL)arg1;        //restart the FrontBoard process (thus restarting SpringBoard as well; the boolean value has no change, the process restarts anyway)
-(void)nonExistantMethod;                   //fake method to crash in a safe way, loading SafeMode
@end
@interface _UIActionSlider : UIView
@property (nonatomic,copy) NSString* trackText;
@end

@interface _SBInternalPowerDownView : UIView
@end

static int Tap = 1;
static _UIActionSlider* actionSlider;

%hook _UIActionSliderKnob



%new
-(void)touchedAction {
    if (Tap == 1) {
        //change text here
        actionSlider.trackText = @"slide to respring";


    }
    else if (Tap == 2) {
        //Change Text again
        actionSlider.trackText = @"slide to safemode";

    }
    else if (Tap == 3) {
        //Change Text Again
        actionSlider.trackText = @"slide to soft reboot";

    }
    else if (Tap == 4) {
        //change text again
        actionSlider.trackText = @"slide to reboot";

    }
    else if (Tap == 5) {
      actionSlider.trackText = @"slide to power off";

    }

    Tap = Tap == 5 ? 1 : Tap + 1;
}

//Tap gesture recognizer/ if _UIActionSliderKnob gets tapped 1 time it calls touchedAction
-(instancetype)initWithFrame:(CGRect)frame {
    self = %orig;

    if (self) {
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchedAction)];
        tapRecognizer.numberOfTapsRequired = 1;
        tapRecognizer.cancelsTouchesInView = NO;
        [self addGestureRecognizer:tapRecognizer];
    }

    return self;
}
%end

%hook _UIActionSlider


-(void)didMoveToWindow {
    %orig;
    actionSlider = self;
}
%end

%hook _SBInternalPowerDownView
//shutdown
-(void)_powerDownSliderDidCompleteSlide{
  if (Tap == 1) {
    [[%c(FBSystemService) sharedInstance] shutdownAndReboot:NO];
  }
  //respring
  else if (Tap == 2) {
    NSLog(@"called 1");
    pid_t pid;
    int status;
    const char* args[] = {"killall", "-9", "SpringBoard", NULL};
    posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
    waitpid(pid, &status, WEXITED);
  }
  //safemode
  else if (Tap == 3) {
    NSLog(@"called 2");
    pid_t pid;
    int status;
    const char* args[] = {"killall", "-SEGV", "SpringBoard", NULL};
    posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
    waitpid(pid, &status, WEXITED);
  }
  //soft reboot
  else if (Tap == 4) {
    pid_t pid;
    int status;
    const char* args[] = {"ldRun", NULL, NULL, NULL};
    posix_spawn(&pid, "/usr/bin/ldRun", NULL, NULL, (char* const*)args, NULL);
    waitpid(pid, &status, WEXITED);
  }
  //reboot
  else if (Tap == 5) {
    [[%c(FBSystemService) sharedInstance] shutdownAndReboot:YES];
  }
}
%end
