os.loadAPI("lib/quaternions.lua")
os.loadAPI("lib/pidcontrollers.lua")
os.loadAPI("lib/pid_utility.lua")

shipreader = peripheral.find("ship_reader")
radar = peripheral.find("radar")
rednet.open("front")

BOW = peripheral.wrap("top")
STERN = peripheral.wrap("bottom")

local sqrt = math.sqrt
local abs = math.abs
local max = math.max
local min = math.min
local mod = math.fmod
local clamp = pid_utility.clamp

term.clear()
term.setCursorPos(1,1)

--------------------------------------------------------------------------------
--the ship is actually built vertical with the front of the ship facing up so I have to rotate the ships default orientation to get it to face up--
function getOffsetDefaultShipOrientation(default_ship_orientation)
	offset_orientation = quaternions.Quaternion.fromRotation(default_ship_orientation:localPositiveX(), -90)*default_ship_orientation
	offset_orientation = quaternions.Quaternion.fromRotation(offset_orientation:localPositiveZ(), -45)*offset_orientation
	return offset_orientation
end

local ship_rotation = shipreader.getRotation(true)
ship_rotation = quaternions.Quaternion.new(ship_rotation.w,ship_rotation.x,ship_rotation.y,ship_rotation.z)
ship_rotation = getOffsetDefaultShipOrientation(ship_rotation)

local ship_global_position = shipreader.getWorldspacePosition()
ship_global_position = vector.new(ship_global_position.x,ship_global_position.y,ship_global_position.z)

local world_up_vector = vector.new(0,1,0)

local target_global_position = ship_global_position
local target_position_displacement = vector.new(0,0,0)
local target_rotation = ship_rotation


local target_rotation_delta = 20
local target_rotation_delta_multiplier = 0.1
local target_position_displacement_delta = 10
local target_position_displacement_delta_multiplier = 0.1

local debug_remote_id = 0 --for the pocket computer
local remote_control_id = 4 --for the Create Link Controller
local port_side_component_controller_id = 5 --left side onboard component controller
local starboard_side_component_controller_id = 8 --right side onboard component controller



function moveLocalXPositive()
	target_position_displacement = vector.new(1,0,0)*target_position_displacement_delta*target_position_displacement_delta_multiplier
end
function moveLocalXNegative()
	target_position_displacement = vector.new(-1,0,0)*target_position_displacement_delta*target_position_displacement_delta_multiplier
end
function moveLocalYPositive()
	target_position_displacement = vector.new(0,1,0)*target_position_displacement_delta*target_position_displacement_delta_multiplier
end
function moveLocalYNegative()
	target_position_displacement = vector.new(0,-1,0)*target_position_displacement_delta*target_position_displacement_delta_multiplier
end
function moveLocalZPositive()
	target_position_displacement = vector.new(0,0,1)*target_position_displacement_delta*target_position_displacement_delta_multiplier
end
function moveLocalZNegative()
	target_position_displacement = vector.new(0,0,-1)*target_position_displacement_delta*target_position_displacement_delta_multiplier
end

function spinLocalXPositive()
	local_rotation_axis = target_rotation:localPositiveX()
	target_rotation = quaternions.Quaternion.fromRotation(local_rotation_axis, target_rotation_delta*target_rotation_delta_multiplier)*target_rotation
end
function spinLocalXNegative()
	local_rotation_axis = target_rotation:localPositiveX()
	target_rotation = quaternions.Quaternion.fromRotation(local_rotation_axis, -target_rotation_delta*target_rotation_delta_multiplier)*target_rotation
end
function spinLocalYPositive()
	local_rotation_axis = target_rotation:localPositiveY()
	target_rotation = quaternions.Quaternion.fromRotation(local_rotation_axis, target_rotation_delta*target_rotation_delta_multiplier)*target_rotation
end
function spinLocalYNegative()
	local_rotation_axis = target_rotation:localPositiveY()
	target_rotation = quaternions.Quaternion.fromRotation(local_rotation_axis, -target_rotation_delta*target_rotation_delta_multiplier)*target_rotation
end
function spinLocalZPositive()
	local_rotation_axis = target_rotation:localPositiveZ()
	target_rotation = quaternions.Quaternion.fromRotation(local_rotation_axis, target_rotation_delta*target_rotation_delta_multiplier)*target_rotation
