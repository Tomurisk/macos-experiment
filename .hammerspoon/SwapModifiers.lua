local function inWine()
    local win = hs.window.focusedWindow()
    if not win then return false end
    local app = win:application()
    return app and app:name() == "wine"
end

local wineTap = hs.eventtap.new(
    {
        hs.eventtap.event.types.keyDown,
        hs.eventtap.event.types.keyUp,
        hs.eventtap.event.types.flagsChanged,
    },
    function(event)
        if not inWine() then return false end

        local mods = event:getFlags()
        local newMods = {}

        -- Pure swap: Cmd ⇄ Ctrl
        if mods.cmd  then newMods.ctrl = true end
        if mods.ctrl then newMods.cmd  = true end

        -- Preserve other modifiers
        if mods.alt   then newMods.alt   = true end
        if mods.shift then newMods.shift = true end
        if mods.fn    then newMods.fn    = true end

        event:setFlags(newMods)
        return false
    end
)

wineTap:start()
return wineTap
