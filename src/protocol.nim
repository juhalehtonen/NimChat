# Import the json module to parse JSON
import json

type
  Message* = object # Defines a new Message type. The * export marker is placed after the name of the type.
    username*: string # Field definitions follow the type definition and are exported similarly.
    message*: string

## Parses the JSON
# Defines a new parseMessage procedure. The export marker is also used to export it.
proc parseMessage*(data: string): Message =
  let dataJson = parseJson(data) # parseJson procedure accepts a string and returns a value of JsonNode type
  result.username = dataJson["username"].getStr() # Gets the value under the username key and assigns its string value to the username field of the resulting message
  result.message = dataJson["message"].getStr()

# Note: The `result` variable is implicitly defined by Nim. It is defined in all
# procedures that are defined with a return type. The result variable is automatically
# returned for you.

## Procedure for creating a message (generating JSON). % operator creates a JsonNode object.
proc createMessage*(username, message: string): string =
  result = $(%{ # The $ converts the JsonNode, returned by the % operator, into a string
    "username": %username, # The % converts strings, integers, floats adn more into appropriate JsonNodes
    "message": %message
  }) & "\c\1" # Add carriage return and line feed characters to end of message for separating


#[
The `when` statement is a compile-time if statement that only includes the code
under it if its condition is true. The isMainModule constant is true when the current
module hasn't been imported. The result is that the test code is hidden if this
module is imported.
]#
when isMainModule:
  block: # Begins a new scope (useful for isolating tests). Test for correct input.
    # Triple-quoted string literal syntax to define data. Triple-quoted means that
    # the single quote in the JSON doesn't have to be escaped.
    let data = """{"username": "John", "message": "Hi!"}"""
    let parsed = parseMessage(data) # Calls the parseMessage procedure on this data defined previously
    doAssert parsed.username == "John"
    doAssert parsed.message == "Hi!"
    echo "All protocol tests passed!"
  block: # Test for incorrect input.
    let data = """foobar"""
    try:
      let parsed = parseMessage(data)
      doAssert false # This line should never be executed because parseMessage will raise an exception
    except JsonParsingError: # Make sure that the exception is the one we expect
      doAssert true
    except:
      doAssert false
  block:
    let expected = """{"username": "dom", "message": "hello"}""" & "\c\1"
    doAssert createMessage("dom", "hello") == expected
# TODO: An ideal way for the parseMessage proc to report errors would be by raising a custom exception.
