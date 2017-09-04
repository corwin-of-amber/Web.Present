http = require 'http'
blob-to-buffer = require '../lib/blob-to-buffer'
WebSocketServer = require 'websocket' .server
stoppable = require 'stoppable'
JSONStream = require 'JSONStream'



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
    #console.log(request)
    #process.stderr.write("[server]  #{request.url}")
    switch request.url
    case "/" =>
      response
        ..writeHead 200, { 'Content-Type': 'text/html' } <<< NO_CACHE
        ..write '''<script src="jquery.js"></script><script src="EventEmitter.js"></script>
                   <script src="client.ls.js"></script>
                   <script src="overlay.ls.js"></script>
                   <link rel="stylesheet" type="text/css" href="viewer.css">
                   <body></body>'''
        ..end!
    case "/client.ls.js" => @serve-static(response, "src/client.ls.js")
    case "/overlay.ls.js" => @serve-static(response, "src/overlay.ls.js")
    case "/jquery.js" => @serve-static(response, "node_modules/jquery/dist/jquery.js")
    case "/EventEmitter.js" => @serve-static(response, "node_modules/eventemitter-browser/EventEmitter.js")
    case "/viewer.css" => @serve-static(response, "src/viewer.css")
    case "/overlay.json" =>
      switch request.method
        case "GET" => @serve-json(response, viewer.overlay.get-state!)
        case "POST" =>
          caught = (op) -> -> try op ... catch e => console.error e
          # NOTICE This tends to CRASH AND BURN (segfault) when an exception
          #   escapes the event handler  :\ O_o
          request.pipe(JSONStream.parse()).on 'data' caught ->
            viewer.overlay.set-state it
            viewer.annotate-changed!
          .on 'end' ->
            response.end!
    else
      @serve-image response

  serve-static: (response, local-filename) ->
    fs.createReadStream(local-filename).pipe(response)

  serve-json: (response, obj) ->
    response
      ..writeHead 200, { 'Content-Type': 'application/json' } <<< NO_CACHE
      ..write JSON.stringify(obj)
      ..end!

  serve-image: (response) ->
    blob = viewer?blob
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
      #console.log ws-request
      console.log "#{..remoteAddress} connected"
      @sessions[_idcnt++] = ..
      ..on 'message' @~handle
      ..on 'close' (reason, desc) ~> @disconnected .., reason, desc

  handle: (message) ->
    #console.log message
    switch message.utf8Data
      case 'next' => viewer.next-page!
      case 'prev' => viewer.prev-page!

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
