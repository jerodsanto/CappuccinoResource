@import "TestHelper.j"

var userResourceJSON   = '{"user":{"id":1,"email":"test@test.com","password":"secret"}}',
    userCollectionJSON = '[{"user":{"id":1,"email":"one@test.com"}},' +
                          '{"user":{"id":2,"email":"two@test.com"}},' +
                          '{"user":{"id":3,"email":"three@test.com"}}]';


@implementation CRBaseTest : OJTestCase

- (void)setUp
{
    user    = [[User alloc] init];
    session = [[UserSession alloc] init];
    // mock network connections
    oldCPURLConnection = CPURLConnection;
    CPURLConnection = moq();
    // setup an obvserver
    observer = [[Observer alloc] init];
}

- (void)tearDown
{
    // destroy mock
    [CPURLConnection verifyThatAllExpectationsHaveBeenMet];
    CPURLConnection = oldCPURLConnection;
}

- (void)testIdentifierKey
{
    [self assert:@"id" equals:[User identifierKey]];
    [self assert:@"token" equals:[UserSession identifierKey]];
}

- (void)testResourcePath
{
    [self assert:[CPURL URLWithString:@"/users"] equals:[User resourcePath]];
    [self assert:[CPURL URLWithString:@"/user_sessions"] equals:[UserSession resourcePath]];
}

- (void)testAttributes
{
    var expected = '{"email":"test@test.com","password":"secret","age":27}';
    [user setEmail:@"test@test.com"];
    [user setPassword:@"secret"];
    [user setAge:27];
    [self assert:expected equals:JSON.stringify([user attributes])];
}

- (void)testAttributeNames
{
    [self assert:["email","password","age","isAlive"] equals:[user attributeNames]];
    [self assert:["userName","startDate"] equals:[session attributeNames]];
}

- (void)testSetAttributes
{
    var atts1 = {"email":"test@test.com", "password":"secret", "id":12, "age":24, "is_alive":true},
        atts2 = {"token":"8675309", "user_name":"dorky", "ignore":"this","start_date":"2009-12-19"},
        atts3 = {"token":"8675309", "user_name":"dorky", "start_date":"2007-04-01T12:34:31Z"}

    [user setAttributes:atts1];
    [self assert:@"test@test.com" equals:[user email]];
    [self assert:@"secret" equals:[user password]];
    [self assert:@"12" equals:[user identifier]];
    [self assert:24 equals:[user age]];
    [self assert:true equals:[user isAlive]];

    [session setAttributes:atts2];
    [self assert:@"dorky" equals:[session userName]];
    [self assert:@"8675309" equals:[session identifier]];
    [self assert:2009 equals:[[session startDate] year]];
    [self assert:12 equals:[[session startDate] month]];
    [self assert:19 equals:[[session startDate] day]];

    [session setAttributes:atts3];
    [self assert:2007 equals:[[session startDate] year]];
    [self assert:4 equals:[[session startDate] month]];
    [self assert:1 equals:[[session startDate] day]];
}

- (void)testNewSansAttributes
{
    tester1 = [User new];
    [self assert:User equals:[tester1 class]];
    [self assert:@"User" equals:[tester1 className]];
    [self assert:nil equals:[tester1 email]];
    [self assert:nil equals:[tester1 password]];

    tester2 = [UserSession new];
    [self assert:UserSession equals:[tester2 class]];
    [self assert:@"UserSession" equals:[tester2 className]];
    [self assert:nil equals:[tester2 userName]];
    [self assert:nil equals:[tester2 startDate]];
}

- (void)testNewWithAttributes
{
    tester1 = [User new:{"email":"test@test.com", "password":"secret"}];
    [self assert:User equals:[tester1 class]];
    [self assert:@"User" equals:[tester1 className]];
    [self assert:@"test@test.com" equals:[tester1 email]];
    [self assert:@"secret" equals:[tester1 password]];

    tester2 = [UserSession new:{"userName":"snoop", "startDate":"2009-04-05"}];
    [self assert:UserSession equals:[tester2 class]];
    [self assert:@"UserSession" equals:[tester2 className]];
    [self assert:@"snoop" equals:[tester2 userName]];
    [self assert:@"2009-04-05" equals:[[tester2 startDate] toDateString]];
}

- (void)testResourceWillSaveWithNewResource
{
    [observer startObserving:@"UserResourceWillSave"];
    [observer startObserving:@"UserResourceWillCreate"];
    var request = [user resourceWillSave], url = [request URL];
    [self assert:@"POST" equals:[request HTTPMethod]];
    [self assert:@"/users" equals:[url absoluteString]];
    [self assertTrue:[observer didObserve:@"UserResourceWillSave"]];
    [self assertTrue:[observer didObserve:@"UserResourceWillCreate"]];
    [self assertFalse:[observer didObserve:@"UserResourceWillUpdate"]];
}

