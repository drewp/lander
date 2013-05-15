
mRequestingApproach = (ship) ->
    x = _.random(-1000, 1000)
    y = _.random(-1000, 1000)

    shipMsg =  'Requesting approach, vector '+x+'x'+y+'.'

    response = _.random(0, 1)
    if response == 1
        stationMsg = ship + ', approach confirmed, please continue.'
    else
        stationMsg = ship + ', approach delayed, please hold pattern until further notice.'

    [shipMsg, stationMsg]


mPassingMarker = (ship) ->
    x = String.fromCharCode(_.random(65, 90))
    y = _.random(0, 1000)
    z = String.fromCharCode(_.random(97, 122))
    shipMsg = 'NOTE - Passing marker '+x+'-'+y+'-'+z+'.'

    [shipMsg, null]


MSGS = [mRequestingApproach, mPassingMarker]


# ======================================================
waitRandomTime = (min, max, cb) ->
    timeToWait = _.random(min, max)
    setTimeout(cb, timeToWait * 1000)


getRandomMsg = (ship) ->
    choice = _.random(0, MSGS.length - 1)
    return MSGS[choice](ship)


getRandomShip = () ->
    shipNames = ['AX20', 'THX1138', 'NEPTQ', 'VELICITY', 'DRAIL', 'CATT',
                 'WRANGLE', 'FOXHUNT', 'LEOPOR', 'WINTRACK', 'ONONE', 'ENVIR',
                 'TAGLINE', 'HITUP', 'AGRON']
    choice = _.random(0, shipNames.length - 1)
    shipNames[choice]


chatterOut = $("#chatter")
printColor = (msg, color) ->
    lines = chatterOut.children()
    if lines.length > 20
      lines[0].remove()
    chatterOut.append($("<div>").addClass(color).text(msg))
    
getCurrentTimeStr = () ->
    moment().format('YYYY-MM-DD hh:mm:ss')

# ======================================================

step = () ->
  printColor('', 'white')
  waitRandomTime 0, 3, () ->
    ship = getRandomShip()
    [shipMsg, stationMsg] = getRandomMsg(ship)
 
    printColor(getCurrentTimeStr(), 'white')
    
    if shipMsg?
      printColor(ship + ' == ' + shipMsg, 'blue')

    if stationMsg?
        waitRandomTime 1, 4, () ->
          printColor('PACKARD STATION - ' + stationMsg, 'green')
          step()
    else
      step()
step()
