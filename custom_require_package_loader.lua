package.loaders[#package.loaders + 1] = function(name)
    if not name:find("^lupus590%.") then
        return nil, "not a Lupus590 module"
    end

    -- TODO: it would be nice if this could be added to startup
    -- I don't fancy making a custom shell

    -- strip off namespace and extention, convert to path, and put the extention back on
    name = name:gsub("^lupus590%.", ""):gsub("%.lua$",""):gsub("%.", "/")..".lua"

    local localPathRoot = "/.cache/lupus590/"

    -- build in doesn't have pocket and advanced and such like APIs do, if this changes then we just need to add the appropriate part here
    local paths = {"main/", n=1}
    if turtle then
        paths.n = paths.n + 1
        paths[paths.n] = "turtle/"
    end
    if command then
        paths.n = paths.n + 1
        paths[paths.n] = "command/"
    end

    local rootUrl = "https://raw.githubusercontent.com/Lupus590-CC/CC-Survival-Programs/master/assets/computercraft/lua/rom/modules/"

    local downloadErrors = {n=0}
    for _, path in ipairs(paths) do
        local localPath = localPathRoot .. path .. name
        if not fs.exists(localPath) then
            local url = rootUrl .. path .. "lupus590/" .. name
            local request, err = http.get(url)
            if request then
                io.open(localPath, "w"):write(request.readAll()):close()
                request.close()
            else
                downloadErrors.n = downloadErrors.n + 1
                downloadErrors[downloadErrors.n] = "Cannot download " .. url .. ": " .. err
            end
        end

        if fs.exists(localPath) then
            local fn, err = loadfile(localPath, nil, _ENV)
            if fn then
                return fn, localPath
            else
                return nil, err
            end
        end
    end
    return nil, table.concat(downloadErrors, "\n")
end
