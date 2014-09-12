//
//  Created by Yonat Sharon on 12/9/14.
//

#import "Analytics.h"
#import <Crashlytics/Crashlytics.h>

@implementation Analytics

+ (void)start
{
    [Crashlytics startWithAPIKey:@"ecff7b477672f6daf735d4a810593b62cc70e111"]; // key for BluetoothConnect app
}

+ (void)trace:(NSString *)s
{
#ifdef DEBUG
    CLSNSLog(@"%@", s);
#else
    CLSSLog(@"%@", s);
#endif
}

+ (void)crash
{
    [[Crashlytics sharedInstance] crash];
}

@end