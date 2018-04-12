//
//  DropViewController.m
//  Grain
//
//  Created by 别琳 on 2018/4/4.
//  Copyright © 2018年 HuZhaoHao. All rights reserved.
//

#import "DropViewController.h"
#import <CoreMotion/CoreMotion.h>

#define WIDTH   [UIScreen mainScreen].bounds.size.width

@interface DropViewController ()<UIAccelerometerDelegate>

@property (nonatomic,strong) CMMotionManager  *motionManager;
@property (strong,nonatomic)   NSMutableArray  *dropsArray;
@property (nonatomic , strong) UIGravityBehavior   *gravityBehavior;
@property (nonatomic , strong) UICollisionBehavior     * collisionBehavitor;
@property (nonatomic , strong) UIDynamicAnimator        * animator;

@property (strong,nonatomic) UIImageView *leftShoot;
@property (strong,nonatomic) UIImageView *rightShoot;
@property (strong,nonatomic) UIView *giftView;

@property (nonatomic, strong) dispatch_source_t timer;
@property (assign,nonatomic) BOOL isDropping;
@end

@implementation DropViewController

- (instancetype)init{
    self = [super init];
    if (self) {
        _motionManager = [[CMMotionManager alloc] init];
        [self startMotion];
    }
    return self;
}
#pragma mark instance methods
- (void)startMotion{
    if (_motionManager.accelerometerAvailable) {
        if (!_motionManager.accelerometerActive) {
            _motionManager.accelerometerUpdateInterval = 1.0/3.0;
            __unsafe_unretained typeof(self) weakSelf = self;
            [_motionManager startAccelerometerUpdatesToQueue:[[NSOperationQueue alloc]init]  withHandler:^(CMAccelerometerData * accelerometerData, NSError *  error) {
                if (error) {
                    NSLog(@"CoreMotion Error : %@",error);
                    [_motionManager stopAccelerometerUpdates];
                }
                CGFloat a = accelerometerData.acceleration.x;
                CGFloat b = accelerometerData.acceleration.y;
//                CGFloat c = accelerometerData.acceleration.z;
                CGVector gravityDirection = CGVectorMake(a,-b);
                weakSelf.gravityBehavior.gravityDirection = gravityDirection;
            }];
        }
    }else{
        NSLog(@"The accelerometer is unavailable");
    }

}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    _giftView =[[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_giftView];

    _leftShoot = [[UIImageView alloc] initWithFrame:CGRectMake(50, 100, 20, 20)];
    _leftShoot.image = [UIImage imageNamed:@"leftShoot"];
    [self.giftView addSubview:_leftShoot];

    _rightShoot = [[UIImageView alloc] initWithFrame:CGRectMake(WIDTH - 70, 100, 20, 20)];
    _rightShoot.image = [UIImage imageNamed:@"rightShoot"];
    [self.giftView addSubview:_rightShoot];

    UIButton *buton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_leftShoot.frame), 100, 50, 30)];
    buton.backgroundColor = [UIColor grayColor];
    [buton setTitle:@"开始" forState:UIControlStateNormal];
    [self.view addSubview:buton];
    [buton addTarget:self action:@selector(addSerialDrop) forControlEvents:UIControlEventTouchUpInside];


    UIButton *clearButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMinX(_rightShoot.frame)-50, 100, 50, 30)];
    clearButton.backgroundColor = [UIColor grayColor];
    [clearButton setTitle:@"清除" forState:UIControlStateNormal];
    [self.view addSubview:clearButton];
    [clearButton addTarget:self action:@selector(didClickedClear:) forControlEvents:UIControlEventTouchUpInside];
}
-(void)addSerialDrop{
    [self startMotion];
    UIImage *love = [UIImage imageNamed:@"love"];
    UIImage *star = [UIImage imageNamed:@"star"];
    if (self.dropsArray.count % 2 == 0) {
        [self dropWithCount:30 images:@[love]];
    }else{
        [self dropWithCount:30 images:@[star]];
    }
//
    [self serialDrop];

}
- (NSMutableArray *)dropWithCount:(int)count images:(NSArray *)images
{
    NSMutableArray *viewArray = [[NSMutableArray alloc] init];
    for (int i = 0 ; i < count; i++) {

        UIImage *image = [images objectAtIndex:rand()%[images count]];
        UIImageView * imageView =[[UIImageView alloc ]initWithImage:image];
        imageView.contentMode = UIViewContentModeCenter;
        imageView.center = CGPointMake(50, 100);
        imageView.tag = 11;
        if (i%2 == 0) {
            imageView.center = CGPointMake(WIDTH - 50, 100);
            imageView.tag = 22;
        }
        [viewArray addObject:imageView];
    }
    [self.dropsArray addObject:viewArray];
    return _dropsArray;

}
//串行
-(void)serialDrop{
    if (_isDropping) return;
    _isDropping = YES;
    dispatch_queue_t queue = dispatch_get_main_queue();
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC));/**< 延迟执行*/
    uint64_t interval = (uint64_t)(0.05 * NSEC_PER_SEC);
    dispatch_source_set_timer(self.timer, start, interval, 0);
    // 设置回调
    dispatch_source_set_event_handler(self.timer, ^{
        if (self.dropsArray.count == 0) return;
        NSMutableArray *currentDrops = self.dropsArray[0];

        if ([currentDrops count]) {
            if (currentDrops.count == 0) return;
            UIImageView * dropView = currentDrops[0];
            [currentDrops removeObjectAtIndex:0];
            [self.giftView addSubview:dropView];
            UIPushBehavior *pushBehavior = [[UIPushBehavior alloc] initWithItems:@[dropView] mode:UIPushBehaviorModeInstantaneous];
            [self.animator addBehavior:pushBehavior];
//            角度范围 ［0.6 1.0］
            float random = ((int)(2 + (arc4random() % (10 - 4 + 1))))*0.1;

            pushBehavior.pushDirection = CGVectorMake(0.6,random);
            if (dropView.tag != 11) {
                pushBehavior.pushDirection = CGVectorMake(-0.6,random);
            }

            pushBehavior.magnitude = 0.3;
            [self.gravityBehavior addItem:dropView];
            [self.collisionBehavitor addItem:dropView];

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                dropView.alpha = 0;
                [self.gravityBehavior removeItem:dropView];
                [self.collisionBehavitor removeItem:dropView];
                [pushBehavior removeItem:dropView];
                [self.animator removeBehavior:pushBehavior];
                [dropView removeFromSuperview];
            });

        }else{
            dispatch_source_cancel(self.timer);
            [self.dropsArray removeObject:currentDrops];
            _isDropping = NO;
            if (self.dropsArray.count) {
                [self serialDrop];
            }
        }

    });
    dispatch_source_set_cancel_handler(_timer, ^{

    });
    //启动
    dispatch_resume(self.timer);

}
-(NSMutableArray *)dropsArray{
    if (nil == _dropsArray) {
        _dropsArray = [NSMutableArray array];
    }
    return _dropsArray;
}
- (UIDynamicAnimator *)animator{
    if (!_animator) {
        _animator = [[UIDynamicAnimator alloc] initWithReferenceView:_giftView];
        /** 重力效果*/
        self.gravityBehavior = [[UIGravityBehavior alloc] init];
        //        self.gravityBehavior.gravityDirection = CGVectorMake(0.5,1);
        /** 碰撞效果*/
        self.collisionBehavitor = [[UICollisionBehavior alloc] init];
        [self.collisionBehavitor setTranslatesReferenceBoundsIntoBoundary:YES];
        [_animator addBehavior:self.gravityBehavior];
        [_animator addBehavior:self.collisionBehavitor];
    }
    return _animator;
}
-(void)didClickedClear:(id)sender{
    // 停止陀螺仪
    [_motionManager stopAccelerometerUpdates];
    _isDropping = NO;
    if (_timer) {
        dispatch_cancel(_timer);
        _timer = nil;
    }
    for (UIDynamicBehavior *behavior in _animator.behaviors)
    {
        if (behavior == self.gravityBehavior)
        {
            for (UIImageView *v in self.gravityBehavior.items)
            {
                [self.gravityBehavior removeItem:v];
                if (v.superview)[v removeFromSuperview];
            }
            continue;
        }
        else if (behavior == self.collisionBehavitor)
        {
            for (UIImageView *v in self.collisionBehavitor.items) {
                [self.collisionBehavitor removeItem:v];
                if (v.superview)[v removeFromSuperview];
            }
            continue;
        }
        else [_animator removeBehavior:behavior];
    }
    self.animator = nil;
    [self.dropsArray removeAllObjects];
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
