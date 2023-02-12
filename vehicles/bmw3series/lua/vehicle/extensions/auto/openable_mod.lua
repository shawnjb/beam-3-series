--- @diagnostic disable: undefined-global

local M = {}
local modAttached = false
local override = false

local couplerCache = {}
local couplerTags = {}

local function has_value(nTable, nValue)
    for index, value in pairs(nTable) do
        if value == nValue then
            return true
        end
    end
    return false
end

local function CloseParts()
    if string.find(tostring(v.data.options.partName), "wigeon") then
        electrics.values['doorlatch_L'] = 0
        electrics.values['doorlatch_R'] = 0
        electrics.values['canopy_latch'] = 0
    end

    electrics.values['trunk'] = 0
    electrics.values['hood'] = 0
    electrics.values['doorFL'] = 0
    electrics.values['doorFR'] = 0
    electrics.values['doorRL'] = 0
    electrics.values['doorRR'] = 0
end

local function getNodeID(name)
    local nodeID = nil
    for k, node in pairs(v.data.nodes) do
        if tostring(node.name) == tostring(name) then
            return node.cid
        end
    end
    return null
end

local function AdjustSpringStrength(node1, node2, strength)
    node1 = getNodeID(node1)
    node2 = getNodeID(node2)

    for k, beam in pairs(v.data.beams) do
        if string.find(tostring(beam.breakGroup), "_Openable") == nil then
            if (beam.id1 == node1 and beam.id2 == node2) or (beam.id2 == node1 and beam.id1 == node2) then
                beam.beamDamp = strength
                beam.beamSpring = strength

                obj:setBeamSpringDamp(beam.cid, beam.beamSpring, beam.beamDamp, -1, -1)
            end
        end
    end
end

local function BreakBeamFromNodes(node1, node2)
    for k, beam in pairs(v.data.beams) do
        if string.find(tostring(beam.breakGroup), "_Openable") == nil then
            if beam.id1 == node1 and beam.id2 == node2 then
                obj:breakBeam(k)
            elseif beam.id2 == node1 and beam.id1 == node2 then
                obj:breakBeam(k)
            end
        end
    end
end

local function removeNodeCollision(node)
    local NORMALTYPE = 0
    local NODE_FIXED = 1

    local ntype = NORMALTYPE
    if node.fixed == true then
        ntype = NODE_FIXED
    end

    local collision
    if node.collision ~= nil then
        collision = node.collision
    else
        collision = true
    end

    local selfCollision
    if node.selfCollision ~= nil then
        selfCollision = node.selfCollision
    else
        selfCollision = false
    end

    local staticCollision
    if node.staticCollision ~= nil then
        staticCollision = node.staticCollision
    else
        staticCollision = true
    end

    local frictionCoef = type(node.frictionCoef) == 'number' and node.frictionCoef or 1
    local slidingFrictionCoef = type(node.slidingFrictionCoef) == 'number' and node.slidingFrictionCoef or frictionCoef
    local noLoadCoef = type(node.noLoadCoef) == 'number' and node.noLoadCoef or 1
    local fullLoadCoef = type(node.fullLoadCoef) == 'number' and node.fullLoadCoef or 0
    local loadSensitivitySlope = type(node.loadSensitivitySlope) == 'number' and node.loadSensitivitySlope or 0

    local nodeWeight = node.nodeWeight or 0

    local nodeMaterialTypeID
    if node.nodeMaterial ~= nil then
        nodeMaterialTypeID = node.nodeMaterial
        if type(nodeMaterialTypeID) ~= "number" then
            log_jbeam('D', "jbeam.pushToPhysics", "invalid node material id:" .. tostring(nodeMaterialTypeID))
            nodeMaterialTypeID = 0
        end
    else
        nodeMaterialTypeID = 0
    end

    local pos = vec3(obj:getNodePosition(node.cid))
    obj:setNode(node.cid, pos.x, pos.y, pos.z, nodeWeight, ntype, frictionCoef, slidingFrictionCoef,
        node.stribeckExponent or 1.75, node.stribeckVelMult or 1, noLoadCoef, fullLoadCoef, loadSensitivitySlope,
        node.softnessCoef or 0.5, node.treadCoef or 0.5, node.tag or '', node.couplerStrength or math.huge,
        node.firstGroup or -1, false, collision, staticCollision, nodeMaterialTypeID)
