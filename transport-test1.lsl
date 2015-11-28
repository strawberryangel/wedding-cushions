// melethril n�n
string CMD_STAGING = "eska"; // Staging area "home".
string CMD_CEREMONY = "gwend"; // Ceremony "bond"
//
integer ENGINE_CHANNEL = 51489145; // Link message ID to listen for.
string ENGINE_ADD = "add"; // Add waypoint.
string ENGINE_CLEAR = "clear"; // Clear all waypoints.
string ENGINE_DEBUG = "debug"; // Turn debugging information on/off.
string ENGINE_LIST = "list"; // List waypoints.
string ENGINE_RESUME = "resume"; // Resume travel to target.
string ENGINE_SPEED = "speed"; // Set maximum speed.
string ENGINE_START = "start"; // Start playing through waypoints.
string ENGINE_STOP = "stop"; // Stop movement.
//
integer LISTEN_CHANNEL = 0;

// Staging
vector staging = <128,128,23>;

// Basic arrangement.
vector center = <128,128,30>;
float radius = 3.0;
float count = 7;
// Platform
float platform_radius = 5;

///////////////////////////////////////////////////////////////////////////////
// Engine Functions
///////////////////////////////////////////////////////////////////////////////

add(vector target)
{
	// State: Any
	// Result: Unchanged.
	llMessageLinked(LINK_SET, ENGINE_CHANNEL, ENGINE_STOP, NULL_KEY);
	llMessageLinked(LINK_SET, ENGINE_CHANNEL, ENGINE_ADD + "|" + (string)target, NULL_KEY);
}

clear()
{
	// State: Any
	// Result  = Unchanged.
	llMessageLinked(LINK_SET, ENGINE_CHANNEL, ENGINE_STOP, NULL_KEY);
	llMessageLinked(LINK_SET, ENGINE_CHANNEL, ENGINE_CLEAR, NULL_KEY);
}

go(vector target)
{
	// State: Any
	// Result: Running.
	stop();
	clear();
	add(target);
	start();
}

speed(float speed)
{
	llMessageLinked(LINK_SET, ENGINE_CHANNEL, ENGINE_SPEED + "|" + (string)speed, NULL_KEY);
}

start()
{
	llMessageLinked(LINK_SET, ENGINE_CHANNEL, ENGINE_START, NULL_KEY);
}

stop()
{
	llMessageLinked(LINK_SET, ENGINE_CHANNEL, ENGINE_STOP, NULL_KEY);
}


///////////////////////////////////////////////////////////////////////////////
// Supported commands.
///////////////////////////////////////////////////////////////////////////////

cmd_staging()
{
	stop();
	go(staging);
}

cmd_ceremony()
{
	float number = (float)llGetObjectName();
	float angle = number * TWO_PI / count;

	vector offset;
	rotation rotate;
	// Waypoint 1
	offset = <10 - radius, 0, 0>; // Vector along the X axis.
	rotate = llEuler2Rot(<0.0, 0.0, angle>);
	offset = offset * rotate;
	add(center + offset + <0, 0, -3>);

	// Waypoint 2
	add(center + offset + <0, 0, 3>);

	// Waypoint 3 
	offset = <radius, 0, 0>; // Vector along the X axis.
	rotate = llEuler2Rot(<0.0, 0.0, angle>);
	offset = offset * rotate;
	add(center + offset + <0, 0, 3>);

	// Waypoint 4
	add(center + offset);

	speed(0.5);
	start();
}

handle_message(string message)
{
	list parsed = parse_command(message);
	integer length = llGetListLength(parsed);
	//say("Command length = " + (string)length);

	if(length == 0) return;

	string command = llList2String(parsed, 0);
	// Single-word commands
	if(command == CMD_STAGING) cmd_staging();
	if(command == CMD_CEREMONY) cmd_ceremony();
}

init()
{
	llListen(LISTEN_CHANNEL, "", llGetOwner(), "");
}

list parse_command(string message)
{
	list pieces = llParseStringKeepNulls(message, [" "], []);
	integer length = llGetListLength(pieces);
	if(length == 0) return [];

	string command = llList2String(pieces, 0);
	if(length == 1) return [command];

	list remainder_list = llDeleteSubList(pieces, 0, 0);
	return [command] + llDumpList2String(remainder_list, " ");
}

say(string message)
{
	llOwnerSay(message);
}

default
{
	changed(integer change)
	{
		init();
	}
	listen(integer channel, string name, key id, string message)
	{
		handle_message(message);
	}
	on_rez(integer start_param)
	{
		init();
	}
	state_entry()
	{
		init();
	}
}

