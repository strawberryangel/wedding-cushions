string CMD_ADD = "add"; // Add waypoint.
string CMD_CLEAR = "clear"; // Clear all waypoints.
string CMD_GO = "go"; // Go to an absolute position.
string CMD_HERE = "here"; // Set home to current position.
string CMD_HOME = "home"; // Go to home position
string CMD_LIST = "list"; // List waypoints.
string CMD_MOVE = "move"; // Move relative to current position.
string CMD_RESET = "reset"; // Reset waypoint index.
string CMD_START = "start"; // Start playing through waypoints.
string CMD_STOP = "stop"; // Stop movement.
string CMD_WHERE = "where"; // Where are we?
//
integer LISTEN_CHANNEL = 0;
integer RELATIVE_WAYPOINTS = FALSE; // If true, waypoints are relative positions.

vector target;
float target_range = 0.25;
float min_time = 0.11111111111111111111111111111111; // 5/45;
float max_speed = 5.0; // m/S
integer is_running = FALSE;
vector home = ZERO_VECTOR;
integer waypoint_index = 0;
list waypoints = [];

integer check_waypoint()
{
	// Is the current position within a certain distance of the target? 
	vector current_location = llGetPos();
	vector direction = target - current_location;
	float distance = llVecMag(direction);
	return distance <= target_range;
}

vector get_vector(string message, string command)
{
	// Get the second parameter of message assuming it contains command. 
	return (vector)llGetSubString(message, llStringLength(command), -1);
}

cmd_add(vector target)
{
	// State: Any
	// Result: Unchanged.
	waypoints = waypoints + target;
	say("Added waypoint " + (string)target);
}

cmd_clear()
{
	// State: Any
	// Result  = Stopped
	cmd_stop();
	waypoints = [];
	waypoint_index = 0;
	say("Cleared waypoints.");
}

cmd_go(vector target)
{
	// State: Running
	// Result: running
	if(is_running) return;
	
	set_waypoint(target);
	say("Going to " + (string)target);
}

cmd_here()
{
	// Sets home position to the current position
	home = llGetPos();
	say("Home set to " + (string)home);
}

cmd_home()
{
	cmd_stop();
	cmd_go(home);
}

cmd_list()
{
	say("Waypoints:");
	integer length = llGetListLength(waypoints);
	integer i;
	for(i=0; i < length; i++)
		say((string)llList2Vector(waypoints, i));
}

cmd_move(vector offset)
{
	cmd_go(llGetPos() + offset);
}

cmd_reset()
{
	waypoint_index = 0;
	say("Waypoint index reset.");
}

cmd_start()
{
	is_running = TRUE;
	next_waypoint();
}

cmd_stop()
{
	is_running = FALSE;
	llSetKeyframedMotion([], []);
	say("Stopped.");
}

cmd_where()
{
	say((string)llGetPos());
}

handle_message(string message)
{
	list parsed = parse_command(message);
	integer length = llGetListLength(parsed);
	//say("Command length = " + (string)length);

	if(length == 0) return;

	string command = llList2String(parsed, 0);
	if(length == 1)
	{
		//say("Single-word command: " + command);
		// Single-word commands
		if(command == CMD_CLEAR) cmd_clear();
		if(command == CMD_HERE) cmd_here();
		if(command == CMD_HOME) cmd_home();
		if(command == CMD_LIST) cmd_list();
		if(command == CMD_RESET) cmd_reset();
		if(command == CMD_START) cmd_start();
		if(command == CMD_STOP) cmd_stop();
		if(command == CMD_WHERE) cmd_where();
		return;
	}

	// Two-part commands
	vector target = llList2Vector(parsed, 1);

	//say("Two-part command: " + command + " " + (string)target);
	if(command == CMD_ADD) cmd_add(target);
	if(command == CMD_GO) cmd_go(target);
	if(command == CMD_MOVE) cmd_move(target);
}

integer is_command(string message, string command, integer offset)
{
	integer length = llStringLength(command);
	if(offset > 0)
	{
		command = llGetSubString(command + "      ", 0, length + offset - 1);
		length = length + offset;
	}
	return llGetSubString(message, 0, length - 1) == command;
}

next_waypoint()
{
	integer count = llGetListLength(waypoints);
	if(count <= waypoint_index)
	{
		is_running = FALSE;
		waypoint_index = 0;
		return;
	}

	vector waypoint = llList2Vector(waypoints, waypoint_index);
	waypoint_index += 1;
	if(RELATIVE_WAYPOINTS)
		set_waypoint(target + waypoint);
	else
		set_waypoint(waypoint);
}

list parse_command(string message)
{
	list pieces = llParseStringKeepNulls(message, [" "], []);
	integer length = llGetListLength(pieces);
	if(length == 0) return [];

	string command = llList2String(pieces, 0);
	if(length == 1) return [command];

	list remainder_list = llDeleteSubList(pieces, 0, 0);
	string remainder = llDumpList2String(remainder_list, " ");
	//say("parse comand: " + remainder);
	vector target = (vector)remainder;
	//say("parse command: " + (string)target);
	return [command, target];
}

say(string message)
{
	llOwnerSay(message);
}

set_object_type()
{
	llSetLinkPrimitiveParamsFast(LINK_ROOT,
		[PRIM_PHYSICS_SHAPE_TYPE, PRIM_PHYSICS_SHAPE_CONVEX,
		PRIM_LINK_TARGET, LINK_ALL_CHILDREN,
		PRIM_PHYSICS_SHAPE_TYPE, PRIM_PHYSICS_SHAPE_NONE]);
}

set_waypoint(vector value)
{
	target = value;
	vector current_location = llGetPos();
	vector direction = target - current_location;
	float distance = llVecMag(direction);
	float time = llRound(45 * distance / max_speed)/45;
	if(time < min_time) time = min_time;
	llSetKeyframedMotion([direction, ZERO_ROTATION, time], []);
}

default
{
	listen(integer channel, string name, key id, string message)
	{
		handle_message(message);
	}
	moving_end()
	{
		if(!is_running) return;

		if(check_waypoint())
			next_waypoint();
		else
			waypoint_index = 0;
	}
	on_rez(integer start_param)
	{
		set_object_type();
		cmd_here();
	}
	state_entry()
	{
		llListen(LISTEN_CHANNEL, "", llGetOwner(), "");
		set_object_type();
	}
	touch_end(integer total_number)
	{
		set_object_type();
		next_waypoint();
	}
}