//
//  Created by Taun Chapman on 12/08/15.
//  Copyright © 2015 MOEDAE LLC. All rights reserved.
//

#import "MDCCloudTransferStatusIndicator.h"

@implementation MDCCloudTransferStatusIndicator

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
+(Class) layerClass {
    return [CAGradientLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        // Initialization code
        [self initializeDefaultValues];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    
    if (self) {
        [self initializeDefaultValues];
    }
    return self;
}

-(void) awakeFromNib {
    [super awakeFromNib];
}

-(void) initializeDefaultValues {
    _outlineColor = [UIColor blueColor];
    _fillColor = [UIColor whiteColor];
    _progressColor = [UIColor lightGrayColor];

    _progress = 0.5;
}

- (void)prepareForInterfaceBuilder
{
    [super prepareForInterfaceBuilder];
    [self setNeedsDisplay];
}

-(void)setProgress:(CGFloat)progress
{
    _progress = -progress;
    
    [self setNeedsDisplay];
}

-(void)drawRect:(CGRect)rect
{
    //// General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    
    UIColor *startColor = self.fillColor;
    UIColor *endColor = self.progressColor;
    
    CGFloat gradientCenter = 0;
    CGPoint gradientStart = CGPointZero;
    CGPoint gradientEnd = CGPointZero;
    
    if (self.progress == 0.0)
    {
        startColor = [self blendColor: startColor WithFraction: 0.5 ofColor: endColor];
    }
    else if (self.progress > 0)
    {
        gradientStart = CGPointMake(12.5, 7.5);
        gradientEnd = CGPointMake(12.5, 18.5);
        
        gradientCenter = self.progress;
    }
    else
    {
        gradientStart = CGPointMake(12.5, 18.5);
        gradientEnd = CGPointMake(12.5, 7.5);
        
        gradientCenter = ABS(self.progress);
    }
    
    //// Gradient Declarations
    CGFloat cloudProgressGradientLocations[] = {0, 0, gradientCenter, 1, 1};
    CGGradientRef cloudProgressGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)@[(id)startColor.CGColor, (id)[self blendColor: startColor WithFraction: 0.5 ofColor: startColor].CGColor, (id)startColor.CGColor, (id)[self blendColor: startColor WithFraction: 0.5 ofColor: endColor].CGColor, (id)endColor.CGColor], cloudProgressGradientLocations);
    
    //// Bezier Drawing
    UIBezierPath* bezierPath = [UIBezierPath bezierPath];
    [bezierPath moveToPoint: CGPointMake(10.78, 7.51)];
    [bezierPath addCurveToPoint: CGPointMake(15.09, 10.51) controlPoint1: CGPointMake(12.71, 7.61) controlPoint2: CGPointMake(14.35, 8.82)];
    [bezierPath addCurveToPoint: CGPointMake(15.23, 10.88) controlPoint1: CGPointMake(15.14, 10.63) controlPoint2: CGPointMake(15.19, 10.75)];
    [bezierPath addCurveToPoint: CGPointMake(18.62, 11.67) controlPoint1: CGPointMake(16.34, 10.18) controlPoint2: CGPointMake(17.7, 10.45)];
    [bezierPath addCurveToPoint: CGPointMake(19.5, 14.61) controlPoint1: CGPointMake(19.23, 12.48) controlPoint2: CGPointMake(19.52, 13.55)];
    [bezierPath addCurveToPoint: CGPointMake(22.62, 15.09) controlPoint1: CGPointMake(20.55, 14.37) controlPoint2: CGPointMake(21.78, 14.52)];
    [bezierPath addCurveToPoint: CGPointMake(22.62, 17.91) controlPoint1: CGPointMake(23.79, 15.87) controlPoint2: CGPointMake(23.79, 17.13)];
    [bezierPath addCurveToPoint: CGPointMake(21, 18.47) controlPoint1: CGPointMake(22.16, 18.22) controlPoint2: CGPointMake(21.59, 18.41)];
    [bezierPath addLineToPoint: CGPointMake(16.51, 18.5)];
    [bezierPath addLineToPoint: CGPointMake(4.5, 18.5)];
    [bezierPath addCurveToPoint: CGPointMake(1.5, 15.5) controlPoint1: CGPointMake(2.84, 18.5) controlPoint2: CGPointMake(1.5, 17.16)];
    [bezierPath addCurveToPoint: CGPointMake(4.5, 12.5) controlPoint1: CGPointMake(1.5, 13.84) controlPoint2: CGPointMake(2.84, 12.5)];
    [bezierPath addCurveToPoint: CGPointMake(5.5, 12.67) controlPoint1: CGPointMake(4.85, 12.5) controlPoint2: CGPointMake(5.19, 12.56)];
    [bezierPath addLineToPoint: CGPointMake(5.5, 12.5)];
    [bezierPath addCurveToPoint: CGPointMake(9.6, 7.58) controlPoint1: CGPointMake(5.5, 10.05) controlPoint2: CGPointMake(7.27, 8.01)];
    [bezierPath addCurveToPoint: CGPointMake(10.5, 7.5) controlPoint1: CGPointMake(9.89, 7.53) controlPoint2: CGPointMake(10.19, 7.5)];
    [bezierPath addCurveToPoint: CGPointMake(10.78, 7.51) controlPoint1: CGPointMake(10.59, 7.5) controlPoint2: CGPointMake(10.69, 7.5)];
    [bezierPath closePath];
    CGContextSaveGState(context);
    [bezierPath addClip];
    CGContextDrawLinearGradient(context, cloudProgressGradient, gradientStart, gradientEnd, 0);
    CGContextRestoreGState(context);
    [self.outlineColor setStroke];
    bezierPath.lineWidth = 1;
    [bezierPath stroke];
    
    
    //// Cleanup
    CGGradientRelease(cloudProgressGradient);
    CGColorSpaceRelease(colorSpace);
}

-(CGSize)intrinsicContentSize
{
    return CGSizeMake(25.0, 25.0);
}

- (UIColor*)blendColor: (UIColor*) color1 WithFraction: (CGFloat)fraction ofColor: (UIColor*)color2
{
    CGFloat r1 = 0, g1 = 0, b1 = 0, a1 = 0;
    CGFloat r2 = 0, g2 = 0, b2 = 0, a2 = 0;
    
    
    [color1 getRed: &r1 green: &g1 blue: &b1 alpha: &a1];
    [color2 getRed: &r2 green: &g2 blue: &b2 alpha: &a2];
    
    CGFloat r = r1 * (1 - fraction) + r2 * fraction;
    CGFloat g = g1 * (1 - fraction) + g2 * fraction;
    CGFloat b = b1 * (1 - fraction) + b2 * fraction;
    CGFloat a = a1 * (1 - fraction) + a2 * fraction;
    
    return [UIColor colorWithRed: r green: g blue: b alpha: a];
}

@end
