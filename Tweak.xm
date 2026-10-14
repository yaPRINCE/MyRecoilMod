// Tweak.xm
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>

// ===== Флаги состояния =====
static bool g_recoilEnabled = true;   // true = отдача работает, false = отключена
static bool g_menuVisible   = false;

// ===== Оригинальная функция =====
static void (*orig_ApplyCameraRecoil)(void *instance, float amount) = NULL;

// ===== Наша заглушка =====
static void hook_ApplyCameraRecoil(void *instance, float amount) {
    if (!g_recoilEnabled) {
        // Отдача выключена — просто выходим, ничего не применяем
        return;
    }
    if (orig_ApplyCameraRecoil) {
        orig_ApplyCameraRecoil(instance, amount);
    }
}

// ===== Получение базового адреса UnityFramework =====
static uintptr_t getUnityBase(void) {
    // На iOS основной код Unity лежит в UnityFramework.framework/UnityFramework
    uintptr_t base = (uintptr_t)_dyld_get_image_header(0); // fallback
    // Правильнее — пройтись по образам и найти UnityFramework
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
    // RVA метода, найденный в дампе: 19329732 (0x126EFC4)
    // ВНИМАНИЕ: это RVA, а не абсолютный адрес. Проверь его в своём дампе!
    uintptr_t rva  = 19329732;
    uintptr_t base = getUnityBase();
    uintptr_t addr = base + rva;

    MSHookFunction((void *)addr,
                   (void *)hook_ApplyCameraRecoil,
                   (void **)&orig_ApplyCameraRecoil);
}

// ===== Простое меню-кнопка через UIWindow =====
@interface RecoilMenuView : UIView
@property (nonatomic, strong) UIButton *toggleBtn;
@end

@implementation RecoilMenuView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.6];
        self.layer.cornerRadius = 12;
        self.layer.masksToBounds = YES;

        _toggleBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _toggleBtn.frame = CGRectMake(8, 8, frame.size.width - 16, frame.size.height - 16);
        [_toggleBtn setTitle:@"Recoil: ON" forState:UIControlStateNormal];
        [_toggleBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_toggleBtn addTarget:self
                       action:@selector(toggleRecoil)
             forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_toggleBtn];
    }
    return self;
}

- (void)toggleRecoil {
    g_recoilEnabled = !g_recoilEnabled;
    NSString *title = g_recoilEnabled ? @"Recoil: ON" : @"Recoil: OFF";
    [_toggleBtn setTitle:title forState:UIControlStateNormal];
}

@end

// ===== Показ плавающей кнопки в окне игры =====
static UIWindow *g_menuWindow = nil;

static void showMenuWindow(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (g_menuWindow) return;

        UIWindow *win = [[UIWindow alloc] initWithFrame:CGRectMake(20, 100, 160, 50)];
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
    // Ставим хук после загрузки Unity-модуля
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        installRecoilHook();
        showMenuWindow();
    });
}
