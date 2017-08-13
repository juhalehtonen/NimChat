# Due to `spawn`, compilation requires the --threads:on flag to enable Nim’s threading support.
# Thankfully this can be done with the client.nims config file.

# Required to use the paramCount and paramStr procedures from the os module,
# and threadpool module is needed for spawn.
import os, threadpool, asyncdispatch, asyncnet
import protocol

proc connect(socket: AsyncSocket, serverAddr: string) {.async.} =
  echo("Connecting to ", serverAddr)
  await socket.connect(serverAddr, 7687.Port)
  echo("Connected!")

  while true:
    let line = await socket.recvLine() # Continously attempt to read a message from server
    let parsed = parseMessage(line) # Uses parseMessage procedure from protocol module
    echo(parsed.username, " said: ", parsed.message)

echo("Chat application started")
if paramCount() == 0: # Ensure user has specified a parameter on the command line
  quit("Please specifcy the server address, .e.g. ./client localhost") # Stops app prematurely

# Retrieve the first parameter that the user specified. Index of 1 is used because
# the executable name is stored at index 0. However, don’t retrieve the executable
# name via paramStr(0), as it may give you OS-specific data that’s not portable.
let serverAddr = paramStr(1)
let chatterName = paramStr(2)
var socket = newAsyncSocket()

asyncCheck connect(socket, serverAddr)
var messageFlowVar = spawn stdin.readLine() # The initial readLine call has been moved out of the while loop
while true:
  if messageFlowVar.isReady(): # The isReady procedure determines if reading the value from messageFlowVar will block.
    let message = createMessage(chatterName, ^messageFlowVar) # Create new message (from protocol module). TODO: Get username
    asyncCheck socket.send(message) # Sends the message to the server, In this case, createMessage adds the separator.
    messageFlowVar = spawn stdin.readLine() # Spawns readLine in another thread as the last one has returned with data.

  asyncdispatch.poll() # Calls the event loop manually using the poll procedure
