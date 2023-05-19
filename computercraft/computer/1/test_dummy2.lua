helm = peripheral.find("ship_helm")
shipreader = peripheral.find("ship_reader")

function turnLeft()
	helm.move("right",false)
	helm.move("left",true)
end

function turnRight()
	helm.move("right",true)
	helm.move("left",false)
end

stop = false
function moveShip()
	local anchor_block = vector.new(~,~,~)
	local radius = 5
	while true do
	term.clear()
	term.setCursorPos(1,1)
	
	helm.move("forward",true)
	
	ship_rotation = shipreader.getRotation(true)
	ship_rotation = quaternions.Quaternion.new(ship_rotation.w,ship_rotation.x,ship_rotation.y,ship_rotation.z)
	
	ship_z_axis = ship_rotation:localPositiveZ()
	
	ship_global_position = shipreader.getWorldspacePosition()
	ship_global_position = vector.new(ship_global_position.x,ship_global_position.y,ship_global_position.z)
	
	current_distance_vector = ship_global_position:sub(anchor_block)
	current_distance_magnitude = sqr(current_distance_vector:dot(current_distance_vector))
	
	steering_error = ship_z_axis:dot(current_distance_vector:normalize())
	
	radius_error = (current_distance_magnitude-radius)
	
	distance_weight = 0.05
	steering_weight = 0.2
	steer = radius_error*distance_weight + steering_error*steering_weight -- + left; - right
	
	helm.move("right",steer<0)
	helm.move("left",steer>0)
	
	
	
	
	
	if stop then
		helm.move("forward",false)
		helm.move("right",false)
		helm.move("left",false)
		print("stopping")
		return
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

parallel.waitForAny(moveShip,stopProgram)