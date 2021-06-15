//
//  Module:   ADYAdjustFocusView   @ ADYLiveSDK
//
//  Function: 奥点云直播推流用 RTMP SDK
//
//  Copyright © 2021 杭州奥点科技股份有限公司. All rights reserved.
//
//  Version: 1.1.0  Creation(版本信息)

/**
 * @author   Created by 胡勤超 on 2021/5/27.
 * @instructions 说明
 该类是
 
 * @abstract  奥点官方网站  https://www.aodianyun.com
 
 */



#import "ADYAdjustFocusView.h"



@implementation ADYAdjustFocusView
{
    CGFloat _orginWidth;
    
}

- (instancetype)initWithFrame: (CGRect)frame
{
    if (self = [super initWithFrame: frame]) {
        _orginWidth = frame.size.width;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews]; // 注意，一定不要忘记调用父类的layoutSubviews方法！
    
}
- (void)drawRect:(CGRect)rect{
    [super drawRect:rect];
    self.backgroundColor = [UIColor clearColor];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetRGBStrokeColor(context, 55, 55, 55, 1.0);
    CGContextSetLineWidth(context, 2);
    CGContextAddRect(context, CGRectMake(0, 0, self.frame.size.width, self.frame.size.height));
    CGContextStrokePath(context);
    
}
-(void)frameByAnimationCenter:(CGPoint )center{
    
    self.hidden = YES;
    self.bounds = CGRectMake(0, 0, self->_orginWidth, self->_orginWidth);
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(restoreView) object:nil];
    self.hidden = NO;
    self.center = center;
    [UIView animateWithDuration:0.8 delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0 options:UIViewAnimationOptionOverrideInheritedOptions animations:^{
        self.bounds = CGRectMake(0, 0, self->_orginWidth - 20, self->_orginWidth - 20);
    } completion:^(BOOL finished) {
        
    }];
    
    [self performSelector:@selector(restoreView) withObject:nil afterDelay:2.0];
    
}
-(void)restoreView{
    dispatch_async(dispatch_get_main_queue(), ^{
        //2.0秒后追加任务代码到主队列，并开始执行
        //打印当前线程
        self.hidden = YES;
        self.bounds = CGRectMake(0, 0, self->_orginWidth, self->_orginWidth);
    });
}

@end