- (void)testResourceWillSaveWithExistingResource
{
    [observer startObserving:@"UserResourceWillSave"];
    [observer startObserving:@"UserResourceWillUpdate"];
    [user setIdentifier:@"42"];
    var request = [user resourceWillSave], url = [request URL];
    [self assert:@"PUT" equals:[request HTTPMethod]];
    [self assert:@"/users/42" equals:[url absoluteString]];
    [self assertTrue:[observer didObserve:@"UserResourceWillSave"]];
    [self assertTrue:[observer didObserve:@"UserResourceWillUpdate"]];
    [self assertFalse:[observer didObserve:@"UserResourceWillCreate"]];
}

- (void)testSuccessfulSaveWithNewResource
{
    [observer startObserving:@"UserResourceDidSave"];
    [observer startObserving:@"UserResourceDidCreate"];
    var response = [201, userResourceJSON];
    [CPURLConnection selector:@selector(sendSynchronousRequest:) returns:response];
    [self assertTrue:[user save]];
    [self assertTrue:[observer didObserve:@"UserResourceDidSave"]];
    [self assertTrue:[observer didObserve:@"UserResourceDidCreate"]];
}

- (void)testFailedSaveWithNewResource
{
    [observer startObserving:@"UserResourceDidNotSave"];
    [observer startObserving:@"UserResourceDidNotCreate"];
    var response = [422,'["email","already in use"]'];
    [CPURLConnection selector:@selector(sendSynchronousRequest:) returns:response];
    [self assertFalse:[user save]];
    [self assertTrue:[observer didObserve:@"UserResourceDidNotSave"]];
    [self assertTrue:[observer didObserve:@"UserResourceDidNotCreate"]];
}

- (void)testSuccessfulCreate
{
    [observer startObserving:@"UserResourceDidSave"];
    [observer startObserving:@"UserResourceDidCreate"];
    var response = [201,userResourceJSON];
    [CPURLConnection selector:@selector(sendSynchronousRequest:) returns:response];
    var result = [User create:{"email":"test@test.com", "password":"secret"}];
    [self assert:@"1" equals:[result identifier]];
    [self assert:@"test@test.com" equals:[result email]];
    [self assert:@"secret" equals:[result password]];
    [self assertTrue:[observer didObserve:@"UserResourceDidSave"]];
    [self assertTrue:[observer didObserve:@"UserResourceDidCreate"]];
}

- (void)testFailedCreate
{
    [observer startObserving:@"UserResourceDidNotSave"];
    [observer startObserving:@"UserResourceDidNotCreate"];
    var response = [422,'["email","already in use"]'];
    [CPURLConnection selector:@selector(sendSynchronousRequest:) returns:response];
    var result = [User create:{"email":"test@test.com", "password":"secret"}];
    [self assertNull:result];
    [self assertTrue:[observer didObserve:@"UserResourceDidNotSave"]];
    [self assertTrue:[observer didObserve:@"UserResourceDidNotCreate"]];
}

- (void)testDestroy
{
    [observer startObserving:@"UserResourceDidDestroy"];
    var response = [200,''];
    [CPURLConnection selector:@selector(sendSynchronousRequest:) returns:response];
    [self assertTrue:[user destroy]];
    [self assertTrue:[observer didObserve:@"UserResourceDidDestroy"]];
}

- (void)testResourceWillLoad
{
    [observer startObserving:@"UserResourceWillLoad"];
    var request = [User resourceWillLoad:@"42"], url = [request URL];
    [self assert:@"GET" equals:[request HTTPMethod]];
    [self assert:@"/users/42" equals:[url absoluteString]];
    [self assertTrue:[observer didObserve:@"UserResourceWillLoad"]];
}

- (void)testResourceDidLoad
{
    [observer startObserving:@"UserResourceDidLoad"];
    var response = userResourceJSON,
        resource = [User resourceDidLoad:response];
    [self assert:@"1" equals:[resource identifier]];
    [self assert:@"test@test.com" equals:[resource email]];
    [self assert:@"secret" equals:[resource password]];
    [self assertTrue:[observer didObserve:@"UserResourceDidLoad"]];
}

- (void)testFindingByIdentifierKey
{
    var response = [201,userResourceJSON];
    [CPURLConnection selector:@selector(sendSynchronousRequest:) returns:response];
    var result = [User find:@"1"];
    [self assert:@"1" equals:[result identifier]];
    [self assert:@"test@test.com" equals:[result email]];
    [self assert:@"secret" equals:[result password]];

    result = [User find:1];
    [self assert:@"1" equals:[result identifier]];
    [self assert:@"test@test.com" equals:[result email]];
    [self assert:@"secret" equals:[result password]];
}

