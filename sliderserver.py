#!bin/python
"""
send slider events to a web page over websockets
"""
from twisted.internet import reactor
import sys, optparse, logging, json
import cyclone.web, cyclone.httpclient, cyclone.websocket

sys.path.append("../light9")
from bcf2000 import BCF2000

logging.basicConfig(level=logging.DEBUG)
log = logging.getLogger()

class Hw(BCF2000):
    def valueIn(self, name, value):
        print "in" ,name, value

        sendToLiveClients({'sliderEvent':{'name':name, 'value':value}})


liveClients = set()
def sendToLiveClients(d=None, asJson=None):
    j = asJson or json.dumps(d)
    for c in liveClients:
        c.sendMessage(j)

class Live(cyclone.websocket.WebSocketHandler):

    def connectionMade(self, *args, **kwargs):
        log.info("websocket opened")
        liveClients.add(self)

    def connectionLost(self, reason):
        log.info("websocket closed")
        liveClients.remove(self)

    def messageReceived(self, message):
        log.info("got message %s" % message)

        # self.valueOut('slider5', value)
        
        self.sendMessage(message)

class Index(cyclone.web.RequestHandler):
    def get(self):
        self.write('slider server. see <a href="ws:///sliders">/sliders</a>')
        
if __name__ == "__main__":
    logging.basicConfig()
    log = logging.getLogger()

    parser = optparse.OptionParser()
    parser.add_option("-v", "--verbose", action="store_true",
                      help="logging.DEBUG")
    (options, args) = parser.parse_args()

    log.setLevel(logging.DEBUG if options.verbose else logging.INFO)

    from twisted.python import log as twlog
    twlog.startLogging(sys.stdout)

    hw = Hw()
    
    port = 9990
    reactor.listenTCP(port, cyclone.web.Application(handlers=[
        (r'/', Index),
        (r'/sliders', Live),
        ], debug=True, hw=hw))
    log.info("serving on %s" % port)
    reactor.run()