end
function spinLocalZNegative()
	local_rotation_axis = target_rotation:localPositiveZ()
	target_rotation = quaternions.Quaternion.fromRotation(local_rotation_axis, -target_rotation_delta*target_rotation_delta_multiplier)*target_rotation
end

function spinWorldYPositive()
	local_rotation_axis = world_up_vector
	target_rotation = quaternions.Quaternion.fromRotation(local_rotation_axis, target_rotation_delta)*target_rotation
end
function spinWorldYNegative()
	local_rotation_axis = world_up_vector
	target_rotation = quaternions.Quaternion.fromRotation(local_rotation_axis, -target_rotation_delta)*target_rotation
end

local orbit_radius = 1
local orbit_radius_delta = 2
local orbit_vector = vector.new(0,1,0)
local ORBIT_mode = false
local AUTO_TARGET = false

local radar_range = 500
local radar_scan_targets = radar.scan(radar_range)[1]
local orbital_target_index = 1
local index_scroll_direction = 1
--Create Link Controller Key binds--
--[[
Thanks to: codenio
https://stackoverflow.com/questions/37447704/what-is-the-alternative-for-switch-statement-in-lua-language
]]--
local previous_choice = ""
switch = function (choice)
	choice = choice and tonumber(choice) or choice
	
	if(choice == previous_choice) then
		target_position_displacement_delta_multiplier = min(target_position_displacement_delta_multiplier + 0.2,1)
			target_rotation_delta_multiplier = min(target_rotation_delta_multiplier + 0.5,1)
	else
		target_position_displacement_delta_multiplier = 0.1
		target_rotation_delta_multiplier = 0.1
	end
	previous_choice = choice
	case =
	{
	["toggle_AUTO_TARGET"] = function ( )
				AUTO_TARGET = not AUTO_TARGET
				if not AUTO_TARGET then
					ORBIT_mode = false
				end
			end,
	["toggle_ORBIT"] = function ( )
				if AUTO_TARGET then
					orbit_radius = sqrt(orbit_vector:dot(orbit_vector))
					ORBIT_mode = not ORBIT_mode
				end
			end,
	["scroll_target_up"] = function ( )
				if AUTO_TARGET then
					orbital_target_index = orbital_target_index + 1
					index_scroll_direction = 1
				end
			end,
	["scroll_target_down"] = function ( )
				if AUTO_TARGET then
					orbital_target_index = orbital_target_index - 1
					index_scroll_direction = -1
				end
			end,
	["reset_multiplier"] = function ( )
				target_position_displacement_delta_multiplier = 0.1
				target_rotation_delta_multiplier = 0.1
			end, 
	
	["w"] = function ( )
					if (ORBIT_mode) then
						moveLocalYPositive()
					else
						moveLocalZPositive()
					end
			end,                                            
	["s"] = function ( )
					if (ORBIT_mode) then
						moveLocalYNegative()
					else
						moveLocalZNegative()
					end
					
			end,
	["a"] = function ( )
					moveLocalXPositive()
			end,
	["d"] = function ( )
					moveLocalXNegative()
			end,
	["space"] = function ( )
					if (ORBIT_mode) then
						orbit_radius = max(orbit_radius - orbit_radius_delta,0)
					else
						moveLocalYPositive()
					end
			end,
	["shift"] = function ( )
					if (ORBIT_mode) then
						orbit_radius = orbit_radius + orbit_radius_delta
					else
						moveLocalYNegative()
					end
			end,
	["shift+a"] = function ( )
					spinLocalZNegative()
			end,
	["shift+d"] = function ( )
					spinLocalZPositive()
			end,
	["space+w"] = function ( )
				spinLocalXPositive()
			end,
	["space+s"] = function ( )
				spinLocalXNegative()
			end,
	["space+a"] = function ( )
					spinWorldYPositive()
			end,
	["space+d"] = function ( )
					spinWorldYNegative()
			end,
	["stop"] = function ( )
				target_position_displacement = vector.new(0,0,0)
			end,
	["realign"] = function ( )
				target_position_displacement = vector.new(0,0,0)
				target_rotation = quaternions.Quaternion.fromRotation(vector.new(0,1,0), 0)
			end,
	["hush"] = function ( ) --kill command
				applyRedStonePower(vector.new(0,0,0),vector.new(0,0,0))
				os.reboot()
			end,
	 default = function ( )
				print("default case executed")   
			end,
	}
	if case[choice] then
	 case[choice]()
	else
	 case["default"]()
	end
	
