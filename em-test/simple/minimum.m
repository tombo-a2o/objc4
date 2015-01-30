//#include <Foundation/Foundation.h>
#include <objc/objc.h>
#include <objc/NSObject.h>
#include <stdio.h>

@interface MyClass : NSObject {
	@public
	int value;
}
- (int)add:(int)arg;
@end

@implementation MyClass
- (int)add:(int)arg {
	return value + arg;
}
@end

int main()
{
	MyClass *m = [[MyClass alloc] init];
	m->value = 1;
	printf("[m add:2] %d\n", [m add:2]);
}
