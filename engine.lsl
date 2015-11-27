string CMD_ADD = "add"; // Add waypoint.
string CMD_CLEAR = "clear"; // Clear all waypoints.
string CMD_DEBUG = "debug"; // Turn debugging information on/off.
string CMD_LIST = "list"; // List waypoints.
string CMD_RESUME = "resume"; // Resume travel to target.
string CMD_SPEED = "speed"; // Set maximum speed.
string CMD_START = "start"; // Start playing through waypoints.
string CMD_STOP = "stop"; // Stop movement.
//
integer ENGINE_CHANNEL = 51489145; // Link message ID to listen for.

integer is_debugging = FALSE;
vector target = ZERO_VECTOR; // Current destination.
float target_range = 0.25; // How close do we need to get to a waypoint to call ourselves "arrived?"
float min_time = 0.11111111111111111111111111111111; // 5/45;
float max_speed = 5.0; // m/S
integer is_running = FALSE;
list waypoints = [];

add_waypoint(vector target)
{
	// State: Any
	// Result: Unchanged.
	if(target != ZERO_VECTOR)
	{
		waypoints = waypoints + target;
		say("Added waypoint " + (string)target);
	}
	else
		say("Refusing to add <0, 0, 0> as a waypoint.");
}

integer check_waypoint()
{
	// Is the current position within a certain distance of the target?
	vector current_location = llGetPos();
	vector direction = target - current_location;
	float distance = llVecMag(direction);
	return distance <= target_range;
}

clear_waypoints()
{
	// State: Any
	// Result  = Stopped
	waypoints = [];
	say("Cleared waypoints.");
}

handle_message(string message)
{
	list parsed = llParseString2List(message, ["|"], []);
	integer length = llGetListLength(parsed);
	//say("Command length = " + (string)length);

	if(length == 0) return;

	string command = llList2String(parsed, 0);
	if(length == 1)
	{
		//say("Single-word command: " + command);
		// Single-word commands
		if(command == CMD_CLEAR) clear_waypoints();
		else if(command == CMD_LIST) list_waypoints();
		else if(command == CMD_RESUME) set_waypoint(target);
		else if(command == CMD_START) start();
		else if(command == CMD_STOP) stop();
		return;
	}

	// Two-part commands
	string param1 = llList2String(parsed, 1);

	if(command == CMD_ADD)
	{
		vector target = (vector)param1;
		add_waypoint(target);
	}
	else if(command == CMD_DEBUG)
	{
		is_debugging = !!(integer)param1;
		llOwnerSay("Debugging set to: " + (string)is_debugging);
	}
	else if(command == CMD_SPEED)
	{
		float new_speed = (float)param1;
		if(new_speed > 0)
		{
			max_speed = new_speed;
			say("Setting speed to: " + (string)new_speed);

		}
		else
			say("Refusing to set speed to: " + (string)new_speed);
	}
}

list_waypoints()
{
	integer length = llGetListLength(waypoints);
	say("Waypoints: " + (string)length);

	integer i;
	for(i=0; i < length; i++)
		say((string)llList2Vector(waypoints, i));
}

next_waypoint()
{
	integer count = llGetListLength(waypoints);
	if(count == 0 || !is_running)
	{
		say("No more waypoints to follow. Stopping.");
		stop();
		return;
	}

	vector waypoint = llList2Vector(waypoints, 0);
	waypoints = llDeleteSubList(waypoints, 0, 0);
	set_waypoint(waypoint);
}

say(string message)
{
	if(is_debugging) llOwnerSay(message);
}

integer set_waypoint(vector value)
{
	target = value;
	if(target == ZERO_VECTOR)
	{
		say("Cannot set waypoint to <0, 0, 0>. Stopping.");
		stop();
		return FALSE;
	}

	vector current_location = llGetPos();
	vector direction = target - current_location;
	float distance = llVecMag(direction);
	float time = llRound(45 * distance / max_speed)/45; // Round to the nearest 1/45. See llSetKeyframedMotion
	if(time < min_time) time = min_time;
	llSetKeyframedMotion([direction, ZERO_ROTATION, time], []);

	say("Waypoint set to " + (string)target + " over the next " + (string)time + "S.");

	is_running = TRUE;
	return TRUE;
}

start()
{
	is_running = TRUE;
	next_waypoint();
}

stop()
{
	is_running = FALSE;
	llSetKeyframedMotion([], []);
	say("Stopped.");
}

default
{
	link_message(integer sender_number, integer number, string message, key id)
	{
		if(number == ENGINE_CHANNEL) handle_message(message);
	}
	moving_end()
	{
		if(!is_running) return;

		if(check_waypoint())
			next_waypoint();
		else
			set_waypoint(target);
	}
}
