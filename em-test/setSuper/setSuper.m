// TEST_CFLAGS -Wno-deprecated-declarations

#include <objc/runtime.h>
#include <objc/message.h>
#include <objc/NSObject.h>
#include <assert.h>
#include <stdio.h>

@interface TestRoot : NSObject @end
@implementation TestRoot
@end

@interface Super1 : TestRoot @end
@implementation Super1
+(int)classMethod { return 1; }
-(int)instanceMethod { return 10000; }
@end

@interface Super2 : TestRoot @end
@implementation Super2
+(int)classMethod { return 2; }
-(int)instanceMethod { return 20000; }
@end

@interface Sub : Super1 @end
@implementation Sub
+(int)classMethod {
	return [super classMethod] + 100;
}
-(int)instanceMethod { 
    return [super instanceMethod] + 1000000;
}
@end

int main()
{
    Class cls;
    Sub *obj = [Sub new];

	/*
	uint count;
	Class superClass = class_getSuperclass([Sub class]);
	Method *methods = class_copyMethodList(superClass, &count);
	printf("%d\n",count);
	for(uint i = 0; i < count; i++) {
		printf("%s\n",sel_getName(method_getName(methods[i])));
		IMP imp = method_getImplementation(methods[i]);
		printf("imp=%d\n",imp);
		int ret = imp(superClass, method_getName(methods[i]));
		//printf("ret=%d\n",ret);
	}
	printf("Sub=%d\n", objc_getClass("Sub"));
	printf("class=%d\n",[Sub classMethod]);
	printf("obj=%d\n", obj);
	printf("obj isa=%d\n", *((int*)obj));
	printf("obj isa isa=%d\n", *((int*)((int*)obj)));
	printf("[Sub class]=%d\n", [Sub class]);
	printf("[[Sub class] class]=%d\n", [[Sub class] class]);
	printf("[Super1 class]=%d\n", [Super1 class]);
	printf("[obj class]=%d\n", [obj class]);
	*/

    assert(101 == [Sub classMethod]);
    assert(101 == [[Sub class] classMethod]);
    assert(1010000 == [obj instanceMethod]);

    cls = class_setSuperclass([Sub class], [Super2 class]);

    assert(cls == [Super1 class]);
    assert(object_getClass(cls) == object_getClass([Super1 class]));

	assert(102 == [[Sub class] classMethod]);
    assert(1020000 == [obj instanceMethod]);
}
