# CappuccinoResource #

It's like ActiveResource for your Cappuccino project!

## About ##

## Usage ##

First, create a class which inherits from CappuccinoResource:

    @implementation Post : CappuccinoResource
    {
        CPString title @accessors;
        CPString body  @accessors;
    }

    - (JSObject)attributes
    {
        return {"title":title, "body":body};
    }

The `attributes` instance method MUST be declared in your class for it to save properly. Using your new class should feel familiar to Rails devs.

### CRUD ###

Instanciate a blank Post object

    var post = [Post new];

Or declare some attributes at the same time. JSON feels like Ruby hashes!

    var post = [Post new:{"title":"First Post!","body":"Lorem and stuff"}];

Just like in ActiveResource, create = new + save

    var post = [Post create:{"title":"First Post!","body":"Lorem and stuff"}];

Get all the posts from Rails

    var posts = [Post all];
    [posts class]; // CPArray
    [[posts objectAtIndex:0] class]; // Post

You can fetch a resource with its identifier...

    var post = [Post find:@"4"];

Change its title...

    [post setTitle:@"Shiny New Name"];

And save it in your Rails back-end.

    [post save];

Deleting is just as easy

    [post destroy];

### More Advanced Finds ###

You can also run find with JSON paramaters

    var myPost = [Post findWithParams:{"title":"Oh Noes!"}];
    [myPost class]; // Post

Or the same thing with a collection

    var posts = [Post allWithParams:{"body":"happy"}];
    [posts class]; // CPArray
    [[posts objectAtIndex:0] class]; // Post

The paramater JSObject will get serialized and be available to your Rails controller's `params` hash. It's up to Rails to return the appropriate records.

Installation
------------

Contributing
------------

Credit
------

Future Features
---------------
* Validations
* Infer attributes from instance vars?
* Nested Models
