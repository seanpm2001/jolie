/***************************************************************************
 *   Copyright (C) by Fabrizio Montesi                                     *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU Library General Public License as       *
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

package jolie.process;


import jolie.SessionContext;
import jolie.runtime.ExitingException;
import jolie.runtime.FaultException;

public class SequentialProcess implements Process
{
	
	private final Process step = new Process()
	{
		private int currentChild = 0;
		@Override
		public void run( SessionContext ctx ) throws FaultException, ExitingException
		{
			if (currentChild < children.length ) {
				final Process child = children[currentChild];
				if ( ctx.isKilled() && child.isKillable() ) {
					return;
				}
				ctx.executeNext( child, step );
			}
			currentChild++;
		}

		@Override
		public Process clone( TransformationReason reason )
		{
			throw new UnsupportedOperationException( "Not supported yet." );
		}

		@Override
		public boolean isKillable()
		{
			return true;
		}
	};
	
	final private Process[] children;
	
	public SequentialProcess( Process[] children )
	{
		if ( children.length < 1 ) {
			throw new IllegalArgumentException( "Process sequences must contain at least one child." );
		}
		this.children = children;
	}
	
	public Process clone( TransformationReason reason )
	{
		Process[] p = new Process[ children.length ];
		int i = 0;
		for( Process child : children ) {
			p[ i++ ] = child.clone( reason );
		}
		return new SequentialProcess( p );
	}
	
	public void run(SessionContext ctx)
		throws FaultException, ExitingException
	{
		ctx.executeNext( step );
	}
	
	public boolean isKillable()
	{
		return children[ 0 ].isKillable();
	}
}
