const {suite} = require('selenium-webdriver/testing');
const {By, Builder, Browser, until} = require('selenium-webdriver');
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
    await driver.actions().sendKeys(' ').perform();
    
    driver.wait(until.elementLocated(By.id('awesomebar')));

    var awesomebar = await driver.findElement(By.id('awesomebar'));

    let noSpaceMessage = 'hello-world-this-is-me-life-should-be-fun-for-everyone';
    await sendKeysSlow(awesomebar, noSpaceMessage);
    awesomebar = await driver.findElement(By.id('awesomebar'));
    await driver.wait(until.elementTextMatches(awesomebar, new RegExp(`.{${noSpaceMessage.length},}`)));
    let actual = await awesomebar.getText()
    assert.strictEqual(actual, noSpaceMessage);
    return new Promise((resolve) => { assert.ok(true); resolve(); });
  });

  it("accepts input with spaces", async function() {
    await driver.actions().sendKeys(' ').perform();
    
    driver.wait(until.elementLocated(By.id('awesomebar')));

    var awesomebar = await driver.findElement(By.id('awesomebar'));

    let spaceMessage = "hi, what's up?";
    await sendKeysSlow(awesomebar, spaceMessage);
    awesomebar = await driver.findElement(By.id('awesomebar'));
    await driver.wait(until.elementTextMatches(awesomebar, new RegExp(`.{${spaceMessage.length},}`)));
    let actual = await awesomebar.getText()
    assert.strictEqual(actual, spaceMessage);
    return new Promise((resolve) => { assert.ok(true); resolve(); });
  });
}, { browsers: ['firefox'] });