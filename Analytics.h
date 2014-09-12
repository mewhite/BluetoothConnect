//
//  Created by Yonat Sharon on 12/9/14.
//

#import <Foundation/Foundation.h>

/** Wrapper for logging and crash reporting frameworks (currenly Crashlytics) */
@interface Analytics : NSObject
+ (void)start;                  // call this in application:didFinishLaunchingWithOptions:
+ (void)trace:(NSString *)s;    // call trace() instead
+ (void)crash;
@end
