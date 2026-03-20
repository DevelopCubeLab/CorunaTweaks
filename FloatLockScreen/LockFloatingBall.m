#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

@interface FBPassThroughWindow : UIWindow
@end

@implementation FBPassThroughWindow
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    // 如果点到的是 window 自己或 rootView，则让事件穿透
    if (hit == self || hit == self.rootViewController.view) {
        return nil;
    }
    return hit;
}
@end

/// 创建一个View
@interface FBFloatRootViewController : UIViewController
@end

@implementation FBFloatRootViewController
/// 锁定界面方向为竖屏 不允许旋转这个VC
- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}
@end

static UIWindow *gWindow;
static UIButton *gButton;

/// 锁屏核心
static void FBLockDevice(void) {
    id sb = (id)[objc_getClass("SpringBoard") sharedApplication];
    SEL sel = NSSelectorFromString(@"_simulateLockButtonPress");
    if ([sb respondsToSelector:sel]) {
        ((void (*)(id, SEL))objc_msgSend)(sb, sel);
    }
}

@interface FBDragView : UIView
@end

@implementation FBDragView {
    CGPoint start;
}

/// 创建一个Float View来用来触发锁屏
- (instancetype)init {
    self = [super initWithFrame:CGRectMake(50, 200, 44, 44)];
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    self.layer.cornerRadius = 22;

    UILabel *l = [[UILabel alloc] initWithFrame:self.bounds];
    l.text = @"🔒";
    l.font = [UIFont systemFontOfSize:22];
    l.textAlignment = NSTextAlignmentCenter;
    [self addSubview:l];

    UIPanGestureRecognizer *pan =
    [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [self addGestureRecognizer:pan];

    UITapGestureRecognizer *tap =
    [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap)];
    [self addGestureRecognizer:tap];

    return self;
}

- (void)pan:(UIPanGestureRecognizer *)g {
    CGPoint t = [g translationInView:self.superview];
    self.center = CGPointMake(self.center.x + t.x, self.center.y + t.y);
    [g setTranslation:CGPointZero inView:self.superview];
}

- (void)tap {
    FBLockDevice();
}

@end

static void setupFloatingBall(void) {

    UIScene *targetScene = nil;
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive) {
            targetScene = scene;
            break;
        }
    }

    if (targetScene && [targetScene isKindOfClass:[UIWindowScene class]]) {
        gWindow = [[FBPassThroughWindow alloc] initWithWindowScene:(UIWindowScene *)targetScene];
    } else {
        gWindow = [[FBPassThroughWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    }

    gWindow.frame = [UIScreen mainScreen].bounds;
    gWindow.windowLevel = 2600;
    gWindow.backgroundColor = UIColor.clearColor;

    UIViewController *root = [FBFloatRootViewController new];
    root.view.backgroundColor = UIColor.clearColor;
    gWindow.rootViewController = root;

    FBDragView *v = [FBDragView new];
    [root.view addSubview:v];

    gWindow.hidden = NO;
    [gWindow makeKeyAndVisible];
}

__attribute__((constructor))
static void init(void) {

    NSString *bid = [[NSBundle mainBundle] bundleIdentifier];
    if (![bid isEqualToString:@"com.apple.springboard"]) return;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2*NSEC_PER_SEC),
                   dispatch_get_main_queue(), ^{
        setupFloatingBall();
    });
}
