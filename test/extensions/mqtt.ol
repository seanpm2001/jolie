/*
 * Copyright (C) 2017 Stefano Pio Zingaro <stefanopio.zingaro@unibo.it>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301  USA
 */

include "../AbstractTestUnit.iol"
include "private/mqtt_server.iol"

outputPort Broker {
    Location: MQTT_BrokerLocation
    Protocol: mqtt
    Interfaces: ServerInterface
}

embedded {
Jolie:
    "private/mqtt_server.ol"
}

define checkResponse
{
    if ( x != 10 ) {
        throw( TestFailed, "Unexpected result" )
    }
}

define doTest
{
    twice@Broker( 5 )( x ) ;
    checkResponse  
}
