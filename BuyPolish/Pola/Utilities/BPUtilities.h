#import <Foundation/Foundation.h>


#define weakify() __weak typeof(self)weakSelf = self;
#define strongify() __strong typeof(weakSelf)strongSelf = weakSelf;


@interface BPUtilities : NSObject

+ (id)handleNull:(id)object;

+ (UIImage *)imageWithColor:(UIColor *)color;
@end