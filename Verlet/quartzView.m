#import "quartzView.h"
#import "ImageData.h"

enum {
	SCREEN_XS = 768,
	SCREEN_YS = 1024,

    NUM_SEG = 6,
    BASE_INDEX = 0,
    GRIP_INDEX = NUM_SEG-1,

    BASE_X = 600,
    BASE_Y = 700,
    BASE_XS = 150,
    BASE_YS = 120,
    BASE_PX = BASE_XS/2,
    BASE_PY = BASE_YS/2,
    
    PSZ = 25,
    
    ARM1_XS = 50,
    ARM1_YS = 200,
    ARM1_PX1 = ARM1_XS/2, // pivot point offsets
    ARM1_PY1 = ARM1_PX1*3/2,
    ARM1_PX2 = ARM1_PX1,
    ARM1_PY2 = ARM1_PX1,    

    ARM2_XS = 45,
    ARM2_YS = 350,
    ARM2_PX1 = ARM2_XS/2,
    ARM2_PY1 = ARM2_PX1*3/2,
    ARM2_PX2 = ARM2_PX1,
    ARM2_PY2 = ARM2_PX1,

    ARM3_XS = 40,
    ARM3_YS = 300,
    ARM3_PX1 = ARM3_XS/2,
    ARM3_PY1 = ARM3_PX1*3/2,
    ARM3_PX2 = ARM3_PX1,
    ARM3_PY2 = ARM3_PX1,

    ARM4_XS = 35,
    ARM4_YS = 350,
    ARM4_PX1 = ARM4_XS/2,
    ARM4_PY1 = ARM4_PX1*3/2,
    ARM4_PX2 = ARM4_PX1,
    ARM4_PY2 = ARM4_PX1,

    GRIP_XS = 35,
    GRIP_YS = 60,
    GRIP_PX1 = GRIP_XS/2,
    GRIP_PY1 = GRIP_PX1*3/2,
    GRIP_PX2 = GRIP_PX1,
    GRIP_PY2 = GRIP_PX1 * 4,
    
    MEMORY_SZ = 50,
};

CGPoint memory[MEMORY_SZ+1][2];
int mCount = 0;
int mIndex = 0;

typedef struct {
    CGPoint pos,sz,p1,p2;
    float angle;
    CGPoint finalpos;
} ArmData;

ArmData armData[NUM_SEG] = {
    { { BASE_X,BASE_Y },  { BASE_XS,BASE_YS }, { 0,0 },               { BASE_PX,BASE_PY   },  0,    { 0,0 } },
    { { 0,0 },            { ARM1_XS,ARM1_YS }, { ARM1_PX1,ARM1_PY1 }, { ARM1_PX2,ARM1_PY2 }, 36,    { 0,0 } },
    { { 0,0 },            { ARM2_XS,ARM2_YS }, { ARM2_PX1,ARM2_PY1 }, { ARM2_PX2,ARM2_PY2 },  4,    { 0,0 } },
    { { 0,0 },            { ARM3_XS,ARM3_YS }, { ARM3_PX1,ARM3_PY1 }, { ARM3_PX2,ARM3_PY2 },  3,    { 0,0 } },
    { { 0,0 },            { ARM4_XS,ARM4_YS }, { ARM4_PX1,ARM4_PY1 }, { ARM4_PX2,ARM4_PY2 },  3,    { 0,0 } },
    { { 0,0 },            { GRIP_XS,GRIP_YS }, { GRIP_PX1,GRIP_PY1 }, { GRIP_PX2,GRIP_PY2 }, M_PI/2,    { 0,0 } }
};

typedef struct {
    ArmData data[NUM_SEG];
    float grip;
    CGPoint endpoint;
} RobotData;

RobotData robot1,robot2;

float rAlpha[MEMORY_SZ+1];
RobotData rMemory[MEMORY_SZ+1];
int rCount,rIndex;

@implementation QuartzView {
    CGPoint pt,previousPt;
    NSTimer *animationTimer;
    CGContextRef context;
}

#pragma mark ======================== reset

