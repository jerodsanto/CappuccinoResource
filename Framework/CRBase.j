@import <Foundation/CPObject.j>
@import "CRSupport.j"

var defaultIdentifierKey = @"id";

@implementation CappuccinoResource : CPObject
{
    CPString identifier @accessors;
    CPArray  attributeNames;
}

// override this method to use a custom identifier for lookups
+ (CPString)identifierKey
{
    return defaultIdentifierKey;
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
    var msg = 'This method must be declared in your subclass.';
    CPLog.warn(msg);
    console.log(msg);
    return {};
}

// switch to this if we can get attribute types
// + (CPDictionary)attributes
// {
//     var array = class_copyIvarList(self),
//         dict  = [[CPDictionary alloc] init];
//
//     for (var i = 0; i < array.length; i++)
//         CPLog.warn(array[i]);
//         [dict setObject:array[i].type forKey:array[i].name];
//     return dict;
// }

/*
 * I'd like to find a way to store attributeNames in a class variable
 * instead of an instance variable, but I can't seem to use a file-scoped
 * variable because they are not accessible by subclasses.
*/
- (CPArray)attributeNames
{
    if (attributeNames)
        return attributeNames;

    attributeNames = [CPArray array];
    var array = class_copyIvarList([self class]);
    for (var i = 0; i < array.length; i++) {
        [attributeNames addObject:array[i].name];
    }

    return attributeNames;
}

- (void)setAttributes:(JSObject)attributes
{
    for (var attribute in attributes) {
        if (attribute == [[self class] identifierKey]) {
            [self setIdentifier:attributes[attribute].toString()];
        } else {
            var attributeName = [attribute cappifiedString];
            if ([[self attributeNames] containsObject:attributeName]) {
                var value = attributes[attribute];
                /*
                 * I would much rather retrieve the ivar class than pattern match the
                 * response from Rails, but objective-j does not support this.
                */
                switch (typeof value) {
                    case "number":
                        [self setValue:value forKey:attributeName];
                        break;
                    case "string":
                        if (value.match(/^\d{4}-\d{2}-\d{2}$/)) {
                            // its a date
                            [self setValue:[CPDate dateWithDateString:value] forKey:attributeName];
                        } else if (value.match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/)) {
                            // its a datetime
                            [self setValue:[CPDate dateWithDateTimeString:value] forKey:attributeName];
                        } else {
                            // its a string
                            [self setValue:value forKey:attributeName];
                        }
                        break;
                }
            }
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
        [self resourceDidNotSave:response[1]];
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
        [self resourceDidDestroy];
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
    var path             = [self resourcePath] + "/" + identifier,
        notificationName = [self className] + "ResourceWillSave";

    if (!path)
        return nil;

    var request = [CPURLRequest requestJSONWithURL:path];
    [request setHTTPMethod:@"GET"];

    [[CPNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
    return request;
}

+ (id)resourceDidLoad:(CPString)aResponse
{
    var response         = [aResponse toJSON],
        attributes       = response[[self railsName]],
        notificationName = [self className] + "ResourceDidLoad",
        resource         = [self new];

    [resource setAttributes:attributes];
    [[CPNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
    return resource;
}

+ (CPURLRequest)collectionWillLoad
{
    return [self collectionWillLoad:nil];
}

// can handle a JSObject or a CPDictionary
+ (CPURLRequest)collectionWillLoad:(id)params
{
    var path             = [self resourcePath],
        notificationName = [self className] + "CollectionWillLoad";

    if (params) {
        if (params.isa && [params isKindOfClass:CPDictionary]) {
            path += ("?" + [CPString paramaterStringFromCPDictionary:params]);
        } else {
            path += ("?" + [CPString paramaterStringFromJSON:params]);
        }
    }

    if (!path) {
        return nil;
    }

    var request = [CPURLRequest requestJSONWithURL:path];
    [request setHTTPMethod:@"GET"];

    [[CPNotificationCenter defaultCenter] postNotificationName:notificationName object:self];

    return request;
}

+ (CPArray)collectionDidLoad:(CPString)aResponse
{
    var collection       = [aResponse toJSON],
        resourceArray    = [CPArray array],
        notificationName = [self className] + "CollectionDidLoad";

    for (var i = 0; i < collection.length; i++) {
        var resource = collection[i];
        var attributes = resource[[self railsName]];
        [resourceArray addObject:[self new:attributes]];
    }

    [[CPNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
    return resourceArray;
}

- (CPURLRequest)resourceWillSave
{
    var path             = [[self class] resourcePath],
        notificationName = [self className] + "ResourceWillSave";

    if (identifier)
        path += "/" + identifier;

    if (!path)
        return nil;

    var request = [CPURLRequest requestJSONWithURL:path];

    [request setHTTPMethod:identifier ? @"PUT" : @"POST"];
    [request setHTTPBody:[CPString JSONFromObject:[self attributes]]];

    [[CPNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
    return request;
}

- (void)resourceDidSave:(CPString)aResponse
{
    var response         = [aResponse toJSON],
        attributes       = response[[[self class] railsName]],
        notificationName = [self className] + "ResourceDidSave";

    [self setAttributes:attributes];
    [[CPNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
}

- (void)resourceDidNotSave:(CPString)aResponse
{
    // TODO - do something with errors
    var notificationName = [self className] + "ResourceDidNotSave";
    [[CPNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
}

- (CPURLRequest)resourceWillDestroy
{
    var path             = [[self class] resourcePath] + "/" + identifier,
        notificationName = [self className] + "ResourceWillDestroy";

    if (!path)
        return nil;

    var request = [CPURLRequest requestJSONWithURL:path];
    [request setHTTPMethod:@"DELETE"];

    [[CPNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
    return request;
}

-(void)resourceDidDestroy
{
    var notificationName = [self className] + "ResourceDidDestroy";
    [[CPNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
}

@end
