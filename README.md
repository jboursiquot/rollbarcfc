RollbarCFC
===
This project was created out of my need to go beyond tailing ColdFusion's server log files and using the CF Administrator's constrained log viewer to troubleshoot some legacy ColdFusion apps. I chose Rollbar because of its feature set and ease of integration via its REST API. If you're unfamiliar with Rollbar, check out http://rollbar.com. While they had libraries for the majority of popular languages used today, ColdFusion was not among them, hence this project.

## Setup
The quickest way to get things rolling is to clone this repo in your webroot where it will be available from http://hostname/rollbarcfc. Alternatively, you have the flexibility of setting up a mapping to the **rollbarcfc** directory anywhere on your filesystem. As long as CF can find and instantiate **rollbarcfc.components.Rollbar**, you're good to go.

It is recommended that you also set up the CFML asynchronous gateway using the **rollbarcfc.components.RollbarAsyncGateway** component. This will allow you to hand off remote logging to a separate thread so that your users don't have to wait for the HTTP requests out to Rollbar to complete before your server can respond to their requests.

## Access Token
You'll need an access token to successfully submit data over Rollbar's API. There are several tokens Rollbar makes available but you'll want the one identified as **post_server_item**.

## Usage
Rollbar allows you to track both messages and exceptions. The following examples show you the various types of messages that can be sent using the primary methods exposed through this project. Examples that make use of the asynchronous gateway are further below.

### Logging Messages

```java
// Initialization requires a struct with access_token at the minimum
conf = {
  "access_token" = "super_secret", // your post_server_item token
  "environment" = "staging" // defaults to "development"
  "use_ssl" = "false" // defaults to true, recommended
};
  
// Instantiate with the parameters above
rollbar = CreateObject("component","rollbarcfc.components.Rollbar").init(conf);

// Use the reportMessage method
rollbar.reportMessage("Info Message");

// You can pass in arbitrary metadata in the form of a struct
rollbar.reportMessage("Debug Message", "debug", {"metadata" = "anything"});

// The second parameter is the level (e.g. info, debug, warning, error, critical). Defaults to info.
rollbar.reportMessage("Error Message", "error");

// You can pass in some info on the user making the request. 
// The "id" is required. Keep it consistent per user and Rollbar will give you a history of events per user. 
// ID can be any string (up to 40 characters), so you can use the username as the id as well.
user = {
  "id" = "12345",
  "username" = "a.user", 
  "email" = "a.user@domain.com"
};

rollbar.reportMessage("Warning Message", "warning", {"metadata" = "anything"}, user);

// Metadata can be omitted as well while still sending user data
rollbar.reportMessage("Critical Message", "critical", {}, user);
```

### Logging Exceptions
Easiest way to demonstrate the capture and logging of an exception is to use try/catch and call on Rollbar in the catch block.

```java
try{
  throw(type="FakeError", message="This fake error message");
}catch(any e){
  rollbar.reportException(e);
}
```

### Logging Messages Asynchronously

```java
// Initialization requires a struct with access_token at the minimum
conf = {
  "access_token" = "super_secret", // your post_server_item token
  "environment" = "staging" // defaults to "development"
  "use_ssl" = "false" // defaults to true, recommended
};
  
// Instantiate with the parameters above
rollbar = CreateObject("component","rollbarcfc.components.Rollbar").init(conf);

// We need to provide the async gateway with both token and payload in a single struct
data = {
  "api_endpoint" = rollbar.getAPIEndpoint(),
  "payload" = rollbar.getPreparedMessagePayload("Async Gateway Debug Message")
};

// Assuming our gateway instance ID's been set to "Rollbar"...
SendGatewayMessage("Rollbar", data);

// You see ColdFusion log the HTTP requests out to console or its http.log log file.
```

### Logging Exceptions Asynchronously

```java
// Initialization requires a struct with access_token at the minimum
conf = {
  "access_token" = "super_secret", // your post_server_item token
  "environment" = "staging" // defaults to "development"
  "use_ssl" = "false" // defaults to true, recommended
};
  
// Instantiate with the parameters above
rollbar = CreateObject("component","rollbarcfc.components.Rollbar").init(conf);

try{
  throw(type="FakeError", message="Async Gateway Error");
}catch(any e){

  // We need to provide the async gateway with both token and payload in a single struct
  data = {
    "api_endpoint" = rollbar.getAPIEndpoint(),
    "payload" = rollbar.getPreparedExceptionPayload(e, "error")
  };

  // Assuming our gateway instance ID's been set to "Rollbar"...
  SendGatewayMessage("Rollbar", data);
}

// You see ColdFusion log the HTTP requests out to console or its http.log log file.
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes with tests(`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Note that you'll need MXUnit (http://mxunit.org/) installed and accessible from your webroot to run the unit tests. Apache Ant (http://ant.apache.org/) is also used from the command line to trigger the tests and see the results in your default browser.
