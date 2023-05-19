--PLANE--
os.loadAPI("lib/quaternions.lua")

helm = peripheral.find("ship_helm")
shipreader = peripheral.find("ship_reader")
monitor = peripheral.find("monitor")
rednet.open("bottom")

function newLine()
	x,y = monitor.getCursorPos()
	monitor.setCursorPos(1,y+1)
end

stop = false

local dummy_remote_control_id = 0

function receiveCommand()
	while true do
		local id,message = rednet.receive("dummy_remote_controls",1)
		
		if id==dummy_remote_control_id then
			if message=="dummy_stop" then
				
				stop = true
			end
		end
	end
end


function moveShip()
	local anchor_block = vector.new(-106.5,shipreader.getWorldspacePosition().y,154.5)
	local radius = 5
	local is_counter_clockwise = false
	monitor.setTextScale(0.5)
	while true do
		helm.move("forward",true)
		term.clear()
		term.setCursorPos(1,1)
		monitor.clear()
		monitor.setCursorPos(1,1)
		
		monitor.write("Vel: ")
		newLine()
		vel = shipreader.getVelocity()
		vel = vector.new(vel.x,vel.y,vel.z)
		monitor.write(string.format("%.3f",vel:length()))
		monitor.write(" m/s")
		
		ship_rotation = shipreader.getRotation(true)
		ship_rotation = quaternions.Quaternion.new(ship_rotation.w,ship_rotation.x,ship_rotation.y,ship_rotation.z)
		
		ship_forward_vector = -ship_rotation:localPositiveX()
		
		print("ship_forward_vector: "..ship_forward_vector:tostring())
		
		ship_global_position = shipreader.getWorldspacePosition()
		ship_global_position = vector.new(ship_global_position.x,ship_global_position.y,ship_global_position.z)
		
		current_distance_vector = anchor_block:sub(ship_global_position)
	
		current_distance_magnitude = math.sqrt(current_distance_vector:dot(current_distance_vector))
		
		steering_error = ship_forward_vector:dot(current_distance_vector:normalize())
		
		radius_error = (radius-current_distance_magnitude)/radius
		
		
		distance_weight = 0.65
		steering_weight = 1
		steer = radius_error*distance_weight + steering_error*steering_weight
		
		print("steer: "..steer)
		
		positive_steer = steer>0.1
		negative_steer = steer<-0.1
		if(is_counter_clockwise)then
			print("is_counter_clockwise")
			print("right: ",positive_steer)
			print("left: ",negative_steer)
			helm.move("right",positive_steer)
			helm.move("left",negative_steer)
		else
			print("is_not_counter_clockwise")
			print("left: ",positive_steer)
			print("right: ",negative_steer)
			
			helm.move("left",positive_steer)
			helm.move("right",negative_steer)
		end
		
		
		if stop then
			helm.move("forward",false)
			helm.move("right",false)
			helm.move("left",false)
			print("stopping")
			return
		end
		os.sleep(0.05)

	end
end

function stopProgram()
	while true do
		local event, key, isHeld = os.pullEvent("key")
		if isHeld then
			helm.move("forward",false)
			helm.move("right",false)
			stop = true
			return
		end
	end
end

parallel.waitForAny(moveShip,stopProgram,receiveCommand)