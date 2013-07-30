component output="false"
{

  public any function onIncomingMessage(required Struct event)
  {
    try{
      sendPreparedPayload(arguments.event.data);
    }catch(any e){
      toConsole(e.message);
    }
  }

  private void function sendPreparedPayload(required struct params)
  {
    local.http = new HTTP();
    local.http.setMethod("POST");
    local.http.setUrl(arguments.params["api_endpoint"]);
    local.http.addParam(type="formfield", name="payload", value="#arguments.params['payload']#");
    local.response = local.http.send();

    if (local.response.getPrefix().statusCode != "200 OK"){
      throw(type="RollbarApiException", message = "Unsuccessful: #local.response.getPrefix().statusCode#");
    }
  }

  private void function toConsole(args = "", local = "", exception = "")
  {
    WriteDump(
        var = {
          "arguments" = arguments.args,
          "local" = arguments.local,
          "exception" = arguments.exception
        },
        output='console'
    );
  }

}