- (void)testFindingWithParams
{
    var response = [201,userCollectionJSON];
    [CPURLConnection selector:@selector(sendSynchronousRequest:) returns:response];
    var result = [User findWithParams:{"email":"test"}];
    [self assert:@"1" equals:[result identifier]];
    [self assert:@"one@test.com" equals:[result email]];
}

- (void)testFindingAll
{
    var response = [201,userCollectionJSON];
    [CPURLConnection selector:@selector(sendSynchronousRequest:) returns:response];
    var results = [User all];
    [self assert:CPArray equals:[results class]];
    [self assert:@"1" equals:[[results objectAtIndex:0] identifier]];
    [self assert:@"2" equals:[[results objectAtIndex:1] identifier]];
    [self assert:@"3" equals:[[results objectAtIndex:2] identifier]];
    [self assert:@"one@test.com" equals:[[results objectAtIndex:0] email]];
    [self assert:@"two@test.com" equals:[[results objectAtIndex:1] email]];
    [self assert:@"three@test.com" equals:[[results objectAtIndex:2] email]];
}

- (void)testFindingAllWithParams
{
    var response = [201,userCollectionJSON];
    [CPURLConnection selector:@selector(sendSynchronousRequest:) returns:response];
    var results = [User allWithParams:{"email":"test"}];
    [self assert:CPArray equals:[results class]];
    [self assert:@"1" equals:[[results objectAtIndex:0] identifier]];
    [self assert:@"2" equals:[[results objectAtIndex:1] identifier]];
    [self assert:@"3" equals:[[results objectAtIndex:2] identifier]];
    [self assert:@"one@test.com" equals:[[results objectAtIndex:0] email]];
    [self assert:@"two@test.com" equals:[[results objectAtIndex:1] email]];
    [self assert:@"three@test.com" equals:[[results objectAtIndex:2] email]];
}

- (void)testCollectionWillLoad
{
    [observer startObserving:@"UserCollectionWillLoad"];
    var request = [User collectionWillLoad], url = [request URL];
    [self assert:@"GET" equals:[request HTTPMethod]];
    [self assert:@"/users" equals:[url absoluteString]];
    [self assertTrue:[observer didObserve:@"UserCollectionWillLoad"]];
}

- (void)testCollectionWillLoadWithOneJSObjectParam
{
    [observer startObserving:@"UserCollectionWillLoad"];
    var request = [User collectionWillLoad:{"password":"secret"}], url = [request URL];
    [self assert:@"GET" equals:[request HTTPMethod]];
    [self assert:@"/users?password=secret" equals:[url absoluteString]];
    [self assertTrue:[observer didObserve:@"UserCollectionWillLoad"]];
}

- (void)testCollectionWillLoadWithMultipleJSObjectParams
{
    [observer startObserving:@"UserCollectionWillLoad"];
    var request = [User collectionWillLoad:{"name":"joe blow","password":"secret"}], url = [request URL];
    [self assert:@"GET" equals:[request HTTPMethod]];
    [self assert:@"/users?name=joe%20blow&password=secret" equals:[url absoluteString]];
    [self assertTrue:[observer didObserve:@"UserCollectionWillLoad"]];
}

- (void)testCollectionWillLoadWithCPDictionary
{
    [observer startObserving:@"UserCollectionWillLoad"];
    var params  = [CPDictionary dictionaryWithJSObject:{"name":"joe blow","password":"secret"}],
        request = [User collectionWillLoad:params],
        url     = [request URL];
    [self assert:@"GET" equals:[request HTTPMethod]];
    [self assert:@"/users?name=joe%20blow&password=secret" equals:[url absoluteString]];
    [self assertTrue:[observer didObserve:@"UserCollectionWillLoad"]];
}

- (void)testCollectionDidLoad
{
    [observer startObserving:@"UserCollectionDidLoad"];
    var response   = userCollectionJSON,
        collection = [User collectionDidLoad:response];
    [self assert:CPArray equals:[collection class]];
    [self assert:User equals:[[collection objectAtIndex:0] class]];
    [self assert:@"1" equals:[[collection objectAtIndex:0] identifier]];
    [self assert:@"2" equals:[[collection objectAtIndex:1] identifier]];
    [self assert:@"3" equals:[[collection objectAtIndex:2] identifier]];
    [self assert:@"one@test.com" equals:[[collection objectAtIndex:0] email]];
    [self assert:@"two@test.com" equals:[[collection objectAtIndex:1] email]];
    [self assert:@"three@test.com" equals:[[collection objectAtIndex:2] email]];
    [self assertTrue:[observer didObserve:@"UserCollectionDidLoad"]];
}

@end