end

--orbit_Mode
--target_lock
--thanks to FrancisPostsHere: https://www.youtube.com/watch?v=ZfRaYTPUHCU
--https://pastebin.pl/view/e157c3e2
function quadraticSolver(a,b,c)--at^2 + bt + c = 0
	local sol_1=nil
	local sol_2=nil
	
	local discriminator = (b*b) - (4*a*c)
	local discriminator_squareroot = sqrt(abs(discriminator))
	local denominator = 2*a
	
	if (discriminator==0) then
		sol_1 = -b/d
		return discriminator,sol_1,sol_1
	elseif (discriminator>0) then
		sol_1 = ((-b)+discriminator_squareroot)/denominator
		sol_2 = ((-b)-discriminator_squareroot)/denominator
		return discriminator,sol_1,sol_2
	end
	
	return discriminator,sol_1,sol_2--I would use complex imaginary numbers but... meh
end



function getTargetOrbitPos(target_g_pos,target_g_vel,ship_g_pos,ship_g_vel,bullet_vel)

	local target_relative_pos = target_g_pos:sub(ship_g_pos)
	local target_relative_vel = target_g_vel:sub(ship_g_vel)
	local a = (target_relative_vel:dot(target_relative_vel))-(bullet_vel*bullet_vel)
	local b = 2 * (target_relative_pos:dot(target_relative_vel))
	local c = target_relative_pos:dot(target_relative_pos)

	local d,t1,t2 = quadraticSolver(a,b,c)
	local t = nil
	local target_global_orbit_pos = target_g_pos
	
	if (d>=0) then
		--[[
		positive_t1 = (t1>0)
		same_sign = (t1*t2)>0
		if (same_sign and positive_t1) then
			t=min(t1,t2)
		else
			t=max(t1,t2)
		end
		]]--
		
		t = (((t1*t2)>0) and (t1>0)) and min(t1,t2) or max(t1,t2)
		print("t: "..t)
		target_global_orbit_pos = target_g_pos:add(target_g_vel:mul(t))
		--target_global_orbit_pos = (target_relative_pos:add(target_relative_vel:mul(t))):add(ship_g_pos)
		
	end
	return target_global_orbit_pos
end


function adjustPositionToOrbit(target_g_pos,orbit_target_pos,radius)
	print("radius: "..radius)
	local radius_vector = (target_g_pos:sub(orbit_target_pos)):normalize()*radius
	print("radius_vector: "..radius_vector:tostring())
	return orbit_target_pos:add(radius_vector)
end



function receiveCommand()
	while true do
		local id,message = rednet.receive("remote_controls",1)
		if id==remote_control_id or id==debug_remote_id then
			if message then
				target_position_displacement = vector.new(0,0,0)
				switch(message)
			end

			local rotated_z_axis = ship_rotation:localPositiveZ()
			if ORBIT_mode then
				local rotated_x_axis = ship_rotation:localPositiveX()
				local rotated_y_axis = ship_rotation:localPositiveY()
				
				target_global_position = target_global_position:add(rotated_x_axis*target_position_displacement.x)
				target_global_position = target_global_position:add(rotated_y_axis*target_position_displacement.y)
				target_global_position = target_global_position:add(rotated_z_axis*target_position_displacement.z)
				
			else
				if (rotated_z_axis~=vector.new(0,1,0) and rotated_z_axis~=vector.new(0,-1,0)) then
					local world_up_local_x_axis = world_up_vector:cross(rotated_z_axis)
					world_up_local_x_axis = world_up_local_x_axis:normalize()

					local world_up_local_z_axis = world_up_local_x_axis:cross(world_up_vector)
					world_up_local_z_axis = world_up_local_z_axis:normalize()
					
					target_global_position = target_global_position:add(world_up_local_x_axis*target_position_displacement.x)
					target_global_position = target_global_position:add(world_up_local_z_axis*target_position_displacement.z)
					target_global_position = target_global_position:add(world_up_vector*target_position_displacement.y)
				end
			end

			
		else
			switch("reset_multiplier")
		end
	end
end

