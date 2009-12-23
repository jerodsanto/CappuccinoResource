// import all the necessary stuff to run tests
@import <OJMoq/OJMoq.j>
@import "../Framework/CRBase.j"
// define some classes which inherit from CR to use in testing

@implementation User : CappuccinoResource
{
    CPString  email       @accessors;
    CPString  password    @accessors;
    int       age         @accessors;
}

- (JSObject)attributes
{
    return {'email':email,'password':password, 'age':age};
}

@end

@implementation UserSession : CappuccinoResource
{
    CPString userName  @accessors;
    CPDate   startDate @accessors;
}

- (JSObject)attributes
{
    return {'user_name':userName,'start_date':[startDate toDateString]};
}


+ (CPString)identifierKey
{
    return @"token";
}

@end
