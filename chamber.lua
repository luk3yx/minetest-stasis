--
-- Minetest stasis mod - Stasis chambers
--

stasis.register_chamber = function(name, def)
    if not def.groups then
        def.groups = {}
    end
    def.groups.attached_node = 1
    
    if def.drawtype == 'stasis_chamber' then
        def.drawtype = 'nodebox'
        if not def.node_box then
            def.node_box = {
                type = 'fixed',
                fixed = {-0.5, -0.5, -0.5, 1.5, 0.3, 0.5},
            }
        end
        def.collision_box = def.node_box
        def.selection_box = def.node_box
        def.paramtype = 'light'
        def.paramtype2 = 'facedir'
    end
    
    local on_rightclick = def.on_rightclick
    
    def.on_rightclick = function(pos, node, player)
        if on_rightclick and on_rightclick(pos, node, player) then
            return
        end
        
        local victim = player:get_player_name()
        
        -- Knockout integration
        if knockout and knockout.carrying[victim] then
            victim = knockout.carrying[victim]
        end
        
        if stasis.frozen_players[victim] then return end
        minetest.swap_node(pos, {
            name = name .. '_active',
            param2 = node.param2,
        })
        
        local meta = minetest.get_meta(pos)
        meta:set_string('victim', victim)
        
        stasis.freeze_player(victim, pos, name)
    end
    
    minetest.register_node(':' .. name, def)
    
    -- Active def
    active_def = {}
    for key, value in pairs(def) do
        active_def[key] = value
    end
    
    if def.tiles_active then
        active_def.tiles = def.tiles_active
    end
    
    active_def.description = (def.description or name) .. ' (active)'
    active_def.groups.not_in_creative_inventory = 1
    active_def.drop = {}
    
    active_def.on_rightclick = function(pos, node, player)
        local meta = minetest.get_meta(pos)
        local victim = meta:get_string('victim')
        
        minetest.swap_node(pos, {name = name, param2 = node.param2})
        
        if victim and #victim > 0 and stasis.frozen_players[victim] then
            stasis.unfreeze_player(victim)
        end
        
        return false
    end
    
    active_def.can_dig = function(pos, player)
        if player.is_fake_player then return true end
        local victim = minetest.get_meta(pos):get_string('victim')
        if victim == player:get_player_name() then
            minetest.chat_send_player(victim, 'You cannot destroy your own stasis chamber!')
            return false
        end
        return true
    end
    
    active_def.after_dig_node = function(pos, oldnode, meta, player)
        player:get_inventory():add_item('main', stasis.begin_transit(meta.fields.victim, name))
    end
    active_def.on_construct = nil
    active_def.on_dig = nil
    
    minetest.register_node(':' .. name .. '_active', active_def)
end

-- The default chamber
stasis.register_chamber('stasis:chamber', {
    description = "Admin stasis chamber",
    tiles = {'default_steel_block.png^[colorize:#0008^default_glass.png',
             'default_steel_block.png', 'default_steel_block.png',
             'default_steel_block.png', 'default_steel_block.png',
             'default_steel_block.png', 'default_steel_block.png',
             'default_steel_block.png'},
    tiles_active = {'default_steel_block.png^[colorize:#0008^stasis_player.png^default_glass.png',
             'default_steel_block.png', 'default_steel_block.png',
             'default_steel_block.png', 'default_steel_block.png',
             'default_steel_block.png', 'default_steel_block.png',
             'default_steel_block.png'},
    groups = {dig_immediate = 2},
    drawtype = 'stasis_chamber',
    
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string('infotext', 'Stasis chamber')
    end,
    
    --on_rightclick = function(pos, node, player)
    --    if not minetest.get_player_privs(player:get_player_name()).privs then
    --        minetest.chat_send_player(player:get_player_name(), 'Permission denied!')
    --        return true
    --    end
    --end,
})
