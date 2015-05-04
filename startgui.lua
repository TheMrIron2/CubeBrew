--RedCube GUI By Gonow32 and CathrodeRayTube
--Clock coded by DreamWave
 
os.loadAPI("CubeAPI")
local menu = 0
local w,h = term.getSize()
 
if term.isColor() == false then
  error("This GUI can not be run on monochrome computers.")
end
 
function drawTaskbar()
  term.setCursorPos(1,h)
  paintutils.drawLine(1, h, w, h, colours.red)
  term.setCursorPos(1,h)
  term.setBackgroundColour(colours.green)
  term.setTextColour(colours.white)
  term.write("(Start)")
  term.setBackgroundColour(colours.black)
  term.setCursorPos(1,1)
end
 
--error("I reached here!")
 
function drawDesktop()
  term.current().setVisible(false)
  term.setBackgroundColour(colours.white)
  term.clear()
  term.setCursorPos(1,1)
  --error("I reached here")
  image = paintutils.loadImage(".background")
  paintutils.drawImage(image, 1, 1)
  drawTaskbar()
  term.current().setVisible(true)
end
 
function drawStart()
  term.setCursorPos(1,h-1)
  term.write("          ")
  term.setCursorPos(1,h-2)
  term.write(" Restart  ")
  term.setCursorPos(1,h-3)
  term.write(" Shutdown ")
  term.setCursorPos(1,h-4)
  term.write(" Run      ")
  term.setCursorPos(1,h-5)
  term.write(" Paint    ")
  term.setCursorPos(1,h-6)
  term.write(" RedSpace ")
  term.setCursorPos(1,h-7)
  term.write("          ")
end
 
drawDesktop()
 
--error("I reached here!")
 
function updateClock()
  term.setBackgroundColor(colors.red)
  local time = textutils.formatTime(os.time(), false)
  term.setCursorPos(w - #time - 1, h)
  write(time)
end
 
while true do
  updateClock()
  os.startTimer(.5)
 
  local event, button, x, y = os.pullEventRaw()
  if event == "mouse_click" then
    if x >= 1 and x <= 7 and y == h and menu == 0 then
      drawDesktop()
      drawStart()
      menu = 1
    elseif x >= 1 and x <= 10 and y == h - 3 and menu == 1 then
      os.shutdown()
    elseif x >= 1 and x <= 10 and y == h - 2 and menu == 1 then
      os.reboot()
    elseif x >= 1 and x <= 10 and y == h - 4 and menu == 1 then
      drawDesktop()
      menu = 0
    elseif x >= 1 and x <= 10 and y == h - 5 and menu == 1 then
      term.setBackgroundColour(colours.black)
      term.setTextColour(colours.white)
      term.clear()
      term.setCursorPos(2,2)
      term.write("Enter new/existing file name: ")
      filename1 = read()
      shell.run("paint "..filename1)
      drawDesktop()
      menu = 0
    elseif x >= 1 and x <= 10 and y == h - 6 and menu == 1 then
      term.setBackgroundColour(colours.black)
      term.setTextColour(colours.white)
      term.clear()
      term.setCursorPos(2,2)
      term.write("Enter server ID: ")
      textid = read()
      if not tonumber(textid) then
         
      else
        rednet.send(tonumber(textid), "get")
        local id2, message2 = rednet.receive(0.5)
        term.clear()
        if message then
          print(message)
          sleep(10)
        end
      end
      drawDesktop()
    else
      drawDesktop()
      menu = 0
    end
  elseif event == "disk" then
    CubeAPI.clearScr(colours.black, colours.white)
    if fs.exists("disk/.copyprotect") then
      file = fs.open("disk/.copyprotect", "r")
      rednet.send(1907, "checkcode")
      rednet.send(1907, file.readAll())
      file.close()
      local id, message = rednet.receive(4)
      if message == "yes" or not message then
        if fs.exists("disk/startgame") then
          shell.run("disk/startgame")
          drawDesktop()
        else
          textutils.slowPrint("There is a problem with your disk. Please return it to the retailer.")
          sleep(2)
          disk.eject("right")
          os.reboot()
        end
      else
        print("Don't copy that floppy.")
        disk.eject("right")
        sleep(2)
        os.reboot()
      end
    else
      print("Don't copy that floppy.")
      disk.eject("right")
      sleep(2)
      os.reboot()
    end
  elseif event == "timer" then
    updateClock()
  end
end
 
function drmCheck()
  if fs.exists("disk/.copyprotect") then
    file = fs.open("disk/.copyprotect", "r")
    rednet.send(2340, "checkcode")
    rednet.send(2340, file.readAll())
    file.close()
    local id, message = rednet.receive(4)
    if message == "yes" or not message then
      if fs.exists("disk/startgame") then
        shell.run("disk/startgame")
      else
        textutils.slowPrint("Game file not found. Going to desktop.")
      end
    else
      print("Don't copy that floppy.")
      disk.eject("right")
      sleep(2)
      os.reboot()
    end
  else
    print("Don't copy that floppy.")
    disk.eject("right")
    sleep(2)
    os.reboot()
  end
end
