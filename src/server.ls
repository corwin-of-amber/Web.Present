http = require 'http'
blob-to-buffer = require '../lib/blob-to-buffer'
WebSocketServer = require 'websocket' .server
stoppable = require 'stoppable'



get-my-ip = ->
  os = require('os')
  ifaces = os.networkInterfaces()

  addresses = []
    for name, iface of ifaces
      for entry in iface
        if (entry.family == 'IPv4' && !entry.internal)
           ..push entry.address

  addresses[0] ? 'localhost'


PORT = 8008
HOST = get-my-ip!


class Server

  ->
    @sessions = {}
    @server = @init-server!

  init-server: ->
    server = stoppable http.createServer()

      ..on 'request' @~serve

      ..listen PORT, ->
        console.log "HTTP server listening on http://#{HOST}:#{server.address!port}"

      window.addEventListener 'unload' -> server.stop!

    ws = new WebSocketServer do
      httpServer: server
      autoAcceptConnections: false

    ws.on 'request' @~connected


  serve: (request, response) ->
    console.log(request)
    process.stderr.write("[server]  #{request.url}")
    switch request.url
    case "/" =>
      response
        ..writeHead 200, { 'Content-Type': 'text/html' } <<< NO_CACHE
        ..write '''<script src="jquery.js"></script><script src="EventEmitter.js"></script>
                   <script src="client.ls.js"></script>
                   <link rel="stylesheet" type="text/css" href="client.css">
                   <body></body>'''
        ..end!
    case "/client.ls.js" => @serve-static(response, "src/client.ls.js")
    case "/jquery.js" => @serve-static(response, "node_modules/jquery/dist/jquery.js")
    case "/EventEmitter.js" => @serve-static(response, "node_modules/eventemitter-browser/EventEmitter.js")
    case "/client.css" => @serve-static(response, "src/client.css")
    else
      @serve-image response
    #fs.createReadStream("./src/index.html").pipe(response)

  serve-static: (response, local-filename) ->
    fs.createReadStream(local-filename).pipe(response)

  serve-image: (response) ->
    blob = viewer.blob
    if !blob?
      response.end!
    else
      err, buf <- blob-to-buffer blob
      if err
        fs.createReadStream("./src/index.html").pipe(response)
      else
        response
          ..writeHead 200, { 'Content-Type': 'image/png' } <<< NO_CACHE
          ..write buf ; ..end!


  _idcnt = 0

  connected: (ws-request) ->
    ws-request.accept('present-protocol', ws-request.origin)
      console.log ws-request
      console.log "#{..remoteAddress} connected"
      @sessions[_idcnt++] = ..
      ..on 'message' @~handle
      ..on 'close' (reason, desc) ~> @disconnected .., reason, desc

  handle: (message) ->
    console.log message
    if message.utf8Data == 'next'
      viewer.next-page!

  disconnected: (conn, reason, desc) ->
    console.log "#{conn.remoteAddress} disconnected (#{reason} #{desc})"
    ks = [k for k,v of @sessions when v == conn]
    for k in ks then delete @sessions[k]

  broadcast: (msg) ->
    for id, conn of @sessions
      conn.send(msg)


NO_CACHE =
  'Cache-Control': 'no-cache, no-store, must-revalidate'
  'Pragma': 'no-cache'
  'Expires': '0'


server = new Server


export server
