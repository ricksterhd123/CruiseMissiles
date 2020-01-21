
local rotSpeed = 60
local posX, posY, posZ = 0, 0, 5
local yaw, pitch, roll = 0, 0, 0
local MAX_POINTS = 5
local prevStartTick = 0
local prevDelayTick = 0
local lastPosition = {}

function fireRocket()
    local x, y, z = getElementPosition(localPlayer)
    lastPosition = {x, y, z}
    z = z + 20
    target = createProjectile(localPlayer, 20, x, y, z)
    setProjectileCounter(target, 600000)
    prevDelayTick = getTickCount()
end
bindKey("num_7", "down", fireRocket)
addCommandHandler("cmiss", fireRocket)

-- arbitrary rotation ZYX
function rotateZYX(matrix4x4, yaw, roll, pitch)
    local gamma = math.rad(yaw)
    local beta = math.rad(roll)
    local alpha = math.rad(pitch)
    local m = matrix(matrix4x4)
    local r = matrix({
        {math.cos(beta)*math.cos(gamma), math.cos(gamma)*math.sin(alpha)*math.sin(beta)-math.cos(alpha)*math.sin(gamma), math.cos(alpha)*math.cos(gamma)*math.sin(beta) + math.sin(alpha)*math.sin(gamma), 0},
        {math.cos(beta)*math.sin(gamma), math.cos(alpha)*math.cos(gamma)+math.sin(alpha)*math.sin(beta)*math.sin(gamma), -math.cos(gamma)*math.sin(alpha)+math.cos(alpha)*math.sin(beta)*math.sin(gamma), 0},
        {-math.sin(beta), math.cos(beta)*math.sin(alpha), math.cos(alpha)*math.cos(beta), 0},
        {0, 0, 0, 1}
    })
    return matrix.mul(m, r)
end

-- arbitrary rotation about uvw 
function rotateUVW(matrix4x4, u, v, w, angle)
    local theta = math.rad(angle)
    local m = matrix(matrix4x4)
    local r = matrix({
        {(u^2+(v^2+w^2)*math.cos(theta))/(u^2+v^2+w^2), (u*v*(1-math.cos(theta))-(w*math.sin(theta)*((u^2+v^2+w^2)^(1/2))))/(u^2+v^2+w^2), (u*w*(1-math.cos(theta))+v*((u^2+v^2+w^2)^(1/2))*math.sin(theta))/(u^2+v^2+w^2), 0},
        {(u*v*(1-math.cos(theta))+w*((u^2+v^2+w^2)^(1/2))*math.sin(theta))/(u^2+v^2+w^2), (v^2+(u^2+w^2)*math.cos(theta))/(u^2+v^2+w^2), (v*w*(1-math.cos(theta))-u*((u^2+v^2+w^2)^(1/2))*math.sin(theta))/(u^2+v^2+w^2), 0},
        {(u*w*(1-math.cos(theta))-v*((u^2+v^2+w^2)^(1/2))*math.sin(theta))/(u^2+v^2+w^2), (v*w*(1-math.cos(theta))+u*((u^2+v^2+w^2)^(1/2))*math.sin(theta))/(u^2+v^2+w^2), (w^2+(u^2+v^2)*math.cos(theta))/(u^2+v^2+w^2), 0},
        {0, 0, 0, 1}
    })
    return matrix.mul(m, r)
end

 local keys = {left = "arrow_l", right = "arrow_r", up = "arrow_u", down = "arrow_d"}
--local keys = {left = "num_4", right = "num_6", up = "num_2", down = "num_8"}
function main(timeSlice)
    if not target or not isElement(target) then return false end
    local tick = getTickCount()
    local matrix4x4 = getElementMatrix(target)
    local left, forward, up, pos = unpack(matrix4x4) -- vector3
    local yaw, pitch = 0, 0
    matrix4x4[4] = {0, 0, 0, 1}

    if getKeyState(keys.left) then
        yaw = -rotSpeed/1000 * timeSlice

    end
    if getKeyState(keys.right) then
        yaw = rotSpeed/1000 * timeSlice
    end

    if getKeyState(keys.up) then
        pitch = rotSpeed/1000 * timeSlice
    end

    if getKeyState(keys.down) then
        pitch = -rotSpeed/1000 * timeSlice
    end

    if not camera then
        camera = true
        addEventHandler("onClientRender", root, actionSceneCamera)
    end

    local speed = Vector3(getElementVelocity(target)):getLength()
    local velocity = -Vector3(forward):getNormalized()
    local vx, vy, vz = velocity:getX(), velocity:getY(), -velocity:getZ()
    local lX, lY, lZ = left[1], left[2], left[3]
    local uX, uY, uZ = up[1], up[2], up[3]
    local fX, fY, fZ = forward[1], forward[2], forward[3]

    -- dxDrawLine3D(pos[1], pos[2], pos[3], pos[1]+vx, pos[2]+vy, pos[3]+vz, tocolor(255, 0, 255), 5)
    -- dxDrawLine3D(pos[1], pos[2], pos[3], pos[1]+lX, pos[2]+lY, pos[3]+lZ, tocolor(255, 0, 0), 5)
    -- dxDrawLine3D(pos[1], pos[2], pos[3], pos[1]+fX, pos[2]+fY, pos[3]+fZ, tocolor(0, 255, 0), 5)
    -- dxDrawLine3D(pos[1], pos[2], pos[3], pos[1]+uX, pos[2]+uY, pos[3]+uZ, tocolor(0, 0, 255), 5)
    matrix4x4 = rotateZYX(matrix4x4, yaw, 0, 0)
    matrix4x4 = rotateUVW(matrix4x4, lX, lY, lZ, pitch)
    matrix4x4[4] = pos
    setElementMatrix(target, matrix4x4)
    setElementVelocity(target, vx, vy, vz)
end
addEventHandler("onClientPreRender", root, main)

local points = {}
local delay = 100
function actionSceneCamera()
    if target and isElement(target) then
        --local pos = Vector3(getElementPosition(target))
        local x, y, z = getElementPosition(target)
        points[#points + 1] = {x, y, z}
        if #points > MAX_POINTS then
            table.remove(points, 1)
        end

        if getTickCount() - prevDelayTick >= delay then
            if #points >= 2 then
                local ax, ay, az = points[1][1] , points[1][2] , points[1][3]
                local bx, by, bz = points[2][1] , points[2][2] , points[2][3]
                setCameraMatrix(ax, ay, az, bx, by, bz)
            end
        end
    else
        camera = false
        setCameraTarget(localPlayer)
        setElementPosition(localPlayer, lastPosition[1], lastPosition[2], lastPosition[3])
        removeEventHandler("onClientRender", root, actionSceneCamera)
    end
end