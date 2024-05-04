from selenium import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.common.by import By
from selenium.webdriver.support.wait import WebDriverWait
import pytest

def login_if_needed(driver):
  wait = WebDriverWait(driver, timeout=2, poll_frequency=.2)
  # check if a #user_email element exists
  email = driver.find_element(by=By.ID, value="user_email")
  if (email): # we're on the login page
      email.send_keys("cinyc.s@gmail.com")
      password = driver.find_element(by=By.ID, value="user_password")
      password.send_keys("test123456789")
      clicky = driver.find_element(by=By.ID, value="sign_in")
      clicky.click()
      wait.until(lambda driver: driver.current_url == "http://localhost:4000/")
  # wait until the #elm-app-container is located
  wait.until(lambda driver: driver.find_element(by=By.ID, value="elm-app-container"))


@pytest.fixture()
def driver(): # for firefox
  # setup
  driver = webdriver.Firefox()
  driver.implicitly_wait(0.5)
  driver.get("http://localhost:4000/")
  title = driver.title
  assert title.find("Timely") != -1 # check we're on the right page
  login_if_needed(driver)
  # do a test
  yield driver
  # teardown
  # logs = driver.get_log('browser')
  # for log in logs:
  #   print(log)
  driver.quit()

def test_non_space_string_slow(driver: webdriver.Firefox):
  wait = WebDriverWait(driver, timeout=2, poll_frequency=.2)
  ActionChains(driver).send_keys(Keys.SPACE).perform()
  # wait.until(lambda driver: driver.find_element(by=By.ID, value="awesomebar"))
  awesomebar = driver.find_element(By.ID, "awesomebar")

  expected = "hello-world-this-is-me-life-should-be-fun-for-everyone"
  for c in expected:
    awesomebar.send_keys(c)
  print(awesomebar.tag_name)
  result = awesomebar.text
  print(result)
  # wait.until(lambda driver: len(awesomebar.text) >= len(noSpaceMessage))

  assert result == expected

def test_non_space_string_fast(driver: webdriver.Firefox):
  wait = WebDriverWait(driver, timeout=2, poll_frequency=.2)
  ActionChains(driver).send_keys(Keys.SPACE).perform()
  # wait.until(lambda driver: driver.find_element(by=By.ID, value="awesomebar"))
  awesomebar = driver.find_element(By.ID, "awesomebar")

  expected = "hello-world-this-is-me-life-should-be-fun-for-everyone"
  awesomebar.send_keys(expected)
  print(awesomebar.tag_name)
  result = awesomebar.text
  print(result)
  # wait.until(lambda driver: len(awesomebar.text) >= len(noSpaceMessage))

  assert result == expected