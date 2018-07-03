#import "ImageData.h"

@implementation ImageData {
   	CGImageRef image;
    CGLayerRef layer;
	bool isInitialized;
	CGSize sz;
}

-(id)initialize  : (NSString *)filename
{
//zorro	self = [super init];
    
    if(self != nil) {
		image = CGImageRetain([UIImage imageNamed:filename].CGImage);
		sz.width  = CGImageGetWidth(image);
		sz.height = CGImageGetHeight(image);
		isInitialized = false;
	}
	
	return self;
}

-(void)makeLayer  : (CGContextRef)context 
{
	if(!isInitialized) {
		isInitialized = true;
		CGContextSaveGState(context);
		
		layer = CGLayerCreateWithContext(context,sz,NULL);
		
		CGContextRef ref = CGLayerGetContext(layer);
		CGRect bt = { 0,0,sz.width,sz.height };
		
		// flip source image vertically
		CGContextTranslateCTM(ref, 0.0, sz.height);
		CGContextScaleCTM(ref, 1.0, -1.0);
		
		CGContextDrawImage(ref, bt,image);	
		CGContextRestoreGState(context);
	}
}

-(void)drawInRect  : (CGContextRef)context  : (CGRect)r
{
    [self makeLayer:context];
	CGContextDrawLayerInRect(context,r,layer);
}

-(void)drawAtPoint  : (CGContextRef)context  : (CGPoint)pt
{
    [self makeLayer:context];
	CGContextDrawLayerInRect(context,CGRectMake(pt.x,pt.y,sz.width,sz.height),layer);
}

@end