-(void)reset
{
}

#pragma mark ======================== heartBeatTimer

-(void)heartBeatTimer
{
	[self setNeedsDisplay];
}

#pragma mark ======================== initialize

-(void)initialize
{
    memcpy(&robot1.data,&armData,sizeof(armData));
    robot1.grip = 20;
    
	animationTimer = [NSTimer scheduledTimerWithTimeInterval:.04 target:self selector:@selector(heartBeatTimer) userInfo:nil repeats:TRUE];
	[self reset];
}

#pragma mark ======================== 

CGPoint target;
bool haveTarget = false;
float aa1 = 0.002;

-(void)jointMove : (float)a1 : (float)a2 : (float)a3 : (float)a4
{
    RobotData t1,t2;
    float d1,d2;
    
    t1 = robot2;  [self updateEndPoint:&t1:+a1:+a2:+a3:+a4];
    t2 = robot2;  [self updateEndPoint:&t2:-a1:-a2:-a3:-a4];
    
    d1 = hypotf(t1.endpoint.x - target.x,t1.endpoint.y - target.y);
    d2 = hypotf(t2.endpoint.x - target.x,t2.endpoint.y - target.y);
    
    if(fabs(d1) < fabs(d2))
        robot2 = t1; else robot2 = t2;
}

-(void)updateRobotPosition
{
    if(!haveTarget) return;

    for(int cycle=0;cycle<20;++cycle) {
        [self jointMove:0:0:0:aa1];
        [self jointMove:0:0:aa1:0];
        [self jointMove:0:aa1:0:0];
        [self jointMove:aa1:0:0:0];
    }
}

#pragma mark ======================== Touch

-(void)touchesBegan : (NSSet *)touches withEvent : (UIEvent *)event
{
	UITouch *touch = [touches anyObject];	
	pt = [touch locationInView:[touch view]];
	
	// UL corner?
	if(pt.x < 50 && pt.y < 50)	{
		[self reset];
		return;
	}

	// UR corner?
	if(pt.x > 700 && pt.y < 50)	{
		return;
	}
    
    if(haveTarget)
        robot1 = robot2;
    
    robot2 = robot1;
    target = pt;
    mIndex = mCount = 0;
    rIndex = rCount = 0;
    haveTarget = true;
}

-(void)touchesMoved : (NSSet *)touches withEvent : (UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	pt = [touch locationInView:[touch view]];
}

-(void)touchesEnded : (NSSet *)touches withEvent : (UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	pt = [touch locationInView:[touch view]];
}

#pragma mark ======================== Graphics helper routines

-(void)drawLine : (CGFloat)x1 : (CGFloat)y1 : (CGFloat)x2 : (CGFloat)y2
{
	CGContextMoveToPoint(context,x1,y1);
	CGContextAddLineToPoint(context,x2,y2);
	CGContextStrokePath(context);	
}

-(void)drawLine : (CGPoint)p1 : (CGPoint)p2
{
	CGContextMoveToPoint(context,p1.x,p1.y);
	CGContextAddLineToPoint(context,p2.x,p2.y);
	CGContextStrokePath(context);
}

-(void)drawCross : (CGPoint)p
{
    #define CC 5
    [self drawLine:p.x-CC:p.y:p.x+CC:p.y];
    [self drawLine:p.x:p.y-CC:p.x:p.y+CC];
}

-(void)drawRectangle : (CGFloat)x1 : (CGFloat)y1 : (CGFloat)xs : (CGFloat)ys
{
	CGContextStrokeRect(context,CGRectMake(x1,y1,xs,ys));
}

-(void)drawFilledRectangle : (CGFloat)x1 : (CGFloat)y1 : (CGFloat)xs : (CGFloat)ys
{
	CGContextFillRect(context,CGRectMake(x1,y1,xs,ys));
}

-(void)drawCircle : (CGFloat)x1 : (CGFloat)y1 : (CGFloat)sz
{
    CGFloat offset = sz/2.0f;
	CGContextStrokeEllipseInRect(context,CGRectMake(x1-offset,y1-offset,sz,sz));
}

