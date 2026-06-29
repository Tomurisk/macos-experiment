local swapTap = hs.eventtap.new(
    {hs.eventtap.event.types.keyDown, hs.eventtap.event.types.keyUp},
    function(event)
        local win = hs.window.focusedWindow()
        if not win then return false end

        local title = win:title()
        if not title or not title:match("PDF%-XChange Editor") then
            return false -- only act on windows whose title contains "PDF-XChange Editor"
        end

        local mods = event:getFlags()
        local newMods = {}

        -- Swap Cmd ↔ Ctrl
        if mods.cmd then newMods.ctrl = true end
        if mods.ctrl then newMods.cmd = true end

        -- Preserve other modifiers
        if mods.alt then newMods.alt = true end
        if mods.shift then newMods.shift = true end

        event:setFlags(newMods)
        return false
    end
)

swapTap:start()

return swapTap
