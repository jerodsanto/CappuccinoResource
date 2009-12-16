@import <Foundation/CPString.j>
@import <Foundation/CPURLConnection.j>
@import <Foundation/CPURLRequest.j>

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

/* Cappuccino expects strings to be camelized with a lowercased first letter.
 * eg - userSession, movieTitle, createdAt, etc.
 * Always use this format when declaring ivars.
*/
- (CPString)cappifiedString
{
    var str=self.toLowerCase();
    var str_path=str.split('/');
    for(var i=0;i<str_path.length;i++) {
      var str_arr=str_path[i].split('_');
      var initX=((true&&i+1==str_path.length)?(1):(0));
      for(var x=initX;x<str_arr.length;x++)
        str_arr[x]=str_arr[x].charAt(0).toUpperCase()+str_arr[x].substring(1);
      str_path[i]=str_arr.join('');
    }
    str=str_path.join('::');
    return str;
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
