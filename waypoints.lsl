string CMD_ADD = "add"; // Add waypoint.
string CMD_CLEAR = "clear"; // Clear all waypoints.
string CMD_DEBUG = "debug"; // Turn debugging information on/off.
string CMD_GO = "go"; // Go to an absolute position.
string CMD_HERE = "here"; // Set home to current position.
string CMD_HOME = "home"; // Go to home position
string CMD_LIST = "list"; // List waypoints.
string CMD_MOVE = "move"; // Move relative to current position.
string CMD_RESET = "reset"; // Reset waypoint index.
string CMD_RESUME = "resume"; // Resume travel to target.
string CMD_START = "start"; // Start playing through waypoints.
string CMD_STOP = "stop"; // Stop movement.
string CMD_WHERE = "where"; // Where are we?
//
integer ENGINE_CHANNEL = 51489145; // Link message ID to listen for.
//
integer LISTEN_CHANNEL = 0;
integer RELATIVE_WAYPOINTS = FALSE; // If true, waypoints are relative positions.

vector home = ZERO_VECTOR;

cmd_add(vector target)
{
	// State: Any
	// Result: Unchanged.
	llMessageLinked(LINK_SET, ENGINE_CHANNEL, CMD_STOP, NULL_KEY);
	llMessageLinked(LINK_SET, ENGINE_CHANNEL, CMD_ADD + "|" + (string)target, NULL_KEY);
}

cmd_clear()
{
	// State: Any
	// Result  = Unchanged.
	llMessageLinked(LINK_SET, ENGINE_CHANNEL, CMD_STOP, NULL_KEY);
	llMessageLinked(LINK_SET, ENGINE_CHANNEL, CMD_CLEAR, NULL_KEY);
}

cmd_debug(integer on_off)
{
	// State: Any
	// Result: Unchanged.
	llMessageLinked(LINK_SET, ENGINE_CHANNEL, CMD_DEBUG + "|" + (string)on_off, NULL_KEY);
}

cmd_go(vector target)
{
	// State: Any
	// Result: Running.
	cmd_stop();
	cmd_clear();
	cmd_add(target);
	cmd_start();
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
	if(home == ZERO_VECTOR)
		say("Home is not set.");
	else
		cmd_go(home);
}

cmd_list()
{
	llMessageLinked(LINK_SET, ENGINE_CHANNEL, CMD_LIST, NULL_KEY);
}

cmd_move(vector offset)
{
	cmd_go(llGetPos() + offset);
}

cmd_reset()
{
	llMessageLinked(LINK_SET, ENGINE_CHANNEL, CMD_RESET, NULL_KEY);
}

cmd_resume()
{
	llMessageLinked(LINK_SET, ENGINE_CHANNEL, CMD_RESUME, NULL_KEY);
}

cmd_start()
{
	llMessageLinked(LINK_SET, ENGINE_CHANNEL, CMD_START, NULL_KEY);
}

cmd_stop()
{
	llMessageLinked(LINK_SET, ENGINE_CHANNEL, CMD_STOP, NULL_KEY);
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
		if(command == CMD_RESUME) cmd_resume();
		if(command == CMD_START) cmd_start();
		if(command == CMD_STOP) cmd_stop();
		if(command == CMD_WHERE) cmd_where();
		return;
	}

	// Two-part commands
	string param1 = llList2String(parsed, 1);

	//say("Two-part command: " + command + " " + (string)target);
	if(command == CMD_ADD) cmd_add((vector)param1);
	if(command == CMD_DEBUG) cmd_debug((integer)param1);
	if(command == CMD_GO) cmd_go((vector)param1);
	if(command == CMD_MOVE) cmd_move((vector)param1);
}

list parse_command(string message)
{
	list pieces = llParseStringKeepNulls(message, [" "], []);
	integer length = llGetListLength(pieces);
	if(length == 0) return [];

	string command = llList2String(pieces, 0);
	if(length == 1) return [command];

	list remainder_list = llDeleteSubList(pieces, 0, 0);
	return [command] + remainder_list;
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

default
{
	listen(integer channel, string name, key id, string message)
	{
		handle_message(message);
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
		cmd_stop();
	}
}