end

local function breakConnectingBeams()
    CloseParts()
    for k, beam in pairs(v.data.beams) do
        if (string.find(tostring(beam.breakGroup), "_Openable") ~= nil) then
            modAttached = true
        end

        if beam.breakGroup ~= nil and beam.breakGroup ~= "" then
            if string.find(tostring(beam.breakGroup), "hoodlatch") ~= nil or
                string.find(tostring(beam.breakGroup), "tailgatelatch") ~= nil or
                string.find(tostring(beam.breakGroup), "trunklatch") ~= nil or
                string.find(tostring(beam.breakGroup), "doorlatch") ~= nil then
                if string.find(tostring(beam.breakGroup), "_Openable") == nil then
                    if (modAttached or override) then
                        obj:breakBeam(k)
                    end
                end
            end

            if string.find(tostring(v.data.options.partName), "wendover") then
                if string.find(tostring(beam.breakGroupType), "1") ~= nil and
                    string.find(tostring(beam.breakGroup), "hoodhinge") then
                    if string.find(tostring(beam.breakGroup), "_Openable") == nil then
                        if (modAttached or override) then
                            obj:breakBeam(k)
                        end
                    end
                end
                if string.find(tostring(beam.beamType), "BOUNDED") ~= nil and
                    string.find(tostring(beam.breakGroup), "hoodhinge") then
                    if string.find(tostring(beam.breakGroup), "_Openable") == nil then
                        if (modAttached or override) then
                            obj:breakBeam(k)
                        end
                    end
                end
            end

            if string.find(tostring(v.data.options.partName), "vivace") then
                if string.find(tostring(beam.breakGroup), "latch") ~= nil then
                    if string.find(tostring(beam.breakGroup), "_Openable") == nil then
                        if (modAttached or override) then
                            obj:breakBeam(k)
                        end
                    end
                end
            end
        end
    end

    if (modAttached) then
        local n = {}

        if string.find(tostring(v.data.options.partName), "coupe") then
            n[0] = getNodeID('d4l')
            n[1] = getNodeID('d4r')

            AdjustSpringStrength('d7l', 'd8l', 0)
            AdjustSpringStrength('d7l', 'd9l', 0)
            AdjustSpringStrength('d7l', 'd10l', 0)
            AdjustSpringStrength('d7l', 'd11l', 0)
            AdjustSpringStrength('d7l', 'd12l', 0)
            AdjustSpringStrength('d7l', 'd13l', 0)
            AdjustSpringStrength('d7r', 'd8r', 0)
            AdjustSpringStrength('d7r', 'd9r', 0)
            AdjustSpringStrength('d7r', 'd10r', 0)
            AdjustSpringStrength('d7r', 'd11r', 0)
            AdjustSpringStrength('d7r', 'd12r', 0)
            AdjustSpringStrength('d7r', 'd13r', 0)

            BreakBeamFromNodes(getNodeID('f15'), getNodeID('h5'))
            BreakBeamFromNodes(getNodeID('f15'), getNodeID('h4'))
            BreakBeamFromNodes(getNodeID('f15r'), getNodeID('h5r'))
            BreakBeamFromNodes(getNodeID('f15l'), getNodeID('h5l'))
            BreakBeamFromNodes(getNodeID('fb1l'), getNodeID('h4l'))
            BreakBeamFromNodes(getNodeID('fb1r'), getNodeID('h4r'))
            BreakBeamFromNodes(getNodeID('fb1l'), getNodeID('h5l'))
            BreakBeamFromNodes(getNodeID('fb1r'), getNodeID('h5r'))
        end

        if string.find(tostring(v.data.options.partName), "vivace") then
            n[0] = getNodeID('t5ll')
            n[1] = getNodeID('t5rr')

            n[2] = getNodeID('t1')
            n[3] = getNodeID('t1l')
            n[4] = getNodeID('t1r')

            BreakBeamFromNodes(getNodeID('t3rr'), getNodeID('r3rr'))
            BreakBeamFromNodes(getNodeID('t3ll'), getNodeID('r3ll'))
            BreakBeamFromNodes(getNodeID('sh2l'), getNodeID('t3ll'))
            BreakBeamFromNodes(getNodeID('sh2r'), getNodeID('t3rr'))
            BreakBeamFromNodes(getNodeID('rb2'), getNodeID('t5'))
        end

        if string.find(tostring(v.data.options.partName), "etk800") then
            n[0] = getNodeID('d4l')
            n[1] = getNodeID('d7l')
            n[3] = getNodeID('d4r')
            n[4] = getNodeID('d7r')
            n[2] = getNodeID('d17l')
            n[5] = getNodeID('d17r')

            AdjustSpringStrength('d7l', 'd8l', 0)
            AdjustSpringStrength('d7l', 'd9l', 0)
            AdjustSpringStrength('d7l', 'd10l', 0)
            AdjustSpringStrength('d7l', 'd11l', 0)
            AdjustSpringStrength('d7l', 'd12l', 0)
            AdjustSpringStrength('d7l', 'd13l', 0)
            AdjustSpringStrength('d7r', 'd8r', 0)
            AdjustSpringStrength('d7r', 'd9r', 0)
            AdjustSpringStrength('d7r', 'd10r', 0)
            AdjustSpringStrength('d7r', 'd11r', 0)
            AdjustSpringStrength('d7r', 'd12r', 0)
            AdjustSpringStrength('d7r', 'd13r', 0)

            BreakBeamFromNodes(getNodeID('h4l'), getNodeID('he3l'))
            BreakBeamFromNodes(getNodeID('h4r'), getNodeID('he3r'))
            BreakBeamFromNodes(getNodeID('p11l'), getNodeID('t3ll'))
            BreakBeamFromNodes(getNodeID('p11r'), getNodeID('t3rr'))
        end

        if string.find(tostring(v.data.options.partName), "fullsize") then
            n[0] = getNodeID('h5')

            AdjustSpringStrength('d7l', 'd8l', 0)
            AdjustSpringStrength('d7l', 'd9l', 0)
            AdjustSpringStrength('d7l', 'd10l', 0)
            AdjustSpringStrength('d7l', 'd11l', 0)
            AdjustSpringStrength('d7l', 'd12l', 0)
            AdjustSpringStrength('d7l', 'd13l', 0)
            AdjustSpringStrength('d7r', 'd8r', 0)
            AdjustSpringStrength('d7r', 'd9r', 0)
            AdjustSpringStrength('d7r', 'd10r', 0)
            AdjustSpringStrength('d7r', 'd11r', 0)
            AdjustSpringStrength('d7r', 'd12r', 0)
            AdjustSpringStrength('d7r', 'd13r', 0)

            BreakBeamFromNodes(getNodeID('h4l'), getNodeID('he3l'))
            BreakBeamFromNodes(getNodeID('h4r'), getNodeID('he3r'))
            BreakBeamFromNodes(getNodeID('h4l'), getNodeID('he5l'))
            BreakBeamFromNodes(getNodeID('h4r'), getNodeID('he5r'))
        end

        if string.find(tostring(v.data.options.partName), "hatch") then
            n[0] = getNodeID('d1l')
            n[1] = getNodeID('d4l')
            n[2] = getNodeID('d7l')
            n[3] = getNodeID('d1r')
            n[4] = getNodeID('d4r')
            n[5] = getNodeID('d7r')

            BreakBeamFromNodes(getNodeID('t4rr'), getNodeID('tl2r'))
            BreakBeamFromNodes(getNodeID('t4ll'), getNodeID('tl2l'))
            BreakBeamFromNodes(getNodeID('t4r'), getNodeID('tl4r'))
            BreakBeamFromNodes(getNodeID('t4l'), getNodeID('tl4l'))
            BreakBeamFromNodes(getNodeID('f14rr'), getNodeID('h2rr'))
            BreakBeamFromNodes(getNodeID('f14ll'), getNodeID('h2ll'))
            BreakBeamFromNodes(getNodeID('h4r'), getNodeID('he1r'))
            BreakBeamFromNodes(getNodeID('h4l'), getNodeID('he1l'))
        end

        if string.find(tostring(v.data.options.partName), "legran") then
            n[0] = getNodeID('d1l')
            n[1] = getNodeID('d4l')
            n[2] = getNodeID('d7l')
            n[3] = getNodeID('d1r')
            n[4] = getNodeID('d4r')
            n[5] = getNodeID('d7r')
            n[6] = getNodeID('d15l')
            n[7] = getNodeID('d18l')
            n[8] = getNodeID('d21l')
            n[9] = getNodeID('d15r')
            n[10] = getNodeID('d18r')
            n[11] = getNodeID('d21r')
            n[12] = getNodeID('tl3l')
            n[13] = getNodeID('tl3r')
            n[14] = getNodeID('t4')
            n[15] = getNodeID('t4l')
            n[16] = getNodeID('t4r')
            n[17] = getNodeID('t4ll')
            n[18] = getNodeID('t4rr')

            AdjustSpringStrength('d7l', 'd8l', 0)
            AdjustSpringStrength('d7l', 'd9l', 0)
            AdjustSpringStrength('d7l', 'd10l', 0)
            AdjustSpringStrength('d7l', 'd11l', 0)
            AdjustSpringStrength('d7l', 'd12l', 0)
            AdjustSpringStrength('d7l', 'd13l', 0)
            AdjustSpringStrength('d7r', 'd8r', 0)
            AdjustSpringStrength('d7r', 'd9r', 0)
            AdjustSpringStrength('d7r', 'd10r', 0)
            AdjustSpringStrength('d7r', 'd11r', 0)
            AdjustSpringStrength('d7r', 'd12r', 0)
            AdjustSpringStrength('d7r', 'd13r', 0)

            AdjustSpringStrength('t3l', 'r8ll', 0)
            AdjustSpringStrength('t3r', 'r8rr', 0)
            AdjustSpringStrength('t3ll', 'r3ll', 0)
            AdjustSpringStrength('t3rr', 'r3rr', 0)

            BreakBeamFromNodes(getNodeID('d18l'), getNodeID('f8l'))
            BreakBeamFromNodes(getNodeID('d18r'), getNodeID('f8r'))
            BreakBeamFromNodes(getNodeID('f15'), getNodeID('h4'))
        end

        if string.find(tostring(v.data.options.partName), "midsize") then
            n[0] = getNodeID('d1l')
            n[1] = getNodeID('d4l')
            n[2] = getNodeID('d7l')
            n[3] = getNodeID('d1r')
            n[4] = getNodeID('d4r')
            n[5] = getNodeID('d7r')

            AdjustSpringStrength('t3l', 'r7ll', 0)
            AdjustSpringStrength('t3r', 'r7rr', 0)

            BreakBeamFromNodes(getNodeID('g1'), getNodeID('h4'))
            BreakBeamFromNodes(getNodeID('g1l'), getNodeID('h4l'))
            BreakBeamFromNodes(getNodeID('g1r'), getNodeID('h4r'))
            BreakBeamFromNodes(getNodeID('h4l'), getNodeID('he1l'))
            BreakBeamFromNodes(getNodeID('h4r'), getNodeID('he1r'))
            BreakBeamFromNodes(getNodeID('fb1'), getNodeID('h4'))
            BreakBeamFromNodes(getNodeID('fb1l'), getNodeID('h4l'))
            BreakBeamFromNodes(getNodeID('fb1r'), getNodeID('h4r'))
            BreakBeamFromNodes(getNodeID('fb1'), getNodeID('h5'))
            BreakBeamFromNodes(getNodeID('fb1l'), getNodeID('h5l'))
            BreakBeamFromNodes(getNodeID('fb1r'), getNodeID('h5r'))
            BreakBeamFromNodes(getNodeID('fb2'), getNodeID('h4'))
            BreakBeamFromNodes(getNodeID('fe12l'), getNodeID('h4l'))
            BreakBeamFromNodes(getNodeID('fe12r'), getNodeID('h4r'))
            BreakBeamFromNodes(getNodeID('fe12l'), getNodeID('h4ll'))
            BreakBeamFromNodes(getNodeID('fe12r'), getNodeID('h4rr'))
            BreakBeamFromNodes(getNodeID('f15'), getNodeID('h4'))
            BreakBeamFromNodes(getNodeID('f15'), getNodeID('h5'))
            BreakBeamFromNodes(getNodeID('f15l'), getNodeID('h5l'))
            BreakBeamFromNodes(getNodeID('f15r'), getNodeID('h5r'))
        end

        if string.find(tostring(v.data.options.partName), "pessima") then
            AdjustSpringStrength('d7l', 'd8l', 0)
            AdjustSpringStrength('d7l', 'd9l', 0)
            AdjustSpringStrength('d7l', 'd10l', 0)
            AdjustSpringStrength('d7l', 'd11l', 0)
            AdjustSpringStrength('d7l', 'd12l', 0)
            AdjustSpringStrength('d7l', 'd13l', 0)
            AdjustSpringStrength('d7r', 'd8r', 0)
            AdjustSpringStrength('d7r', 'd9r', 0)
            AdjustSpringStrength('d7r', 'd10r', 0)
            AdjustSpringStrength('d7r', 'd11r', 0)
            AdjustSpringStrength('d7r', 'd12r', 0)
            AdjustSpringStrength('d7r', 'd13r', 0)

            AdjustSpringStrength('t3ll', 'r3ll', 0)
            AdjustSpringStrength('t3rr', 'r3rr', 0)

            BreakBeamFromNodes(getNodeID('g1'), getNodeID('h4'))
            BreakBeamFromNodes(getNodeID('g1l'), getNodeID('h4l'))
            BreakBeamFromNodes(getNodeID('g1r'), getNodeID('h4r'))
            BreakBeamFromNodes(getNodeID('h4l'), getNodeID('he1l'))
            BreakBeamFromNodes(getNodeID('h4r'), getNodeID('he1r'))
            BreakBeamFromNodes(getNodeID('fb1'), getNodeID('h4'))
            BreakBeamFromNodes(getNodeID('fb1l'), getNodeID('h4l'))
            BreakBeamFromNodes(getNodeID('fb1r'), getNodeID('h4r'))
        end

        if string.find(tostring(v.data.options.partName), "sbr") then
            n[0] = getNodeID('he1l')
            n[1] = getNodeID('he1r')

            BreakBeamFromNodes(getNodeID('f11ll'), getNodeID('h4l'))
            BreakBeamFromNodes(getNodeID('f11rr'), getNodeID('h4r'))
            BreakBeamFromNodes(getNodeID('fb1'), getNodeID('h4'))
            BreakBeamFromNodes(getNodeID('fb1l'), getNodeID('h4ll'))
            BreakBeamFromNodes(getNodeID('fb1r'), getNodeID('h4rr'))
            BreakBeamFromNodes(getNodeID('t4ll'), getNodeID('tl2l'))
            BreakBeamFromNodes(getNodeID('t4rr'), getNodeID('tl2r'))
            BreakBeamFromNodes(getNodeID('t4l'), getNodeID('tl1l'))
            BreakBeamFromNodes(getNodeID('t4r'), getNodeID('tl1r'))
        end

        if string.find(tostring(v.data.options.partName), "sunburst") then
            n[0] = getNodeID('tl1l')
            n[1] = getNodeID('tl3l')
            n[2] = getNodeID('tl1r')
            n[3] = getNodeID('tl3r')
            n[4] = getNodeID('rb1l')
            n[5] = getNodeID('rb1r')

            BreakBeamFromNodes(getNodeID('f15'), getNodeID('h4'))
            BreakBeamFromNodes(getNodeID('fb1'), getNodeID('h4'))
            BreakBeamFromNodes(getNodeID('fb1'), getNodeID('h5'))
            BreakBeamFromNodes(getNodeID('fb1l'), getNodeID('h5l'))
            BreakBeamFromNodes(getNodeID('fb1r'), getNodeID('h5r'))
            BreakBeamFromNodes(getNodeID('fb1l'), getNodeID('h4l'))
            BreakBeamFromNodes(getNodeID('fb1r'), getNodeID('h4r'))
            BreakBeamFromNodes(getNodeID('f15l'), getNodeID('h5l'))
            BreakBeamFromNodes(getNodeID('f15r'), getNodeID('h5r'))
            BreakBeamFromNodes(getNodeID('h4l'), getNodeID('he3l'))
            BreakBeamFromNodes(getNodeID('h4r'), getNodeID('he3r'))
        end

        if string.find(tostring(v.data.options.partName), "bolide") then

            AdjustSpringStrength('6fl', 'tb1l', 0)
            AdjustSpringStrength('tg3r', 'tb1r', 0)
            AdjustSpringStrength('fx4l', 'h1l', 0)
            AdjustSpringStrength('fx4r', 'h1r', 0)
        end

        if string.find(tostring(v.data.options.partName), "etki") then
            n[0] = getNodeID('d1l')
            n[1] = getNodeID('d4l')
            n[2] = getNodeID('d7l')
            n[3] = getNodeID('d1r')
            n[4] = getNodeID('d4r')
            n[5] = getNodeID('d7r')
            n[6] = getNodeID('d17l')
            n[7] = getNodeID('d17r')

            AdjustSpringStrength('d7l', 'd8l', 0)
            AdjustSpringStrength('d7l', 'd9l', 0)
            AdjustSpringStrength('d7l', 'd10l', 0)
            AdjustSpringStrength('d7l', 'd11l', 0)
            AdjustSpringStrength('d7l', 'd12l', 0)
            AdjustSpringStrength('d7l', 'd13l', 0)
            AdjustSpringStrength('d7r', 'd8r', 0)
            AdjustSpringStrength('d7r', 'd9r', 0)
            AdjustSpringStrength('d7r', 'd10r', 0)
            AdjustSpringStrength('d7r', 'd11r', 0)
            AdjustSpringStrength('d7r', 'd12r', 0)
            AdjustSpringStrength('d7r', 'd13r', 0)

            BreakBeamFromNodes(getNodeID('g1'), getNodeID('h4'))
            BreakBeamFromNodes(getNodeID('g1r'), getNodeID('h4r'))
            BreakBeamFromNodes(getNodeID('g1l'), getNodeID('h4l'))
            BreakBeamFromNodes(getNodeID('f15'), getNodeID('h4'))
            BreakBeamFromNodes(getNodeID('h4l'), getNodeID('he1l'))
            BreakBeamFromNodes(getNodeID('h4r'), getNodeID('he1r'))
        end

        if string.find(tostring(v.data.options.partName), "wendover") then
            AdjustSpringStrength('t3l', 'r8ll', 0)
            AdjustSpringStrength('t3r', 'r8rr', 0)
        end

        if string.find(tostring(v.data.options.partName), "bastion") then
            n[0] = getNodeID('d18l')
            n[1] = getNodeID('d18r')

            AdjustSpringStrength('q3r', 't3rr', 0)
            AdjustSpringStrength('q3l', 't3ll', 0)

            BreakBeamFromNodes(getNodeID('d5r'), getNodeID('d18r'))
            BreakBeamFromNodes(getNodeID('d5l'), getNodeID('d18l'))

            BreakBeamFromNodes(getNodeID('d2l'), getNodeID('sk2ll'))
            BreakBeamFromNodes(getNodeID('d2r'), getNodeID('sk2rr'))
            BreakBeamFromNodes(getNodeID('d3l'), getNodeID('sk3l'))
            BreakBeamFromNodes(getNodeID('d3r'), getNodeID('sk3r'))
            BreakBeamFromNodes(getNodeID('d3l'), getNodeID('sk3ll'))
            BreakBeamFromNodes(getNodeID('d3r'), getNodeID('sk3rr'))
        end

        for k, node in pairs(v.data.nodes) do
            if has_value(n, k) then
                removeNodeCollision(node)
            end
        end
    end
end

function OpenPart(node1, node2, originalSpring, openValue)
    node1 = getNodeID(node1)
    node2 = getNodeID(node2)

    if originalSpring == 0 then
        originalSpring = 2000000
    end

    for k, beam in pairs(v.data.beams) do
        if beam.beamPrecompression == 1 and string.find(tostring(beam.breakGroup), "_Openable") ~= nil then
            if (beam.id1 == node1 and beam.id2 == node2) or (beam.id2 == node1 and beam.id1 == node2) then
                if openValue ~= 0 then
                    beam.beamSpring = 0
                    beam.beamDamp = 0
                else
                    beam.beamSpring = originalSpring
                    beam.beamDamp = 10
                end

                obj:setBeamSpringDamp(beam.cid, beam.beamSpring, beam.beamDamp, -1, -1)
            end
        end
    end
end

M.onReset = breakConnectingBeams
M.onInit = CloseParts

return M
