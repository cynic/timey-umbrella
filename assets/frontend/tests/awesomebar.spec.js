const {By, Builder, Browser, until} = require('selenium-webdriver');
const assert = require("assert");
const { Type, Level, addConsoleHandler, installConsoleHandler } = require('selenium-webdriver/lib/logging');

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

(async function firstTest() {
  let driver;
  
  try {
    driver = await new Builder()
      .forBrowser(Browser.FIREFOX)
      .build();
    await driver.get('http://localhost:4000/');

    let title = await driver.getTitle();
    assert.match(title, /Timely/);
  
    // mmm, I like expected conditions more, but…
    await driver.manage().setTimeouts({implicit: 500});

    // check if a #user_email element exists
    let email = await driver.findElement(By.id('user_email'));
    if (email) { // then I'm actually at the login page
      await email.sendKeys('cinyc.s@gmail.com');
      let password = await driver.findElement(By.id('user_password'));
      await password.sendKeys('test123456789');
      let clicky = await driver.findElement(By.id('sign_in'));
      await clicky.click();

      driver.wait(until.urlIs('http://localhost:4000'));
    }
    driver.wait(until.elementLocated(By.id('elm-app-container')));
    // let elm_app = await driver.findElement(By.id('elm-app-container'));
    //await elm_app.sendKeys(' ');
    await driver.actions().sendKeys(' ').perform();
    
    driver.wait(until.elementLocated(By.id('awesomebar')));

    var awesomebar = await driver.findElement(By.id('awesomebar'));

    let noSpaceMessage = 'hello-world-this-is-me-life-should-be-fun-for-everyone';
    await sendKeysSlow(awesomebar, noSpaceMessage);
    awesomebar = await driver.findElement(By.id('awesomebar'));
    driver.wait(until.elementTextMatches(awesomebar, new RegExp(`.{noSpaceMessage.length}`)));
    let onScreen =
      await awesomebar.getText();
      // await awesomebar.getText();

    assert.equal(onScreen, noSpaceMessage);
    driver.quit();
  } catch (e) {
    console.log("Oh noes!  I gots an errorz!  Possibly a failing test…");
    // console.log(e)
  }
}())