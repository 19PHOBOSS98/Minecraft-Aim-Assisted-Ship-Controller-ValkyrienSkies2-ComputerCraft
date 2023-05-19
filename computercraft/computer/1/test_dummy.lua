helm = peripheral.find("ship_helm")


stop = false
function moveShip()
	while true do
	term.clear()
	term.setCursorPos(1,1)
		if stop then
			helm.move("forward",false)
			helm.move("right",false)
			print("stopping")
			return
		end
		
		print("going")
		helm.move("forward",true)
		os.sleep(3)
		helm.move("forward",true)
		helm.move("right",true)
		os.sleep(0.925)
		helm.move("right",false)
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