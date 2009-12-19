@import "TestHelper.j"

var userResourceJSON   = '{"user":{"id":1,"email":"test@test.com","password":"secret"}}';
var userCollectionJSON = '[{"user":{"id":1,"email":"one@test.com"}},' +
                          '{"user":{"id":2,"email":"two@test.com"}},' +
                          '{"user":{"id":3,"email":"three@test.com"}},]';


@implementation CRBaseTest : OJTestCase

- (void)setUp
{
    user    = [[User alloc] init];
    session = [[UserSession alloc] init];
    // mock network connections
    oldCPURLConnection = CPURLConnection;
    CPURLConnection = moq();
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
    [self assert:["email","password","age"] equals:[user attributeNames]];
    [self assert:["userName"] equals:[session attributeNames]];
}

- (void)testSetAttributes
{
    var atts1 = {"email":"test@test.com","password":"secret","id":12, "age":24},
        atts2 = {"token":"8675309","user_name":"dorky", "ignore":"this"};

    [user setAttributes:atts1];
    [self assert:@"test@test.com" equals:[user email]];
    [self assert:@"secret" equals:[user password]];
    [self assert:@"12" equals:[user identifier]];
    [self assert:24 equals:[user age]];

    [session setAttributes:atts2];
    [self assert:@"dorky" equals:[session userName]];
    [self assert:@"8675309" equals:[session identifier]];
}

- (void)testNewSansAttributes
{
    tester = [User new];
    [self assert:User equals:[tester class]];
    [self assert:@"User" equals:[tester className]];
    [self assert:nil equals:[tester email]];
    [self assert:nil equals:[tester password]];
}

- (void)testNewWithAttributes
{
    tester = [User new:{"email":"test@test.com", "password":"secret"}];
    [self assert:User equals:[tester class]];
    [self assert:@"User" equals:[tester className]];
    [self assert:@"test@test.com" equals:[tester email]];
    [self assert:@"secret" equals:[tester password]];
}

- (void)testResourceWillSaveWithNewResource
{
    var request = [user resourceWillSave], url = [request URL];
    [self assert:@"POST" equals:[request HTTPMethod]];
    [self assert:@"/users" equals:[url absoluteString]];
}

- (void)testResourceWillSaveWithExistingResource
{
    [user setIdentifier:@"42"];
    var request = [user resourceWillSave], url = [request URL];
    [self assert:@"PUT" equals:[request HTTPMethod]];
    [self assert:@"/users/42" equals:[url absoluteString]];
}

- (void)testSuccessfulSaveWithNewResource
{
    var response = [201, userResourceJSON];
    [CPURLConnection selector:@selector(sendSynchronousRequest:) returns:response];
    [self assertTrue:[user save]];
}

- (void)testFailedSaveWithNewResource
{
    var response = [422,'["email","already in use"]'];
    [CPURLConnection selector:@selector(sendSynchronousRequest:) returns:response];
    [self assertFalse:[user save]];
}

- (void)testSuccessfulCreate
{
    var response = [201,userResourceJSON];
    [CPURLConnection selector:@selector(sendSynchronousRequest:) returns:response];
    var result = [User create:{"email":"test@test.com", "password":"secret"}];
    [self assert:@"1" equals:[result identifier]];
    [self assert:@"test@test.com" equals:[result email]];
    [self assert:@"secret" equals:[result password]];
}

- (void)testFailedCreate
{
    var response = [422,'["email","already in use"]'];
    [CPURLConnection selector:@selector(sendSynchronousRequest:) returns:response];
    var result = [User create:{"email":"test@test.com", "password":"secret"}];
    [self assertNull:result];
}

- (void)testDestroy
{
    var response = [200,''];
    [CPURLConnection selector:@selector(sendSynchronousRequest:) returns:response];
    [self assertTrue:[user destroy]];
}

- (void)testResourceWillLoad
{
    var request = [User resourceWillLoad:@"42"], url = [request URL];
    [self assert:@"GET" equals:[request HTTPMethod]];
    [self assert:@"/users/42" equals:[url absoluteString]];
}

- (void)testResourceDidLoad
{
    var response = userResourceJSON,
        resource = [User resourceDidLoad:response];
    [self assert:@"1" equals:[resource identifier]];
    [self assert:@"test@test.com" equals:[resource email]];
    [self assert:@"secret" equals:[resource password]];
}

- (void)testFindingByIdentifierKey
{
    var response = [201,userResourceJSON];
    [CPURLConnection selector:@selector(sendSynchronousRequest:) returns:response];
    var result = [User find:@"1"];
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
    var request = [User collectionWillLoad], url = [request URL];
    [self assert:@"GET" equals:[request HTTPMethod]];
    [self assert:@"/users" equals:[url absoluteString]];
}

- (void)testCollectionWillLoadWithOneParam
{
    var request = [User collectionWillLoad:{"password":"secret"}], url = [request URL];
    [self assert:@"GET" equals:[request HTTPMethod]];
    [self assert:@"/users?password=secret" equals:[url absoluteString]];
}

- (void)testCollectionWillLoadWithMultipleParams
{
    var request = [User collectionWillLoad:{"name":"joe blow","password":"secret"}], url = [request URL];
    [self assert:@"GET" equals:[request HTTPMethod]];
    [self assert:@"/users?name=joe%20blow&password=secret" equals:[url absoluteString]];
}

- (void)testCollectionDidLoad
{
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
}

@end
