-- RedCube API by Gonow32 and CathrodeRayTube
-- Designed for the RedCube games console
-- Modified for use with CubeBrew.
 
function clearScr(backColour, textColour)
  term.setBackgroundColour(backColour)
  term.setTextColour(textColour)
  term.clear()
  term.setCursorPos(1,1)
end

function resetCursor()
  term.setCursorPos(1,1)
end

function checkForSaveFolder()
  if fs.exists("saves") and fs.isDir("saves") then
    return true
  else
    return false
  end
end
 
function clear()
  term.clear()
  term.setCursorPos(1,1)
end
 
function drmCheck()
  rednet.open("top")
  if fs.exists("/disk/.copyprotect") then
    local file = fs.open("disk/.copyprotect", "r")
    rednet.send(2340, "checkcode")
    sleep(1)
    rednet.send(2340, file.readAll())
    file.close()
    local id, message = rednet.receive(4)
    if message == "yes" or not message then
      return true
    else
      return false
    end
  else
    return false
  end
end
 
function quickReboot(...)
sleep(...)
os.reboot()
end
