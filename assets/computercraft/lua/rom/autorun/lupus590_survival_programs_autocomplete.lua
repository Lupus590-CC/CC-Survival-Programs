local executeOrRun = shell.execute or shell.run
if turtle then
    executeOrRun("dig.lua", "addShellComplete")
end
