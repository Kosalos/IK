#import <UIKit/UIKit.h>

@interface ImageData : NSObject

-(id)initialize :(NSString *)filename;

-(void)drawInRect :(CGContextRef)context :(CGRect)r;
-(void)drawAtPoint :(CGContextRef)context :(CGPoint)pt;

@end

