--KILL SWITCH--
rednet.open("back")


main_controller_id = 11

component_control_msg = {pos=vector.new(0,0,0),rot=vector.new(0,0,0)}

rednet.send(main_controller_id,"hush","remote_controls")
	
