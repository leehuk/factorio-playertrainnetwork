--[[
    State Table:
        element         = LuaGuiElement
        station         = int, if this is a station gui its the station index
]]

-- _tnp_state_gui_prune()
--   Clears invalid state information about LuaGuiElements
function _tnp_state_gui_prune()
    if not global.gui_data then
        return
    end

    for id, ent in pairs(global.gui_data) do
        if not ent.valid then
            global.gui_data[id] = nil
        end
    end
end

-- tnp_state_gui_delete()
--   Deletes state information about a LuaGuiElement
function tnp_state_gui_delete(element)
    if not global.gui_data then
        return
    end

    global.gui_data[element.index] = nil
end

-- tnp_state_gui_get()
--   Gets state information about a LuaGuiElement
function tnp_state_gui_get(element, key)
    _tnp_state_gui_prune()

    if not global.gui_data then
        return nil
    end

    if global.gui_data[element.index] then
        return global.gui_data[element.index][key]
    end

    return nil
end

-- tnp_state_gui_set()
--   Sets state information about a LuiGuiElement
function tnp_state_gui_set(element, key, value)
    _tnp_state_gui_prune()

    if not global.gui_data then
        global.gui_data = {}
    end

    if not global.gui_data[element.index] then
        global.gui_data[element.index] = {}
        global.gui_data[element.index]['element'] = element
    end

    global.gui_data[element.index][key] = value
end