------------------------------------------------------------
-- CONFIG
------------------------------------------------------------
local pagesDir = os.getenv("HOME") .. "/Book pages"
------------------------------------------------------------
local function extractIdentifier(title)
    local id = title:match("^%[(.-)%] %- PDF%-XChange Editor$")
    if id then return id end
    id = title:match("^(.-)%* %- PDF%-XChange Editor$")
    if id then return id end
    id = title:match("^(.-) %- PDF%-XChange Editor$")
    if id then return id end
    return nil
end
------------------------------------------------------------
function runPagerScript()
    if _G.pagerLock then return end
    _G.pagerLock = true

    local win = hs.window.focusedWindow()
    if not win then
        hs.alert("No focused window")
        _G.pagerLock = false
        return
    end

    local title = win:title()
    local identifier = extractIdentifier(title)
    if not identifier or identifier == "" then
        hs.alert("Identifier not found")
        _G.pagerLock = false
        return
    end

    -- Ask user for page number
    local button, input = hs.dialog.textPrompt("Page number", "Enter page for: " .. identifier, "", "OK", "Cancel")

    -- Always refocus PDF-XChange immediately
    win:focus()

    if button == "Cancel" or not input or input == "" then
        _G.pagerLock = false
        return
    end

    local clip = input:gsub("%s+", "")
    if not clip:match("^[1-9][0-9]*$") then
        hs.alert("Not a valid page number: " .. clip)
        _G.pagerLock = false
        return
    end

    -- Delete old files matching identifier
    for file in hs.fs.dir(pagesDir) do
        if file ~= "." and file ~= ".." then
            if string.find(file, identifier, 1, true) then
                local removed, err = os.remove(pagesDir .. "/" .. file)
                if not removed then
                    hs.alert("Delete failed: " .. (err or "?"))
                end
            end
        end
    end

    -- Create new file
    local newName = string.format("[%s] %s", clip, identifier)
    local newPath = pagesDir .. "/" .. newName
    local f = io.open(newPath, "w")
    if f then
        f:write("")
        f:close()
        hs.alert("Created: " .. newName)
    else
        hs.alert("Failed to create file")
    end

    win:focus()
    _G.pagerLock = false
end
------------------------------------------------------------

hs.hotkey.bind({"cmd"}, "N", function()
    local win = hs.window.focusedWindow()
    if not win then return end
    local title = win:title()
    if title and title:match("PDF%-XChange Editor") then
        runPagerScript()
    else
        hs.eventtap.keyStroke({"cmd"}, "N", 0)
    end
end)