#pragma mark ========================

-(void)drawBase
{
    [self drawRectangle:BASE_X:BASE_Y:BASE_XS:BASE_YS];
    [self drawCircle:BASE_PX:BASE_PY:PSZ];
}

-(CGPoint)pointOffset : (CGPoint)base : (float)angle : (float)amount
{
    base.x += cosf(angle) * amount;
    base.y += sinf(angle) * amount;
    return base;    
}

-(void)drawArmData : (RobotData *)robot : (int)index
{
    ArmData *p = &robot->data[index];
    
    if(index == BASE_INDEX) {
        [self drawRectangle:p->pos.x:p->pos.y:p->sz.x:p->sz.y];
        [self drawCircle:p->finalpos.x:p->finalpos.y:PSZ];
        return;
    }
    
    CGPoint pt1 = robot->data[index-1].finalpos;
    CGPoint pt2 = p->finalpos;

    CGPoint pt1c = [self pointOffset:pt1:p->angle:-p->p1.y];
    CGPoint pt2c = [self pointOffset:pt2:p->angle:+p->p2.y];
    
    float a2 = p->angle + M_PI/2;
    
    CGPoint pt1a = [self pointOffset:pt1c:a2:-p->p1.y];
    CGPoint pt1b = [self pointOffset:pt1c:a2:+p->p1.y];
    
    if(index == GRIP_INDEX) { // gripper
        CGPoint pt2a = [self pointOffset:pt2c:a2:-p->p1.y];
        CGPoint pt2b = [self pointOffset:pt2c:a2:+p->p1.y];
        CGPoint pt3a = [self pointOffset:pt2c:a2:-p->p2.y];
        CGPoint pt3b = [self pointOffset:pt2c:a2:+p->p2.y];
        
        CGPoint pt3c = [self pointOffset:pt2:p->angle:+p->p2.y + 10];
        CGPoint pt4a = [self pointOffset:pt3c:a2:-p->p2.y];
        CGPoint pt4b = [self pointOffset:pt3c:a2:+p->p2.y];
        
        // arms
        CGPoint pt5a1 = [self pointOffset:pt3c:a2:-robot->grip];
        CGPoint pt5a2 = [self pointOffset:pt3c:a2:-(robot->grip+10)];
        CGPoint pt5b1 = [self pointOffset:pt3c:a2:+robot->grip];
        CGPoint pt5b2 = [self pointOffset:pt3c:a2:+(robot->grip+10)];
        
        CGPoint pt5c = [self pointOffset:pt2:p->angle:+p->p2.y + 50];
        
        CGPoint pt6a1 = [self pointOffset:pt5c:a2:-robot->grip];
        CGPoint pt6a2 = [self pointOffset:pt5c:a2:-(robot->grip+10)];
        CGPoint pt6b1 = [self pointOffset:pt5c:a2:+robot->grip];
        CGPoint pt6b2 = [self pointOffset:pt5c:a2:+(robot->grip+10)];

        [self drawLine:pt1a:pt1b];
        [self drawLine:pt1a:pt2a];
        [self drawLine:pt1b:pt2b];
        [self drawLine:pt2a:pt3a];
        [self drawLine:pt2b:pt3b];
        [self drawLine:pt3a:pt4a];
        [self drawLine:pt3b:pt4b];
        [self drawLine:pt4a:pt4b];
        
        [self drawLine:pt5a2:pt6a2];
        [self drawLine:pt6a2:pt6a1];
        [self drawLine:pt6a1:pt5a1];

        [self drawLine:pt5b2:pt6b2];
        [self drawLine:pt6b2:pt6b1];
        [self drawLine:pt6b1:pt5b1];
        
        return;
    }

    CGPoint pt2a = [self pointOffset:pt2c:a2:-p->p2.y];
    CGPoint pt2b = [self pointOffset:pt2c:a2:+p->p2.y];

    [self drawLine:pt1a:pt1b];
    [self drawLine:pt2a:pt2b];
    [self drawLine:pt1a:pt2a];
    [self drawLine:pt1b:pt2b];
    [self drawCircle:p->finalpos.x:p->finalpos.y:PSZ];
}

