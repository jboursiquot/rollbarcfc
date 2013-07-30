component extends="mxunit.framework.TestCase"
{

	public TestHelper function init()
	{
		return this;
	}

	public void function setUp()
	{	
    this.access_token = "b8a6c72430414a8e910bfe9c1b28d5f1";
	}

	public void function tearDown()
	{
	}

  public any function getInitializedRollbar()
  {
    local.conf = {"access_token" = this.access_token, "use_ssl" = false};
    local.rollbar = CreateObject("component","rollbarcfc.components.Rollbar").init(local.conf);
    return local.rollbar;
  }

  public struct function getSampleMessage()
  {
    local.result = {};
    local.result.message = "Test message #CreateUUID()#";
    local.result.level = "info";
    local.result.meta = {};
    local.result.user = {};
    return local.result;
  }

  public struct function getSampleException()
  {
    local.result = {};
    local.result.level = "error";
    local.result.user = {};
    try{throw(type="CustomException", message="Test Exception #CreateUUID()#");}
    catch(any e){local.result.exception = e;}
    return local.result;
  }

}
