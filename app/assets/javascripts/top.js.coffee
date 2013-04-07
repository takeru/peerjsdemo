# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ ($)->
  addLog = (s)->
    $('#log').prepend("<p>" + $('<div>').text(s).html() + "</p>")

  changeNickname = ()->
    nickname = $.cookie("nickname")
    if nickname is ""
      nickname = "guest-"+Math.floor(Math.random() * 1000)
    while true
      nickname = prompt("your nickname:", nickname)
      break if nickname isnt ""
    $.cookie("nickname", nickname)
    addLog("your nickname= " + nickname)

  if not $.cookie("nickname")
    changeNickname()
  else
    addLog("your nickname= " + $.cookie("nickname"))
  $("#nickname").html($.cookie("nickname"))

  $("#nickname").click ->
    changeNickname()
    $("#nickname").html($.cookie("nickname"))

  delay = (time, fn, args...) ->
    setTimeout fn, time, args...

  peer = new Peer({key: 'lj6k9nykmg3nmi', debug: !true})
  peer.on('open', (id)->
    $('#pid').text(id)
    addLog("your peerid= " + id)

    elem = $('#tweet-btn a')
    text = elem.attr("data-text")
    url  = elem.attr("data-url")
    elem.attr("data-text", text + " " + url + "#connectto="+id)
    showTweetBtn()

    for id in ($.cookie("peers") || "").split(",")
      if id
        connectTo(id)

    if m = /#connectto=(.+)$/.exec(location.hash)
      id = m[1]
      connectTo(id)
  )
  peer.on('connection', (connection, meta)->
    # console.log("connection", connection, meta)
    setupConnection(connection)
  )
  peer.on('error', (error)->
    console.log("server:error", error)
  )
  peer.on('close', ()->
    console.log("server:close")
  )

  connectTo = (id)->
    if peers[id] or id is peer.id
      return

    console.log("connectTo:", id)
    options = {
      reliable:      true
    }
    connection = peer.connect(id, options)
    setupConnection(connection)

  peers = {}

  setupConnection = (c)->
    tag = "peer(label=" + c.label + ")"
    c.on('open', ()->
      peers[c.peer] = c
      refreshPeerList()
      sendMsg(null)
      addLog('connected with peer=' + c.peer)
    )
    c.on('data', (data)->
      console.log(tag+":data=", data)
      if data.msg
        msg = unescape(data.msg)
        addLog(data.nickname + "(" + c.peer + "): " + msg)
      for id in data.ids
        if not peers[id] and id isnt peer.id
          delay Math.floor(Math.random() * 1000), ->
            connectTo(id)
    )
    c.on('close', ()->
      delete peers[c.peer]
      addLog('disconnected from peer=' + c.peer)
      refreshPeerList()
    )
    c.on('error', (error)->
      console.log(tag+":error=", error)
    )

  sendMsg = (msg)->
    ids = []
    for id,c of peers
      ids.push(id)
    for id,c of peers
      console.log("send: id=", id, "msg=", msg)
      c.send({nickname: $.cookie("nickname"), msg:msg, ids:ids})

  $("button#connect").click( ()->
    connectTo($("input#rid").val())
    $("input#rid").val("")
  )

  $("button#send").click( ()->
    msg = $("input#msg").val()
    $("input#msg").val('')
    sendMsg(escape(msg))
    addLog(msg)
  )
  $('input#msg').keypress( (e) ->
    if (e.which and e.which==13) or (e.keyCode && e.keyCode is 13)
      $("button#send").click()
  )

  refreshPeerList = ->
    size = Object.keys(peers).length
    console.log("peers.length=", size)
    ids  = ""
    html = ""
    for id,c of peers
      ids  += id + ","
      html += "<li>" + id + "</li>"
    $("#peerlist").html(html)
    $("#peerscount").html(size)
    $("input#msg").attr("disabled", size==0)
    $("button#send").attr("disabled", size==0)
    $.cookie("peers", ids)
