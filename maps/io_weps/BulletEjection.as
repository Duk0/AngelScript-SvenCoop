/*
=================
EV_GetDefaultShellInfo
 
Determine where to eject shells from
Taken from the HL SDK
=================
*/
/**
*   This function calculates the origin and velocity for a shell ejected at the given location.
*   @param pPlayer Player to use for calculations.
*   @param ShellVelocity The velocity of the shell. The shell velocity will point to the right of the screen (righthanded weapon with ejection to the right).
*   @param ShellOrigin The origin of the shell. This is where the shell starts.
*   @param forwardScale X offset for the shell. Positive values move further out, negative values place it behind the player.
*   @param rightScale Y offset for the shell. Positive values move to the right, negative values move to the left.
*   @param upScale Z offset for the shell. Positive values move up, negative values move down.
*/

void GetDefaultShellInfo( CBasePlayer@ pPlayer, Vector& out ShellVelocity, Vector& out ShellOrigin, float forwardScale, float rightScale, float upScale )
{  
	Vector vecForward, vecRight, vecUp;
	
	g_EngineFuncs.AngleVectors( pPlayer.pev.v_angle, vecForward, vecRight, vecUp );
	
	const float fR = Math.RandomFloat( 50, 70 );
	const float fU = Math.RandomFloat( 100, 150 );
 
	for( int i = 0; i < 3; ++i )
	{
		ShellVelocity[i] = pPlayer.pev.velocity[i] + vecRight[i] * fR + vecUp[i] * fU + vecForward[i] * 25;
		ShellOrigin[i]   = pPlayer.pev.origin[i] + pPlayer.pev.view_ofs[i] + vecUp[i] * upScale + vecForward[i] * forwardScale + vecRight[i] * rightScale;
	}
}