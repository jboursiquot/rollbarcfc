<cfscript>

  try{
    conf = {"access_token" = "your-post-server-item-token-here", "use_ssl" = "false"};
    rollbar = CreateObject("component","rollbarcfc.components.Rollbar").init(conf);

    if (rollbar.reportMessage("Debug Message", "debug", {"metadata" = "anything"})) WriteOutput("Debug Message Success<br/>");
    if (rollbar.reportMessage("Info Message", "info", {"metadata" = "anything"})) WriteOutput("Info Message Success<br/>");
    if (rollbar.reportMessage("Error Message", "error", {"metadata" = "anything"})) WriteOutput("Error Message Success<br/>");
    if (rollbar.reportMessage("Warning Message", "warning", {"metadata" = "anything"})) WriteOutput("Warning Message Success<br/>");
    if (rollbar.reportMessage("Critical Message", "critical", {"metadata" = "anything"})) WriteOutput("Critical Message Success<br/>");

    user = {"id" = CreateUUID(), "username" = "a.user", "email" = "a.user@domain.com"};

    try{
      throw(type="FakeError", message="This fake error message #CreateUUID()#");
    }catch(any e){
      if (rollbar.reportException(e, "error", user)) WriteOutput("Exception Success<br/>");
    }

  }catch(any e){
    WriteDump(e);
  }

</cfscript>
