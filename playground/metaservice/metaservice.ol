/***************************************************************************
 *   Copyright (C) by Fabrizio Montesi                                     *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as               *
 *   published by the Free Software Foundation; either version 2 of the    *
 *   License, or (at your option) any later version.                       *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU Library General Public     *
 *   License along with this program; if not, write to the                 *
 *   Free Software Foundation, Inc.,                                       *
 *   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             *
 *                                                                         *
 *   For details about the authors of this software, see the AUTHORS file. *
 ***************************************************************************/

include "config.iol"
include "console.iol"
include "runtime.iol"

execution { sequential }

include "metaservice.iol"

inputPort MetaService {
Location: MetaServiceLocation
Protocol: sodep
Interfaces: MetaServiceConsultation, MetaServiceAdministration
}

outputPort ConfirmingService {
RequestResponse:
	confirmRedirection throws InvalidToken
}

init
{
	services -> global.services;

	config.debug = Debug;

	// TODO: implement a proper Logger service interface.
	if ( config.debug ) {
		install(
			EmbeddingFault => println@Console( "Embedding fault thrown" ),
			RedirectionNotFound => println@Console( "RedirectionNotFound fault thrown" )
		)
	} else {
		install(
			EmbeddingFault => nullProcess,
			RedirectionNotFound => nullProcess
		)
	}
}

main
{
	[ addRedirection( request )( response ) {
		scope( addRedirectionScope ) {
			//install( RuntimeException => nullProcess ); // TODO: add a proper logging action here
			with( redirection ) {
				.resourceName = request.resourcePrefix;
				.inputPortName = "MetaService"
			};
			getRedirection@Runtime( redirection )( outputPortName );
			if ( is_defined( outputPortName ) ) {
				// If we already have that redirection, generate a fresh name for the new service.
				if ( is_defined( global.counter.(outputPortName) ) ) {
					global.counter.(outputPortName)++
				} else {
					global.counter.(outputPortName) = 2
				};
				redirection.resourceName = outputPortName + "-" + global.counter.(outputPortName)
			};

			with( port ) {
				.name = redirection.resourceName;
				.location = request.location;
				.protocol << request.protocol
			};
			setOutputPort@Runtime( port )();

			// If we can't set the redirection, we must remove the output port.
			install( RuntimeException => removeOutputPort@Runtime( port.name ); cH );
			redirection.outputPortName = redirection.resourceName;
			setRedirection@Runtime( redirection )();
			response = redirection.resourceName;
			services.(redirection.resourceName).metadata << request.metadata;

			if ( is_defined( request.token ) ) {
				// Optional token for security check
				ConfirmingService.location = request.location;
				ConfirmingService.protocol << request.protocol;
				install( InvalidToken => throw( RuntimeException ) );
				confirmRedirection@ConfirmingService( request.token )()
			}
		}
	} ] { nullProcess }

	[ removeRedirection( request )() {
		r.resourceName = request;
		r.inputPortName = "MetaService";
		removeRedirection@Runtime( r )();
		removeOutputPort@Runtime( request )()
	} ] { nullProcess }

	[ getServices()( response ) {
		i = 0;
		foreach( s : services ) {
			response.service[i] << services.(s);
			response.service[i].resourceName = s;
			i++
		}
	} ] { nullProcess }

	[ loadEmbeddedJolieService( request )( response ) {
		scope( embedJolieScope ) {
			install( RuntimeException => throw( EmbeddingFault ) );
			with( redirection ) {
				.resourceName = request.resourcePrefix;
				.inputPortName = "MetaService"
			};
			getRedirection@Runtime( redirection )( outputPortName );
			if ( is_defined( outputPortName ) ) {
				// If we already have that redirection, generate a fresh name for the new service.
				if ( is_defined( global.counter.(outputPortName) ) ) {
					global.counter.(outputPortName)++
				} else {
					global.counter.(outputPortName) = 2
				};
				redirection.resourceName = outputPortName + "-" + global.counter.(outputPortName)
			};

			// Load the embedded service.
			with( embedInfo ) {
				.type = "Jolie";
				.filepath = request.filepath
			};
			loadEmbeddedService@Runtime( embedInfo )( handle );

			with( port ) {
				.name = redirection.resourceName;
				.location = handle
			};
			setOutputPort@Runtime( port )();

			// If we can't set the redirection, we must also remove the output port.
			install( RuntimeException => removeOutputPort@Runtime( port.name ); cH );
			redirection.outputPortName = redirection.resourceName;
			setRedirection@Runtime( redirection )();

			response = redirection.resourceName;
			services.(redirection.resourceName).metadata << request.metadata
		}
	} ] { nullProcess }

	[ unloadEmbeddedService( request )( response ) {
		removeRedirection@Runtime( request );
		removeOutputPort@Runtime( request )();
		undef( services.(request) )
	} ] { nullProcess }

	[ shutdown() ] { exit }
}
