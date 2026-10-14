// Tweak.xm
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>

// ===== Флаги состояния =====
static bool g_recoilEnabled = true;
static UIWindow *g_menuWindow = nil;

// ===== Оригинальная функция =====
static void (*orig_ApplyCameraRecoil)(void *instance, float amount) = NULL;

// ===== Заглушка =====
static void hook_ApplyCameraRecoil(void *instance, float amount) {
    if (!g_recoilEnabled) return; // отдача выключена — выходим
    if (orig_ApplyCameraRecoil) orig_ApplyCameraRecoil(instance, amount);
}

// ===== Поиск базы UnityFramework =====
static uintptr_t getUnityBase(void) {
    uintptr_t base = 0;
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "UnityFramework")) {
            base = (uintptr_t)_dyld_get_image_header(i);
            break;
        }
    }
    return base;
}

// ===== Установка хука =====
static void installRecoilHook(void) {
    uintptr_t rva  = 19329732;              // RVA из дампа v1.3
    uintptr_t base = getUnityBase();
    if (!base) return;

    uintptr_t addr = base + rva;
    MSHookFunction((void *)addr,
                   (void *)hook_ApplyCameraRecoil,
                   (void **)&orig_ApplyCameraRecoil);
}

// ===== UI =====
@interface RecoilMenuView : UIView
@property (nonatomic, strong) UIButton *toggleBtn;
@end

@implementation RecoilMenuView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.65];
        self.layer.cornerRadius = 10;
        self.layer.masksToBounds = YES;

        _toggleBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _toggleBtn.frame = CGRectInset(self.bounds, 6, 6);
        [_toggleBtn setTitle:@"Recoil: ON" forState:UIControlStateNormal];
        [_toggleBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_toggleBtn addTarget:self action:@selector(toggleRecoil)
             forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_toggleBtn];
    }
    return self;
}
- (void)toggleRecoil {
    g_recoilEnabled = !g_recoilEnabled;
    [_toggleBtn setTitle:(g_recoilEnabled ? @"Recoil: ON" : @"Recoil: OFF")
                forState:UIControlStateNormal];
}
@end

static void showMenuWindow(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (g_menuWindow) return;
        UIWindow *win = [[UIWindow alloc] initWithFrame:CGRectMake(20, 80, 140, 44)];
        win.windowLevel = UIWindowLevelAlert + 1;
        win.backgroundColor = [UIColor clearColor];
        win.rootViewController = [UIViewController new];
        RecoilMenuView *menu = [[RecoilMenuView alloc] initWithFrame:win.bounds];
        [win.rootViewController.view addSubview:menu];
        win.hidden = NO;
        g_menuWindow = win;
    });
}

// ===== Точка входа =====
__attribute__((constructor))
static void initialize(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        installRecoilHook();
        showMenuWindow();
    });
}