-(void)drawRobot : (RobotData *)robot
{
    for(int i=0;i<NUM_SEG;++i)
        [self drawArmData:robot:i];

    [self drawCross:robot->endpoint];
}

#pragma mark ========================

-(void)updateFinalPos : (RobotData *)robot : (int)index
{
    ArmData *p = &robot->data[index];
    
    if(index == BASE_INDEX) {
        p->finalpos.x = p->pos.x + p->p2.x;
        p->finalpos.y = p->pos.y + p->p2.y;
        return;
    }
    
    // assume parent's final is ready
    float dist = p->sz.y - p->p1.y - p->p2.y;
    
    CGPoint p1 = robot->data[index-1].finalpos;
    
    p->finalpos.x = p1.x + cosf(p->angle) * dist;
    p->finalpos.y = p1.y + sinf(p->angle) * dist;
}

-(void)updateEndPoint : (RobotData *)robot : (float)a1 : (float)a2 : (float)a3 : (float)a4
{
    robot->data[1].angle += a1;
    robot->data[2].angle += a2;
    robot->data[3].angle += a3;
    robot->data[4].angle += a4;
    
    for(int i=0;i<NUM_SEG;++i)
        [self updateFinalPos:robot:i];

    robot->endpoint = [self pointOffset:robot->data[GRIP_INDEX].finalpos:robot->data[GRIP_INDEX].angle:100];
}

#pragma mark ======================== 

-(void)addMemory : (CGPoint)p
{
    static CGPoint prevP = { 0,0 };
    
    if(!mCount) prevP = p;
    
    memory[mIndex][0] = prevP;
    memory[mIndex][1] = p;
    if(++mIndex >= MEMORY_SZ)
        mIndex = 0;
    
    if(mCount < MEMORY_SZ) ++mCount;
    
    prevP = p;
    
    // ----------------------------------------
    
    rMemory[rIndex] = robot2;
    rAlpha[rIndex] = 1;
    if(++rIndex >= MEMORY_SZ)
        rIndex = 0;
    
    if(rCount < MEMORY_SZ) ++rCount;
}

#pragma mark ======================== drawRect

-(void)drawRect : (CGRect)rect
{
    // screen background
	context = UIGraphicsGetCurrentContext();
    
    [[UIColor blackColor]set];
    [self drawFilledRectangle:0:0:SCREEN_XS:SCREEN_YS];
    
    //CGContextScaleCTM(context,.51,.51);
    
    [self updateEndPoint:&robot1:0:0:0:0];
    [[UIColor  colorWithRed:1 green:1 blue:1 alpha:.3]set];
    [self drawRobot:&robot1];
    
    // ---------------------------------------
    [self updateRobotPosition];
    
    if(haveTarget) {
        
        [self addMemory:robot2.endpoint];
        
        [[UIColor greenColor]set];
        [self drawCircle:target.x:target.y:PSZ];
        for(int i=0;i<mCount;++i)
            [self drawLine:memory[i][0]:memory[i][1]];
    }
    
//    [[UIColor yellowColor]set];
//    [self drawRobot:&robot2];
    
    for(int i=0;i<rCount;++i) {
        if(rAlpha[i] <= 0) continue;
        [[UIColor  colorWithRed:1 green:1 blue:1 alpha:rAlpha[i]]set];
        [self drawRobot:&rMemory[i]];
        
        rAlpha[i] -= .06;
    }
    
    robot1.data[GRIP_INDEX].angle = M_PI/2;

   // printf("A %6.2f %6.2f %6.2f %6.2f\n",robot2.data[1].angle,robot2.data[2].angle,robot2.data[3].angle,robot2.data[4].angle);
    // ---------------------------------------
//    static float a = 0;
//    float gsz = 50;
//    robot2.grip = gsz/2 + sinf(a) * gsz/2;
//    a += 0.08;
    
    //printf("Grip %3f\n",grip);
}

@end
