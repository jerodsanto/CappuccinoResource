// import all the necessary stuff to run tests
@import <OJMoq/OJMoq.j>
@import "../CappuccinoResource.j"
// define some classes which inherit from CR to use in testing

@implementation User : CappuccinoResource
{
    CPString  email       @accessors;
    CPString  password    @accessors;
}

- (JSObject)attributes
{
    return {'email':email,'password':password};
}

@end

@implementation UserSession : CappuccinoResource
{
    CPString userName @accessors;
}

- (JSObject)attributes
{
    return {'user_name':userName};
}


+ (CPString)identifierKey
{
    return @"token";
}

@end
