component extends="TestHelper" output="false"
{

	public RollbarTest function init(){return this;}

	public void function setUp()
  {
    super.setup();
    this.rollbar = getInitializedRollbar();
  }

	public void function tearDown(){super.tearDown();}

  public void function testReportMessage()
  {
    local.message = getSampleMessage();
    local.result = this.rollbar.reportMessage(argumentCollection = local.message);
    assertTrue(local.result, "Expected true");
  }

  public void function testReportException()
  {
    local.exception = getSampleException();
    local.result = this.rollbar.reportException(argumentCollection = local.exception);
    assertTrue(local.result, "Expected true");
  }

  public void function testGetPreparedMessagePayload()
  {
    local.message = getSampleMessage();
    local.payload = this.rollbar.getPreparedMessagePayload(argumentCollection = local.message);
    assertTrue(IsJSON(local.payload), "Expected JSON");
  }

  public void function testGetPreparedExceptionPayload()
  {
    local.exception = getSampleException();
    local.rollbar = getInitializedRollbar(this.access_token);
    local.payload = this.rollbar.getPreparedExceptionPayload(argumentCollection = local.exception);
    assertTrue(IsJSON(local.payload), "Expected JSON");
  }

}
