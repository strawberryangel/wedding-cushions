string ENGINE_ADD = "add"; // Add waypoint.
string ENGINE_CLEAR = "clear"; // Clear all waypoints.
string ENGINE_DEBUG = "debug"; // Turn debugging information on/off.
string ENGINE_LIST = "list"; // List waypoints.
string ENGINE_RESUME = "resume"; // Resume travel to target.
string ENGINE_SPEED = "speed"; // Set maximum speed.
string ENGINE_START = "start"; // Start playing through waypoints.
string ENGINE_STOP = "stop"; // Stop movement.
//
integer ENGINE_CHANNEL = 51489145; // Link message ID to listen for.
float DEFAULT_SPEED  = 5.0; // m/S

integer is_debugging = FALSE;
vector target = ZERO_VECTOR; // Current destination.
float target_range = 0.25; // How close do we need to get to a waypoint to call ourselves "arrived?"
float min_time = 0.11111111111111111111111111111111; // 5/45;
float max_speed = DEFAULT_SPEED;
integer is_running = FALSE;
list waypoints = []; // Strided list. (destination, speed)

add_waypoint(vector target)
{
	// State: Any
	// Result: Unchanged.
	if(target != ZERO_VECTOR)
	{
		float speed = max_speed;
		if(speed == 0) speed = DEFAULT_SPEED;

		waypoints = waypoints + [target, speed];
		say("Added waypoint " + (string)target + " at speed " + (string)speed + "m/S");
	}
	else
		say("Refusing to add zero vector as a waypoint.");
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

rotation face()
{
	if(target == ZERO_VECTOR) return ZERO_ROTATION;

	vector current = llRot2Euler(llGetRot());
	float current_angle = current.z;
	say("Current facing = " + (string)(current_angle * RAD_TO_DEG));

	vector direction = target - llGetPos();
	float direction_angle = llAtan2(direction.y, direction.x);
	say("Target facing = " + (string)(direction_angle * RAD_TO_DEG));

	//return llEuler2Rot(<0, 0, direction_angle>);
	return llEuler2Rot(<0, 0, direction_angle - current_angle>);
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
		if(command == ENGINE_CLEAR) clear_waypoints();
		else if(command == ENGINE_LIST) list_waypoints();
		else if(command == ENGINE_RESUME) set_waypoint(target);
		else if(command == ENGINE_START) start();
		else if(command == ENGINE_STOP) stop();
		return;
	}

	// Two-part commands
	string param1 = llList2String(parsed, 1);

	if(command == ENGINE_ADD)
	{
		vector target = (vector)param1;
		add_waypoint(target);
	}
	else if(command == ENGINE_DEBUG)
	{
		is_debugging = !!(integer)param1;
		llOwnerSay("Debugging set to: " + (string)is_debugging);
	}
	else if(command == ENGINE_SPEED)
	{
		float speed = (float)param1;
		if(speed > 0)
		{
			max_speed = speed;
			say("Setting speed to: " + (string)speed);

		}
		else
			say("Refusing to set speed to: " + (string)speed);
	}
}

list_waypoints()
{
	integer length = llGetListLength(waypoints);
	say("Waypoints: " + (string)(length/2));

	integer i;
	for(i=0; i < length; i += 2)
		say((string)llList2Vector(waypoints, i) + " at " +  (string)llList2Float(waypoints, i+1) + "m/S");
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
	float speed = llList2Float(waypoints, 1);
	waypoints = llDeleteSubList(waypoints, 0, 1); // Remove strided items from head of queue.
	max_speed = speed;
	set_waypoint(waypoint);
}

say(string message)
{
	if(is_debugging) llOwnerSay(message);
}

set_waypoint(vector value)
{
	target = value;
	if(target == ZERO_VECTOR)
	{
		say("Cannot set waypoint to <0, 0, 0>. Stopping.");
		stop();
		return;
	}

	vector current_location = llGetPos();
	vector direction = target - current_location;
	float distance = llVecMag(direction);

	rotation facing = face();
	float time = llRound(45 * distance / max_speed)/45; // Round to the nearest 1/45. See llSetKeyframedMotion
	if(time < min_time) time = min_time;
	llSetKeyframedMotion([direction, facing, time], []);

	say("Waypoint set to " + (string)target + " over the next " + (string)time + "S.");

	is_running = TRUE;
	return;
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
