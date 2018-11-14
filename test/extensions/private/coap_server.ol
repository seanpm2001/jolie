include "server.iol"

execution { single }

inputPort Server {
  Location: Location_CoAPServer
  Protocol: coap 
  Interfaces: ServerInterface 
}

main 
{
  provide
    [ echoPerson( request )( response ) {
      undef( response );
      response << request
    } ]
    [ identity( request )( response ) {
      undef( response );
      response << request
    } ]
  until
    [ shutdown() ]
}