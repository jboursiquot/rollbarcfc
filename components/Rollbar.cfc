component output="false"
{
  variables.access_token = "";
  variables.use_ssl_endpoint = true;
  variables.api_endpoint_ssl = "https://api.rollbar.com/api/1/item/";
  variables.api_endpoint = "http://api.rollbar.com/api/1/item/";
  variables.environment = "development";

	public Rollbar function init(required struct conf)
  {
    try{
      validateConf(arguments.conf);
      setAccessToken(arguments.conf);
      setAPIEndpoint(arguments.conf);
      setEnvironment(arguments.conf);
    }catch(any e){
      toConsole(arguments, {}, e);
      rethrow;
    }
    return this;
  }

  public boolean function reportMessage(
      required string message,
      string level = "info",
      struct meta = StructNew(),
      struct user = StructNew())
  {
    try{
      local.payload = getPreparedMessagePayload(arguments.message, arguments.level, arguments.meta, arguments.user);
      sendPayload(local.payload);
      return true;
    }catch(any e){
      toConsole(arguments, local, e);
      return false;
    }
  }

  public boolean function reportException(
      required any exception,
      string level = "error",
      struct user = StructNew())
  {
    try{
      local.payload = getPreparedExceptionPayload(arguments.exception, arguments.level, arguments.user);
      sendPayload(local.payload);
      return true;
    }catch(any e){
      toConsole(arguments, local, e);
      return false;
    }
  }

  public string function getPreparedMessagePayload(
      required string message,
      string level = "info",
      struct meta = StructNew(),
      struct user = StructNew())
  {
    local.payload = preparePayload(arguments.level, arguments.user);
    local.payload["data"]["body"]["message"] = {"body" = arguments.message};
    StructAppend(local.payload["data"]["body"]["message"], arguments.meta);
    return preparePayloadForTransmission(local.payload);
  }

  public string function getPreparedExceptionPayload(
      required any exception,
      string level = "error",
      struct user = StructNew())
  {
    local.payload = preparePayload(arguments.level, arguments.user);
    local.payload["data"]["body"]["trace"] = {};
    local.payload["data"]["body"]["trace"]["frames"] = getStackFramesForPayload(arguments.exception);
    local.payload["data"]["body"]["trace"]["exception"] = getExceptionParamsForPayload(arguments.exception);
    return preparePayloadForTransmission(local.payload);
  }

  private void function sendPayload(required string payload)
  {
    local.http = new HTTP();
    local.http.setMethod("POST");
    local.http.setUrl(getAPIEndpoint());
    local.http.addParam(type="formfield", name="payload", value="#arguments.payload#");
    local.response = local.http.send();

    if (local.response.getPrefix().statusCode != "200 OK"){
      throw(type="RollbarApiException", message = "Unsuccessful: #local.response.getPrefix().statusCode#");
    }
  }

  private array function getStackFramesForPayload(
      required any exception,
      string code_param = "",
      array context_pre = [],
      array context_post = [])
  {
    local.result = [];
    local.stack = getCurrentStackTrace();

    for (local.frame in local.stack){
      ArrayAppend(local.result, {
        "filename" = local.frame.template,
        "lineno" = local.frame.lineNumber,
        "method" = LCase(local.frame.function),
        "code" = arguments.code_param,
        "context" = getContextParamsForPayload(arguments.exception)
      });
    }

    return local.result;
  }

  private struct function getExceptionParamsForPayload(required any exception)
  {
    local.result = {
      "class" = arguments.exception.type,
      "message" = arguments.exception.message
    };

    return local.result;
  }

  private struct function getContextParamsForPayload(required any exception)
  {
    local.pre = [];
    for (local.context in arguments.exception.tagContext){
      for (local.key in ListToArray(StructKeyList(local.context))){
        ArrayAppend(local.pre, LCase(local.key) & " = " & local.context[local.key]);
      }
    }
    return {"pre" = local.pre,"post" = []};
  }

  // The following function was written by a different author and unfortunately
  // I cannot find the blog post anymore to give proper credit.
  private array function getCurrentStackTrace()
  {
    var lc = StructNew();
    lc.trace = CreateObject("java", "java.lang.Throwable").getStackTrace();
    lc.op = ArrayNew(1);
    lc.elCount = ArrayLen(lc.trace);
    for (lc.i = 1; lc.i Lte lc.elCount; lc.i = lc.i + 1) {
      if (ListFindNoCase('runPage,runFunction', lc.trace[lc.i].getMethodName())) {
        lc.info = StructNew();
        lc.info["Template"] = lc.trace[lc.i].getFileName();
        if (lc.trace[lc.i].getMethodName() Eq "runFunction") {
          lc.info["Function"] = ReReplace(lc.trace[lc.i].getClassName(), "^.+\$func", "");
        } else {
          lc.info["Function"] = "";
        }
        lc.info["LineNumber"] = lc.trace[lc.i].getLineNumber();
        ArrayAppend(lc.op, Duplicate(lc.info));
      }
    }
    // Remove the entry for this function
    ArrayDeleteAt(lc.op, 1);
    return lc.op;
  }

  private struct function preparePayload(string level = "info", user = StructNew())
  {
    try{
      local.payload = {};
      local.payload["access_token"] = getAccessToken();
      local.payload["data"] = {};
      local.payload["data"]["environment"] = getEnvironment();
      local.payload["data"]["level"] = arguments.level;
      local.payload["data"]["body"] = {};
      local.payload["data"]["request"] = getRequestParamsForPayload();
      local.payload["data"]["person"] = getUserParamsForPayload(arguments.user);
      local.payload["data"]["client"] = getClientParamsForPayload();
      local.payload["data"]["server"] = getServerParamsForPayload();
      local.payload["data"]["platform"] = getPlatformForPayload();
      local.payload["data"]["language"] = getLanguageForPayload();
      local.payload["data"]["notifier"] = getNotifierParamsForPayload();
      return local.payload;
    }catch(any e){
      toConsole(arguments, local, e);
    }
  }

  private struct function getRequestParamsForPayload()
  {
    local.reqData = GetHttpRequestData();
    local.result = {
      "url" = getRequestUrlFromCGI(),
      "method" = local.reqData.method,
      "headers" = local.reqData.headers,
      "get" = url,
      "query_string" = cgi.query_string,
      "post" = form,
      "body" = local.reqData.content,
      "user_ip" = cgi.remote_addr
    };
    return local.result;
  }

  private struct function getServerParamsForPayload()
  {
    return {
      "coldfusion" = server.coldfusion,
      "os" = server.os
    };
  }

  private string function getRequestUrlFromCGI()
  {
    local.result = cgi.server_name & cgi.script_name;
    if (cgi.server_port != 80 && cgi.server_port_secure){
      local.result = "https://" & local.result;
    }else{
      local.result = "http://" & local.result;
    }
    return local.result;
  }

  private struct function getUserParamsForPayload(struct user = StructNew())
  {
    if (!StructKeyExists(arguments.user, "id")) arguments.user["id"] = CreateUUID();
    if (!StructKeyExists(arguments.user, "username")) arguments.user["username"] = "anonymous@" & cgi.remote_host;
    if (!StructKeyExists(arguments.user, "email")) arguments.user["email"] = "anonymous@" & cgi.remote_host;
    return arguments.user;
  }

  private struct function getClientParamsForPayload()
  {
    return { "javascript" = { "browser" = cgi.http_user_agent } };
  }

  private struct function getNotifierParamsForPayload()
  {
    return { "name" = "RollbarCFC", "version" = "0.0.1" };
  }

  private string function getPlatformForPayload()
  {
    return server.coldfusion.productname & " " &
           server.coldfusion.productversion & " " &
           server.coldfusion.productlevel & " running on " &
           server.os.name & " " & server.os.version;
  }

  private string function getLanguageForPayload(){return "ColdFusion";}

  public string function getAPIEndpoint()
  {
    if (variables.use_ssl_endpoint){
      return variables.api_endpoint_ssl;
    }else{
      return variables.api_endpoint;
    }
  }

  private string function getAccessToken(){return variables.access_token;}
  private string function getEnvironment(){return variables.environment;}

  private string function preparePayloadForTransmission(required struct payload)
  {
    return SerializeJSON(arguments.payload);
  }

  private void function validateConf(required struct conf)
  {
    if(!StructKeyExists(arguments.conf, 'access_token'))
      throw(
          type = "RollbackInitException",
          message = "Initialization hash must contain an access_token"
      );
  }

  private void function setAccessToken(required struct conf)
  {
    if (StructKeyExists(arguments.conf, 'access_token'))
      variables.access_token = arguments.conf['access_token'];
  }

  private void function setAPIEndpoint(required struct conf)
  {
    if (StructKeyExists(arguments.conf, 'use_ssl'))
      variables.use_ssl_endpoint = arguments.conf['use_ssl'];
  }

  private void function setEnvironment(required struct conf)
  {
    if (StructKeyExists(arguments.conf, 'environment'))
      variables.environment = arguments.conf['environment'];
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
