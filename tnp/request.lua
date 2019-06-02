-- tnp_request_assign()
--   Assigns a parked train to a player, marked as arrived.
function tnp_request_assign(player, target, train)
    tnp_request_setup(player, target, train, tnpdefines.train.status.arrived)

    if target then
        tnp_message(tnpdefines.loglevel.standard, player, {"tnp_train_waiting", target.backer_name})
    end
end

-- tnp_request_cancel()
--   Cancels a tnp request and removes all state tracking
function tnp_request_cancel(player, train, message)
    if player then
        if player.valid then
            player.set_shortcut_toggled('tnp-handle-request', false)
            tnp_gui_stationlist_close(player)

            if message then
                tnp_message(tnpdefines.loglevel.standard, player, message)
            end
        end

        tnp_state_player_delete(player, 'train')
    end

    if train then
        tnp_state_train_delete(train, false)
    end
end

-- tnp_request_create()
--   Attempts to create a new request for a tnp train
function tnp_request_create(player, target)
    local config = settings.get_player_settings(player)

    local train = target.get_stopped_train()
    if train and train.valid then
        if config['tnp-train-arrival-path'].value then
            tnp_draw_path(player, target)
        end

        tnp_request_assign(player, target, train)
        return true
    end

    local train = tnp_train_find(player, target)
    if not train then
        tnp_message(tnpdefines.loglevel.core, player, {"tnp_train_invalid"})
        return false
    end

    if config['tnp-train-arrival-path'].value then
        tnp_draw_path(player, target)
    end

    tnp_request_dispatch(player, target, train)
    return true
end

-- tnp_request_dispatch()
--   Dispatches a train
function tnp_request_dispatch(player, target, train)
    local config = settings.get_player_settings(player)

    tnp_request_setup(player, target, train, tnpdefines.train.status.dispatching)
    tnp_state_train_set(train, 'timeout', config['tnp-train-arrival-timeout'].value)

    local schedule = tnp_train_schedule_copy(train)
    local schedule_found = tnp_train_schedule_check(schedule, target.backer_name)

    if schedule_found == false then
        table.insert(schedule.records, {
            station = target.backer_name,
            wait_conditions = {
                {
                    type="time",
                    compare_type = "or",
                    ticks = config['tnp-train-boarding-timeout'].value*60
                }
            }
        })

        schedule.current = #schedule.records
    else
        schedule.current = schedule_found
    end

    tnp_train_enact(train, false, schedule, nil, false)

    tnp_message(tnpdefines.loglevel.core, player, {"tnp_train_requested", target.backer_name})
end


-- tnp_request_redispatch()
--   Redispatches a train for an onward journey
function tnp_request_redispatch(player, target, train)
    tnp_request_setup(player, target, train, tnpdefines.train.status.redispatched)

    local schedule = tnp_train_schedule_copy(train)
    local schedule_found = tnp_train_schedule_check(schedule, target.backer_name)

    if schedule_found == false then
        table.insert(schedule.records, {
            station = target.backer_name,
            wait_conditions = {
                {
                    type="passenger_not_present",
                    compare_type = "or"
                }
            }
        })

        schedule.current = #schedule.records
    else
        schedule.current = schedule_found
    end

    tnp_train_enact(train, false, schedule, nil, false)
end

-- tnp_request_setup()
--   Handles common setup logic for a train
function tnp_request_setup(player, target, train, status)
    tnp_state_train_set(train, 'player', player)
    tnp_state_player_set(player, 'train', train)

    if target then
        tnp_state_train_set(train, 'station', target)
    end

    tnp_state_train_set(train, 'status', status)
    tnp_train_info_save(train)

    player.set_shortcut_toggled('tnp-handle-request', true)
end