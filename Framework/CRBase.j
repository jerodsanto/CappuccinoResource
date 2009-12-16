@import <Foundation/CPObject.j>
@import "CRSupport.j"

var DefaultIdentifierKey = @"id";

@implementation CappuccinoResource : CPObject
{
    CPString identifier @accessors;
}

// override this method to use a custom identifier for lookups
+ (CPString)identifierKey
{
    return DefaultIdentifierKey;
}

// this provides very, very basic pluralization (adding an 's').
// override this method for more complex inflections
+ (CPURL)resourcePath
{
    return [CPURL URLWithString:@"/" + [self railsName] + @"s"];
}

+ (CPString)railsName
{
    return [[self className] railsifiedString];
}

- (JSObject)attributes
{
    console.log('This method must be declared in your subclass');
    return {};
}

- (void)setAttributes:(JSObject)attributes
{
    for (var attribute in attributes) {
        if (attribute == [[self class] identifierKey]) {
            [self setIdentifier:attributes[attribute].toString()];
        } else {
            [self setValue:attributes[attribute] forKey:[attribute cappifiedString]];
        }
    }
}

+ (id)new
{
    return [self new:nil];
}

+ (id)new:(JSObject)attributes
{
    var resource = [[self alloc] init];

    if (!attributes)
        attributes = {};

    [resource setAttributes:attributes];
    return resource;
}

+ (id)create:(JSObject)attributes
{
    var resource = [self new:attributes];
    if ([resource save])
        return resource;
    else
        return nil;
}

- (BOOL)save
{
    var request = [self resourceWillSave];
    if (!request)
        return NO;

    var response = [CPURLConnection sendSynchronousRequest:request];

    if (response[0] >= 400) {
        return NO;
    } else {
        [self resourceDidSave:response[1]];
        return YES;
    }
}

- (BOOL)destroy
{
    var request = [self resourceWillDestroy];
    if (!request)
        return NO;

    var response = [CPURLConnection sendSynchronousRequest:request];

    if (response[0] == 200) {
        return YES;
    } else {
        return NO;
    }
}

+ (CPArray)all
{
    var request = [self collectionWillLoad];
    if (!request)
        return NO;

    var response = [CPURLConnection sendSynchronousRequest:request];

    if (response[0] >= 400) {
        return nil;
    } else {
        return [self collectionDidLoad:response[1]];
    }
}

+ (CPArray)allWithParams:(JSObject)params
{
    var request = [self collectionWillLoad:params];

    var response = [CPURLConnection sendSynchronousRequest:request];

    if (response[0] >= 400) {
        return nil;
    } else {
        return [self collectionDidLoad:response[1]];
    }
}

+ (id)find:(CPString)identifier
{
    var request = [self resourceWillLoad:identifier];
    if (!request)
        return NO;

    var response = [CPURLConnection sendSynchronousRequest:request];

    if (response[0] >= 400) {
        return nil;
    } else {
        return [self resourceDidLoad:response[1]];
    }
}

+ (id)findWithParams:(JSObject)params
{
    var collection = [self allWithParams:params];
    return [collection objectAtIndex:0];
}

// All the following methods post notifications using their class name
// You can observe these notifications and take further action if desired
+ (CPURLRequest)resourceWillLoad:(CPString)identifier
{
    var path = [self resourcePath] + "/" + identifier,
        name = [self className] + "ResourceWillSave";

    if (!path)
        return nil;

    var request = [CPURLRequest requestJSONWithURL:path];
    [request setHTTPMethod:@"GET"];

    [[CPNotificationCenter defaultCenter] postNotificationName:name object:self];
    return request;
}

+ (id)resourceDidLoad:(CPString)aResponse
{
    var response    = [aResponse toJSON],
        attributes  = response[[self railsName]],
        name        = [self className] + "ResourceDidLoad",
        resource    = [self new];

    [resource setAttributes:attributes];
    [[CPNotificationCenter defaultCenter] postNotificationName:name object:self];
    return resource;
}

+ (CPURLRequest)collectionWillLoad
{
    return [self collectionWillLoad:nil];
}

+ (CPURLRequest)collectionWillLoad:(JSObject)params
{
    var path = [self resourcePath],
        name = [self className] + "CollectionWillLoad";

    if (params)
        path += ("?" + [CPString paramaterStringFromJSON:params]);

    if (!path)
        return nil;

    var request = [CPURLRequest requestJSONWithURL:path];
    [request setHTTPMethod:@"GET"];

    [[CPNotificationCenter defaultCenter] postNotificationName:name object:self];
    return request;
}

+ (CPArray)collectionDidLoad:(CPString)aResponse
{
    var collection    = [aResponse toJSON],
        resourceArray = [CPArray array],
        name          = [self className] + "CollectionDidLoad";

    for (var i = 0; i < collection.length; i++) {
        var resource = collection[i];
        var attributes = resource[[self railsName]];
        [resourceArray addObject:[self new:attributes]];
    }

    [[CPNotificationCenter defaultCenter] postNotificationName:name object:self];
    return resourceArray;
}

- (CPURLRequest)resourceWillSave
{
    var path = [[self class] resourcePath],
        name = [self className] + "ResourceWillSave";

    if (identifier)
        path += "/" + identifier;

    if (!path)
        return nil;

    var request = [CPURLRequest requestJSONWithURL:path];

    [request setHTTPMethod:identifier ? @"PUT" : @"POST"];
    [request setHTTPBody:[CPString JSONFromObject:[self attributes]]];

    [[CPNotificationCenter defaultCenter] postNotificationName:name object:self];
    return request;
}

- (void)resourceDidSave:(CPString)aResponse
{
    var response    = [aResponse toJSON],
        attributes  = response[[[self class] railsName]],
        name        = [self className] + "ResourceDidSave";

    [self setAttributes:attributes];
    [[CPNotificationCenter defaultCenter] postNotificationName:name object:self];
}

- (void)resourceDidNotSave:(CPString)aResponse
{
    // TODO - do something with errors
    var name = [self className] + "ResourceDidNotSave";
    [[CPNotificationCenter defaultCenter] postNotificationName:name object:self];
}

- (CPURLRequest)resourceWillDestroy
{
    var path = [[self class] resourcePath] + "/" + identifier,
        name = [self className] + "ResourceWillDestroy";

    if (!path)
        return nil;

    var request = [CPURLRequest requestJSONWithURL:path];
    [request setHTTPMethod:@"DELETE"];

    [[CPNotificationCenter defaultCenter] postNotificationName:name object:self];
    return request;
}

@end
