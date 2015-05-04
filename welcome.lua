--[[-- JakeUtils API: Commands
-- sPrint("text")     -- Slowprint any text
-- center("text")     -- center text to middle of any screen
-- rainbowPrint("text") -- print text in ALOT of colors!
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
function sPrint(text)
  textutils.slowPrint(text)
end]]--
function center(text)
  maxX, maxY = term.getSize()
  curX, curY = term.getCursorPos()
  sub = #text / 2
  cenX = maxX / 2 - sub
  term.setCursorPos(cenX, maxY / 2)
  print(text)
end
function rainbowPrint(text)
  for i=1,#text do
    term.setTextColor(math.pow(math.random(1,15),4))
    write(string.sub(text,i,i))
  end
end
term.setBackgroundColor(colors.lightBlue)
term.clear()
term.setTextColor(colors.white)
center("Welcome!")
sleep(0.25)
term.setBackgroundColor(colors.blue)
term.clear()
center("Welcome!")
sleep(2)
