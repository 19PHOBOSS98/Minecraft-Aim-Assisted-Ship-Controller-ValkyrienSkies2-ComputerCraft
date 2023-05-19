--KILL SWITCH--
rednet.open("back")




component_control_msg = {pos=vector.new(0,0,0),rot=vector.new(0,0,0)}

rednet.broadcast("dummy_stop","dummy_remote_controls")
	
