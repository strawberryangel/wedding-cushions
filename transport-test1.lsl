// melethril n�n
string CMD_STAGING = "eska"; // Staging area "home".
string CMD_CEREMONY = "gwendad"; // Ceremony gwend "bond" + sad "place, spot"
string CMD_SAY = "pedo"; // Imperative  "ped-" say.
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
vector staging = <192,64,3100>;

// Basic arrangement.
vector center = <176,80,3111>;
integer number;
float radius;
float count;
// Platform
float platform_radius = 5.0;
float platform_below = 2;
float platform_above = 5;

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
	get_object();
	float angle = number * TWO_PI / count;

	vector offset;
	rotation rotate;
	// Waypoint 1
	offset = <2*platform_radius - radius, 0, 0>; // Vector along the X axis.
	rotate = llEuler2Rot(<0.0, 0.0, angle>);
	offset = offset * rotate;
	add(center + offset + <0, 0, -platform_below>);

	// Waypoint 2
	float height = platform_above*(1 - radius/platform_radius);
	vector above = <0, 0, height>;
	add(center + offset + above);

	// Waypoint 3
	offset = <radius, 0, 0>; // Vector along the X axis.
	rotate = llEuler2Rot(<0.0, 0.0, angle>);
	offset = offset * rotate;
	add(center + offset + above);

	// Waypoint 4
	add(center + offset);

	start();
}

cmd_say()
{
	llOwnerSay("sidh");
}

///////////////////////////////////////////////////////////////////////////////
// Support functions
///////////////////////////////////////////////////////////////////////////////

get_object()
{
	list pieces = llParseString2List(llGetObjectName(), ["\\"], []);
	number = (integer)llList2String(pieces, 0);
	integer row_number = (integer)llList2String(pieces, 1);
	if(row_number == 1)
	{
		radius = 1;
		count = 7;
	}
	else if(row_number == 2)
	{
		radius = 2;
		count = 9;
	}
	else if(row_number == 3)
	{
		radius = 3;
		count = 11;
	}
	else if(row_number == 4)
	{
		radius = 4;
		count = 13;
	}
	else if(row_number == 5)
	{
		radius = 5;
		count = 15;
	}
	else if(row_number == 6)
	{
		radius = 6;
		count = 17;
	}
	else
	{
		radius = 7;
		count = 19;
	}
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
	if(command == CMD_SAY) cmd_say();
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

