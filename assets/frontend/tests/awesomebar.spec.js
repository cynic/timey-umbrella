const {suite} = require('selenium-webdriver/testing');
const {By, Builder, Key, Browser, until} = require('selenium-webdriver');
const assert = require("assert");
const firefox = require('selenium-webdriver/firefox');
const LogInspector = require('selenium-webdriver/bidi/logInspector');

let sendKeysFast =
  async function(element, s) {
    await element.sendKeys(s);
  };

let sendKeysSlow =
  async function(element, s) {
    // convert 's' into an array of characters
    let chars = s.split('');
    // for each of the chars, do something
    chars.forEach(async function(c) {
      await element.sendKeys(c);
    });
  };

let sendKeys = sendKeysFast;

let checkAwesomebarMessage =
  async function(driver, send, expected) {
    await driver.actions().sendKeys(' ').perform();
    
    driver.wait(until.elementLocated(By.id('awesomebar')));

    var awesomebar = await driver.findElement(By.id('awesomebar'));

    await send(awesomebar);
    awesomebar = await driver.findElement(By.id('awesomebar'));
    await driver.wait(until.elementTextMatches(awesomebar, new RegExp(`.{${expected.length},}`)));
    let actual = await awesomebar.getText()
    assert.strictEqual(actual, expected);
    return new Promise((resolve) => { assert.ok(true); resolve(); });  };

suite(function(env) {
  let driver;

  before(async function() {
    this.timeout(10000);
    driver = await new Builder()
      .forBrowser(Browser.FIREFOX)
      .setFirefoxOptions(new firefox.Options().enableBidi())
      .build();
    await driver.manage().setTimeouts({implicit: 500});    
    await driver.get('http://localhost:4000/');

    let logEntry = null
    const inspector = await LogInspector(driver)
    await inspector.onConsoleEntry(
      (log) =>
        { console.log(`[${log.level}] ${log.text}`);
        }
    );

    let title = await driver.getTitle();
    assert.match(title, /Timely/);
  
    // are we on the login page??  If so, log in.
    let email = await driver.findElement(By.id('user_email'));
    if (email) { // then I'm actually at the login page
      await email.sendKeys('cinyc.s@gmail.com');
      let password = await driver.findElement(By.id('user_password'));
      await password.sendKeys('test123456789');
      let clicky = await driver.findElement(By.id('sign_in'));
      await clicky.click();

      driver.wait(until.urlIs('http://localhost:4000'));
    }
  });

  beforeEach(async function() {
    this.timeout(3500); // sometimes a bit slow.
    driver.get('http://localhost:4000/');
    return driver.wait(until.elementLocated(By.id('elm-app-container')));
  });

  after(async function() {
    this.timeout(10000);
    return driver.quit();
  });

  it("activates the awesomebar when space is pressed", async function() {
    // assert.rejects(await driver.findElement(By.id('awesomebar')));

    await driver.actions().sendKeys(' ').perform();
    
    await driver.wait(until.elementLocated(By.id('awesomebar')));

    return assert.doesNotReject(driver.findElement(By.id('awesomebar')));
  });

  it("accepts input with no spaces", async function() {
    this.timeout(3000); // sometimes takes just under 2s to complete, so this is for safety
    await checkAwesomebarMessage(
      driver,
      (e) => sendKeys(e, 'hello-world-this-is-me-life-should-be-fun-for-everyone'),
      'hello-world-this-is-me-life-should-be-fun-for-everyone'
    );
  });

  it("accepts input with spaces", async function() {
    await checkAwesomebarMessage(
      driver,
      (e) => sendKeys(e, "hi, what's up?"),
      "hi, what's up?"
    );
  });

  it("accepts input with multiple spaces prefixed", async function() {
    await checkAwesomebarMessage(
      driver,
      (e) => sendKeys(e, "    yo!"),
      "    yo!"
    );
  });

  it("accepts input with one space prefixed", async function() {
    await checkAwesomebarMessage(
      driver,
      (e) => sendKeys(e, " yo!"),
      " yo!"
    );
  });

  it("accepts input with multiple spaces suffixed", async function() {
    await checkAwesomebarMessage(
      driver,
      (e) => sendKeys(e, "yo!    "),
      "yo!    "
    );
  });

  it("accepts input with one space suffixed", async function() {
    await checkAwesomebarMessage(
      driver,
      (e) => sendKeys(e, "yo! "),
      "yo! "
    );
  });

  it("completes special words whin Tab is pressed", async function() {
    await checkAwesomebarMessage(
      driver,
      async function(e) {
        await sendKeys(e, "tomor");
        await sendKeys(e, Key.TAB);
      },
      "tomorrow"
    );
  });

  it("locates the cursor correctly after a Tab completion", async function() {
    await checkAwesomebarMessage(
      driver,
      async function(e) {
        await sendKeys(e, "tomor");
        await sendKeys(e, Key.TAB);
        await sendKeys(e, "x");
      },
      "tomorrowx"
    );
  });
}, { browsers: ['firefox'] });