function applyRedStonePower(lin_mv,rot_mv)
	--Redstone signal for linear movement p==positive, n==negative--
	local lin_x_p = max(0,lin_mv.x)
	local lin_x_n = abs(min(0,lin_mv.x))
	local lin_y_p = max(0,lin_mv.y)
	local lin_y_n = abs(min(0,lin_mv.y))
	local lin_z_p = max(0,lin_mv.z)
	local lin_z_n = abs(min(0,lin_mv.z))

	--Redstone signal for angular movement p==positive, n==negative--
	local rot_x_p = max(0,rot_mv.x)
	local rot_x_n = abs(min(0,rot_mv.x))
	local rot_y_p = max(0,rot_mv.y)
	local rot_y_n = abs(min(0,rot_mv.y))
	local rot_z_p = max(0,rot_mv.z)
	local rot_z_n = abs(min(0,rot_mv.z))
	
	local BF = lin_z_p --BOW FORWARD thruster
	
	local BUL = lin_x_p+lin_y_p+rot_x_n+rot_y_p+rot_z_n
	local BUR = lin_x_n+lin_y_p+rot_x_n+rot_y_n+rot_z_p
	local BDL = lin_x_p+lin_y_n+rot_x_p+rot_y_p+rot_z_p
	local BDR = lin_x_n+lin_y_n+rot_x_p+rot_y_n+rot_z_n
	
	local SB = lin_z_n --STERN BACKWARD thruster
	
	local SUL = lin_x_p+lin_y_p+rot_x_p+rot_y_n+rot_z_n
	local SUR = lin_x_n+lin_y_p+rot_x_p+rot_y_p+rot_z_p
	local SDL = lin_x_p+lin_y_n+rot_x_n+rot_y_n+rot_z_p
	local SDR = lin_x_n+lin_y_n+rot_x_n+rot_y_p+rot_z_n
	--[[
	print("BF: "..BF)
	print("BUL: "..BUL)
	print("BUR: "..BUR)
	print("BDL: "..BDL)
	print("BDR: "..BDR)
	
	print("\nSB: "..SB)
	print("SUL: "..SUL)
	print("SUR: "..SUR)
	print("SDL: "..SDL)
	print("SDR: "..SDR)
	]]--
	BOW.setAnalogOutput("front", BF)
	STERN.setAnalogOutput("back", SB)

	BOW.setAnalogOutput("bottom", BDR)
	STERN.setAnalogOutput("bottom", SDR)
	
	BOW.setAnalogOutput("top", BUL)
	STERN.setAnalogOutput("top", SUL)
	
	BOW.setAnalogOutput("left", BDL)
	STERN.setAnalogOutput("left", SDL)
	
	BOW.setAnalogOutput("right", BUR)
	STERN.setAnalogOutput("right", SUR)
end

function getLocalPositionError(trg_g_pos,current_g_pos,current_rot)
	local trg_l_pos = trg_g_pos - current_g_pos
	trg_l_pos = current_rot:inv():rotateVector3(trg_l_pos) --target position in the ship's perspective
	return trg_l_pos
end

--want to learn more about quaternions? here's a simple tutorial video by sociamix that should get you started: https://youtu.be/1yoFjjJRnLY
local rotation_difference = quaternions.Quaternion.fromRotation(vector.new(0,1,0), 0)

function getQuaternionRotationError(target_rot,current_rot)
	rotation_difference = target_rot * current_rot:inv()--TODO MAKE THIS A LOCAL VARIABLE
	local error_magnitude = rotation_difference:rotationAngle()
	local rotation_axis = rotation_difference:rotationAxis()
	local local_rotation = current_rot:inv():rotateVector3(rotation_axis) --have to reorient target rotation axis to the ship's perspective
	return local_rotation:mul(error_magnitude)
end

function loopScrollIndex(indx,limit)
	return mod(indx-1+limit,limit)+1
end

