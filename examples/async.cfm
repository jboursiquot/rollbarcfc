<cfscript>
  // Assumes you've configured a CFML Asynchronous Gateway on your ColdFusion server

  conf = {"access_token" = "your-post-server-item-token-here", "use_ssl" = "false"};
  user = {"id" = CreateUUID(), "username" = "a.user", "email" = "a.user@domain.com"};
  rollbar = CreateObject("component","rollbarcfc.components.Rollbar").init(conf);

  try{
    mData = {
      "api_endpoint" = rollbar.getAPIEndpoint(),
      "payload" = rollbar.getPreparedMessagePayload("Async Gateway Debug Message #CreateUUID()#", "debug", {"type" = "debug"})
    };

    if (SendGatewayMessage("Rollbar", mData)) WriteOutput("Message Success<br/>");

  }catch(any e){
    WriteDump(e);abort;
  }

  try{

    throw(type="FakeError", message="Async Gateway Error #CreateUUID()#");

  }catch(any e){

    eData = {
      "api_endpoint" = rollbar.getAPIEndpoint(),
      "payload" = rollbar.getPreparedExceptionPayload(e, "error", user)
    };

    if (SendGatewayMessage("Rollbar", eData)) WriteOutput("Error Success<br/>");

  }
</cfscript>
