@import <Foundation/CPDate.j>
@import <Foundation/CPString.j>
@import <Foundation/CPURLConnection.j>
@import <Foundation/CPURLRequest.j>

@implementation CPDate (CRSupport)

+ (CPDate)dateWithDateString:(CPString)aDate
{
    return [[self alloc] initWithString:aDate + " 12:00:00 +0000"];
}

+ (CPDate)dateWithDateTimeString:(CPString)aDateTime
{
    var format = /^(\d{4}-\d{2}-\d{2})T(\d{2}:\d{2}:\d{2})Z$/,
        d      = aDateTime.match(new RegExp(format)),
        string = d[1] + " " + d[2] + " +0000";

    return [[self alloc] initWithString:string];
}

- (int)year
{
    return self.getFullYear();
}

- (int)month
{
    return self.getMonth() + 1;
}

- (int)day
{
    return self.getDate();
}

- (CPString)toDateString
{
    return [CPString stringWithFormat:@"%04d-%02d-%02d", [self year], [self month], [self day]];
}


@end

@implementation CPString (CRSupport)

+ (CPString)paramaterStringFromJSON:(JSObject)params
{
    paramsArray = [CPArray array];
    for (var param in params)
        [paramsArray addObject:(escape(param) + "=" + escape(params[param]))];

    return paramsArray.join("&");
}

/* Rails expects strings to be lowercase and underscored.
 * eg - user_session, movie_title, created_at, etc.
 * Always use this format when sending data to Rails
*/
- (CPString)railsifiedString
{
    var str=self;
    var str_path=str.split('::');
    var upCase=new RegExp('([ABCDEFGHIJKLMNOPQRSTUVWXYZ])','g');
    var fb=new RegExp('^_');
    for(var i=0;i<str_path.length;i++)
      str_path[i]=str_path[i].replace(upCase,'_$1').replace(fb,'');
    str=str_path.join('/').toLowerCase();
    return str;
}

/*
 * Cappuccino expects strings to be camelized with a lowercased first letter.
 * eg - userSession, movieTitle, createdAt, etc.
 * Always use this format when declaring ivars.
*/
- (CPString)cappifiedString
{
    var string = self.charAt(0).toLowerCase() + self.substring(1);
    var array  = string.split('_');
    for (var x = 1; x < array.length; x++) // skip first word
        array[x] = array[x].charAt(0).toUpperCase() +array[x].substring(1);
    string = array.join('');
    return string;
}

- (JSObject)toJSON
{
    var str=self;
    try {
        var obj = JSON.parse(str);
    }
    catch (anException) {
        CPLog.warn(@"Could not convert to JSON: " + str);
    }

    if (obj)
        return obj;
}

@end

@implementation CPURLConnection (CRSupport)

// Works just like built-in method, but returns CPArray instead of CPData.
// First value in array is HTTP status code, second is data string.
+ (CPArray)sendSynchronousRequest:(CPURLRequest)aRequest
{
    try {
        var request = objj_request_xmlhttp();

        request.open([aRequest HTTPMethod], [[aRequest URL] absoluteString], NO);

        var fields = [aRequest allHTTPHeaderFields],
            key = nil,
            keys = [fields keyEnumerator];

        while (key = [keys nextObject])
            request.setRequestHeader(key, [fields objectForKey:key]);

        request.send([aRequest HTTPBody]);

        return [CPArray arrayWithObjects:request.status, request.responseText];
     }
     catch (anException) {}
     return nil;
}

@end

@implementation CPURLRequest (CRSupport)

+ (id)requestJSONWithURL:(CPURL)aURL
{
    var request = [self requestWithURL:aURL];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    return request;
}

@end
