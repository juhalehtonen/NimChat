import asyncdispatch, asyncnet # Imports modules which contain procedures and types needed to use async sockets

type # Starts a new type section
  Client = ref object # Defines the Client type as a reference type
    socket: AsyncSocket # Specifies the socket belonging to the client, the AsyncSocket type is an async socket
    netAddr: string # Stores the address from which this client connected
    id: int # The id number of this client
    connected: bool # Flag to determine whether client is still connected

  Server = ref object # Defines the Server as a reference type
    socket: AsyncSocket # The server socket for accepting new client connections
    clients: seq[Client] # A list of client objects that have connected

# Every asynchronous operation in Nim returns a Future[T] object, where the 'T'
# corresponds to the type of value that Future promises to store in the future.

# Constructor for the Server type
proc newServer(): Server = Server(socket: newAsyncSocket(), clients: @[])
# Define $ for the type, as echo will try to use $ operator to display all of the
# procedures arguments. If this $ isnt defined for the type that you pass to echo,
# you get an error.
proc `$`(client: Client): string =
  $client.id & "(" & client.netAddr & ")"

# Process messages sent by clients
# Thanks to being async due to {.async.}, this infinite loop can be paused even
# if it never really stops executing. It pauses when await client.socket.recvLine()
# is called. Other pieces of code will be executing while this procedure waits for
# the result of the client.socket.recvLine().
proc processMessages(server: Server, client: Client) {.async.} =
  while true:
    let line = await client.socket.recvLine() # Waits for a single line to be read from the client
    if line.len == 0: # If client disconnects, client returns an empty string
      echo(client, " disconnected!")
      client.connected = false
      client.socket.close() # Close the clients socket after disconnect
      return # Stops any further processing of messages
    echo(client, " sent: ", line)
    for c in server.clients: # Send messages to clients processed by the server
      if c.id != client.id and c.connected:
        await c.socket.send(line & "\c\1")

# [1] Sets up the server socket by binding it to a port and calling listen.
# The integer port param needs to be cast to a Port type that the bindAddrs
# procedure expects.
# [3] Executes the loop procedure and then runs the event loop until the loop procedure returns.
proc loop(server: Server, port = 7687) {.async.} =
  server.socket.bindAddr(port.Port) # [1]
  server.socket.listen()

  while true:
    let (netAddr, clientSocket) = await server.socket.acceptAddr()
    echo("Accepted connection from ", netAddr)
    let client = Client( # Init a new instance of the Client object and set the fields
      socket: clientSocket,
      netAddr: netAddr,
      id: server.clients.len,
      connected: true
    )
    server.clients.add(client) # Adds the new Client instance to the clients sequence
    asyncCheck processMessages(server, client) # Run processMessages procedure in background

# Start server
var server = newServer()
waitFor loop(server) # [3]
