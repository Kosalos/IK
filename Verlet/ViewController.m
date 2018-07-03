#import "ViewController.h"

@interface ViewController ()
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    quartzView = (QuartzView *)self.view;
    [quartzView initialize];
}

-(BOOL)prefersStatusBarHidden{
    return YES;
}

@end
