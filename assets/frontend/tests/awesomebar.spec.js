const {By, Builder, Browser, until} = require('selenium-webdriver');
const assert = require("assert");

(async function firstTest() {
  let driver;
  
  try {
    driver = await new Builder().forBrowser(Browser.FIREFOX).build();
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
    let elm_app = await driver.findElement(By.id('elm-app-container'));
    //await elm_app.sendKeys(' ');
    await driver.actions().sendKeys(' ').perform();
    
    driver.wait(until.elementLocated(By.id('awesomebar')));

    let awesomebar = await driver.findElement(By.id('awesomebar'));

    let noSpaceMessage = 'hello-world-this-is-me-life-should-be-fun-for-everyone';
    await awesomebar.sendKeys(noSpaceMessage);
    // driver.wait(until.elementIsNotVisible(By.id('awesomebar')), 5000);
  
    let onScreen = await awesomebar.getText();
    // driver.wait(until.elementIsNotVisible(By.id('awesomebar')), 5000);

    assert.equal(onScreen, noSpaceMessage);
  } catch (e) {
    console.log(e)
  } finally {
    await driver.quit();
  }
}())