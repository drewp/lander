window.reconnectingWebSocket = (url, onMessage) ->
  ws = null
  bufferedMsgs = []
  connect = ->
    ws = new WebSocket(url)
    ws.onopen = ->
      $("#status").text("connected")
      for m in bufferedMsgs
        ws.send(JSON.stringify(m))
      bufferedMsgs = []

    ws.onerror = (e) ->
      $("#status").text("error: " + e)

    ws.onclose = ->
      pong = 1 - pong
      $("#status").text("disconnected (retrying " + ((if pong then "😼" else "😺")) + ")")

      # this should be under a requestAnimationFrame to
      # save resources
      setTimeout(connect, 2000)

    ws.onmessage = (evt) ->
      onMessage(JSON.parse(evt.data))
    ws.bufferedSendJs = (msg) ->
      if ws.readyState != WebSocket.OPEN
        bufferedMsgs.push(msg)
      else
        ws.send(JSON.stringify(msg))
  
  pong = 0
  connect()
  ws