function calculateMovement()
	local min_time_step = 0.05 --how fast the computer should continuously loop (the max is 0.05 for ComputerCraft)
	local ship_mass = shipreader.getMass()
	local gravity_acceleration_vector = vector.new(0,-9.8,0)
	
	local max_redstone = 15
	
	local mod_configured_thruster_speed = 55000 --make sure to check the VS2-Tournament mod config 
	local thruster_tier=2--make sure ALL the tournament thrusters are upgraded to level 5
	
	
	local inv_active_thrusters_per_linear_movement = vector.new(1/4,1/4,1) --the number of thruster responsible for each axis of linear movement... but they're inverted
	local inv_active_thrusters_per_angular_movement = vector.new(1/4,1/4,1/4) --the number of thruster responsible for each axis of angular movement... but they're inverted
	
	local base_thruster_force = mod_configured_thruster_speed*thruster_tier --thruster force when powered with 1 redstone(from VS2-Tournament code)
	
	local inv_base_thruster_force = 1/base_thruster_force --the base thruster force... but it's inverted
	--it's easier for the computer to use the multiplicatio operator them instead of dividing them over and over again (I'm not really sure if this applies to Lua, I just know that this is what (should) generally go on in your CPU hardware)
	
	local max_thruster_force = max_redstone*base_thruster_force
	local max_linear_acceleration = max_thruster_force/ship_mass --for PID Integral clamping
	
	--I used Create Schematics to build local inertia tensor.. I built my own java project to get this--
	--these values are specific for 0sun_ray_v4.nbt--
	local local_inertia_tensor = {
		x=vector.new(301889.55029585795,-9.805489753489383E-13,1.546140993013978E-11),
		y=vector.new(-9.805489753489383E-13,426078.57801307994,82704.32252897555),
		z=vector.new(1.546140993013978E-11,82704.32252897555,355870.97228277783)
	}
	local local_inertia_tensor_inv = {
		x=vector.new(3.312469739412906E-6,3.723778946337488E-23,-1.5256984385101195E-22),
		y=vector.new(3.723778946337488E-23,2.4578592975187952E-6,-5.712058692758763E-7),
		z=vector.new(-1.5256984385101212E-22,-5.712058692758771E-7,2.942755313043317E-6)
	}

	--also specific for 0sun_ray_v4.nbt--
	local U_R_D_L_thruster_position = vector.new(1,1,0)

	
	--the ship is actually built vertical with the front of the ship facing up so I have to get the thruster position relative to the new ship orientation--
	local new_local_orientation = quaternions.Quaternion.fromRotation(vector.new(1,0,0), -90)
	new_local_orientation = quaternions.Quaternion.fromRotation(new_local_orientation:localPositiveZ(), -45)*new_local_orientation
	
	local new_local_x_axis = new_local_orientation:rotateVector3(vector.new(1,0,0))
	local new_local_y_axis = new_local_orientation:rotateVector3(vector.new(0,1,0))
	local new_local_z_axis = new_local_orientation:rotateVector3(vector.new(0,0,1))
	
	local new_local_U_R_D_L_thruster_position = vector.new(0,0,0)
	new_local_U_R_D_L_thruster_position.x = new_local_x_axis:dot(U_R_D_L_thruster_position)
	new_local_U_R_D_L_thruster_position.y = new_local_y_axis:dot(U_R_D_L_thruster_position)
	new_local_U_R_D_L_thruster_position.z = new_local_z_axis:dot(U_R_D_L_thruster_position)
	
	local thruster_distances_from_axes = vector.new(0,0,0)
	thruster_distances_from_axes.x = vector.new(0,new_local_U_R_D_L_thruster_position.y,new_local_U_R_D_L_thruster_position.z):length()
	thruster_distances_from_axes.y = vector.new(new_local_U_R_D_L_thruster_position.x,0,new_local_U_R_D_L_thruster_position.z):length()
	thruster_distances_from_axes.z = vector.new(new_local_U_R_D_L_thruster_position.x,new_local_U_R_D_L_thruster_position.y,0):length()
	
	
	local perpendicular_force = base_thruster_force*math.sin(math.pi/4)--the rotation thrusters are all at an angle of 45 degrees
	
	--multiply this with the PID calculated torque to get the needed redstone power for the thruster--
	local torque_redstone_coefficient_for_x_axis = 1/(thruster_distances_from_axes.x*perpendicular_force)
	local torque_redstone_coefficient_for_y_axis = 1/(thruster_distances_from_axes.y*perpendicular_force)
	local torque_redstone_coefficient_for_z_axis = 1/(thruster_distances_from_axes.z*perpendicular_force)
	
	--for PID output (and Integral) clamping--
	local max_perpendicular_force = max_thruster_force*math.sin(math.pi/4)
	
	local torque_saturation = vector.new(0,0,0)
	torque_saturation.x = thruster_distances_from_axes.x * (max_perpendicular_force)
	torque_saturation.y = thruster_distances_from_axes.y * (max_perpendicular_force)--should actually be using cosine instead of sine but... meh
	torque_saturation.z = thruster_distances_from_axes.z * (max_perpendicular_force)
	
	local max_angular_acceleration = vector.new(0,0,0)
	max_angular_acceleration.x = torque_saturation:dot(local_inertia_tensor_inv.x)
	max_angular_acceleration.y = torque_saturation:dot(local_inertia_tensor_inv.y)
	max_angular_acceleration.z = torque_saturation:dot(local_inertia_tensor_inv.z)
	
	--PID Controllers--
	local pos_PID = pidcontrollers.PID_PWM(3,0,5,-max_linear_acceleration,max_linear_acceleration)
	
	local rot_x_PID = pidcontrollers.PID_PWM_scalar(0.15,0,0.1,-max_angular_acceleration.x,max_angular_acceleration.x)
	local rot_y_PID = pidcontrollers.PID_PWM_scalar(0.15,0,0.15,-max_angular_acceleration.y,max_angular_acceleration.y)
	local rot_z_PID = pidcontrollers.PID_PWM_scalar(0.17,0,0.12,-max_angular_acceleration.z,max_angular_acceleration.z)
	
	--Error Based Distributed PWM Algorithm by NikZapp for finer control over the redstone thrusters--
	local linear_pwm = pid_utility.pwm()
	local angular_pwm = pid_utility.pwm()
	
	local autocannon_barrel_count = 5
	local bullet_velocity = autocannon_barrel_count/0.05
	orbital_target_index = 1
	
	local remote_control_ship_id = 3
	while true do
		term.clear()
		term.setCursorPos(1,1)
		
		print("ship_mass: "..ship_mass)
		
		if (AUTO_TARGET) then
			radar_scan_targets = radar.scan(radar_range)[1]
			local radar_scan_targets_table_size = #radar_scan_targets
			
			if (radar_scan_targets_table_size>1) then
			
				my_id = shipreader.getShipID()
				
				ship_global_velocity = shipreader.getVelocity()

				orbital_target_index = loopScrollIndex(orbital_target_index,radar_scan_targets_table_size)
				
				local radar_target_id = radar_scan_targets[orbital_target_index].id
				if( radar_target_id == my_id or radar_target_id == remote_control_ship_id) then
					orbital_target_index = loopScrollIndex(orbital_target_index+index_scroll_direction,radar_scan_targets_table_size)
				end
				
				local radar_target_global_position = radar_scan_targets[orbital_target_index].position
				local radar_target_global_velocity = radar_scan_targets[orbital_target_index].velocity
				
				if (radar_target_global_position) then
					radar_target_global_position = vector.new(radar_target_global_position.x,radar_target_global_position.y,radar_target_global_position.z)
				else
					radar_target_global_position = vector.new(0,0,0)
				end
				
				
				print("radar_target_global_position: "..radar_target_global_position:tostring())
				

				if (radar_target_global_velocity) then
					radar_target_global_velocity = vector.new(radar_target_global_velocity.x,radar_target_global_velocity.y,radar_target_global_velocity.z)
				else
					radar_target_global_velocity = vector.new(0,0,0)
				end
				
				--print("radar_target_global_velocity: "..radar_target_global_velocity:tostring())
				--orbit_target_position = radar_target_global_position
				orbit_target_position = getTargetOrbitPos(radar_target_global_position,radar_target_global_velocity,target_global_position,ship_global_velocity,bullet_velocity)
				print("\ntarget_global_position: "..target_global_position:tostring())
				print("\norbit_target_position: "..orbit_target_position:tostring())
				
				orbit_vector = orbit_target_position:sub(target_global_position)
				
				print("\norbit_vector: "..orbit_vector:normalize():tostring())
				print("\ntarget_rotationZ: "..target_rotation:localPositiveZ():tostring())
				
				target_rotation = quaternions.Quaternion.fromToRotation(target_rotation:localPositiveZ(), orbit_vector:normalize())*target_rotation
				if (ORBIT_mode) then
					target_global_position = adjustPositionToOrbit(target_global_position,orbit_target_position,orbit_radius)
				end
			
			end
			
		end
		
		ship_rotation = shipreader.getRotation(true)
		ship_rotation = quaternions.Quaternion.new(ship_rotation.w,ship_rotation.x,ship_rotation.y,ship_rotation.z)
		ship_rotation = getOffsetDefaultShipOrientation(ship_rotation)
		
		ship_global_position = shipreader.getWorldspacePosition()
		ship_global_position = vector.new(ship_global_position.x,ship_global_position.y,ship_global_position.z)


		--FOR ANGULAR MOVEMENT--
		rotation_error = getQuaternionRotationError(target_rotation,ship_rotation) --The difference between the ship's current rotation and the ship's target rotation
		
		--print("\nrotation_error: \nX:"..rotation_error.x.."\nY:"..rotation_error.y.."\nZ:"..rotation_error.z)

		pid_output_angular_acceleration = vector.new(0,0,0)
		pid_output_angular_acceleration.x = rot_x_PID:run(rotation_error.x)
		pid_output_angular_acceleration.y = rot_y_PID:run(rotation_error.y)
		pid_output_angular_acceleration.z = rot_z_PID:run(rotation_error.z)
		
		distributed_net_torque = vector.new(0,0,0)
		distributed_net_torque.x = pid_output_angular_acceleration:dot(local_inertia_tensor.x)
		distributed_net_torque.y = pid_output_angular_acceleration:dot(local_inertia_tensor.y)
		distributed_net_torque.z = pid_output_angular_acceleration:dot(local_inertia_tensor.z)
		
		--I divide the calculated torque to the apointed thrusters--
		distributed_net_torque.x = distributed_net_torque.x*inv_active_thrusters_per_angular_movement.x
		distributed_net_torque.y = distributed_net_torque.y*inv_active_thrusters_per_angular_movement.y
		distributed_net_torque.z = distributed_net_torque.z*inv_active_thrusters_per_angular_movement.z

		calculated_angular_RS_PID = distributed_net_torque
		
		--convert calculated torque to redstone signal--
		calculated_angular_RS_PID.x = calculated_angular_RS_PID.x*torque_redstone_coefficient_for_x_axis
		calculated_angular_RS_PID.y = calculated_angular_RS_PID.y*torque_redstone_coefficient_for_y_axis
		calculated_angular_RS_PID.z = calculated_angular_RS_PID.z*torque_redstone_coefficient_for_z_axis
		
		calculated_angular_RS_PID = angular_pwm:run(calculated_angular_RS_PID)
		
		--print("\ncalculated_angular_RS_PID: "..calculated_angular_RS_PID:tostring())
		
		
		
		--FOR LINEAR MOVEMENT--
		position_error = getLocalPositionError(target_global_position,ship_global_position,ship_rotation)--The difference between the ship's current position and the ship's target position
		
		--print("\nposition_error: \nX:"..position_error.x.."\nY:"..position_error.y.."\nZ:"..position_error.z)
		
		
		local_gravity_acceleration = ship_rotation:inv():rotateVector3(gravity_acceleration_vector)--the gravity vector in the ship's perspective
		
		pid_output_linear_acceleration = pos_PID:run(position_error)
		net_linear_acceleration = pid_output_linear_acceleration:sub(local_gravity_acceleration)
		distributed_linear_net_force = net_linear_acceleration:mul(ship_mass)

		--the thrusters responsible for vertical and side-to-side movement are at an angle of 45 degrees (pi/4)
		distributed_linear_net_force.x = distributed_linear_net_force.x/math.sin(math.pi/4)
		distributed_linear_net_force.y = distributed_linear_net_force.y/math.sin(math.pi/4)
		
		distributed_linear_net_force.x = distributed_linear_net_force.x*inv_active_thrusters_per_linear_movement.x
		distributed_linear_net_force.y = distributed_linear_net_force.y*inv_active_thrusters_per_linear_movement.y
		distributed_linear_net_force.z = distributed_linear_net_force.z*inv_active_thrusters_per_linear_movement.z
		
		
		calculated_linear_RS_PID = distributed_linear_net_force:mul(inv_base_thruster_force)--convert calculated thrust to redstone signal

		
		calculated_linear_RS_PID = linear_pwm:run(calculated_linear_RS_PID)
		--print("\ncalculated_linear_RS_PID: "..calculated_linear_RS_PID:tostring())
		
		
		--[[
		--purely for DEBUGGING--
		rotated_z_axis_debug = ship_rotation:localPositiveZ()
		rotated_y_axis_debug = ship_rotation:localPositiveY()
		print("\nrotated_z_axis_debug: "..rotated_z_axis_debug:tostring())
		print("rotated_y_axis_debug: "..rotated_y_axis_debug:tostring())
		--purely for DEBUGGING--
		]]--
		
		
		applyRedStonePower(calculated_linear_RS_PID,calculated_angular_RS_PID)
		
		sleep(min_time_step)
	end
end



parallel.waitForAny(receiveCommand, calculateMovement)
