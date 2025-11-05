-- written by groverbuger for g3d
-- september 2021
-- MIT license

----------------------------------------------------------------------------------------------------
-- simple obj loader
----------------------------------------------------------------------------------------------------

local loadMTL = function(mtlPath)
    local materials = { }
    local currentMaterial = nil

    if not mtlPath or not love.filesystem.getInfo(mtlPath, "file") then
        return materials
    end

    local content, size = love.filesystem.read(mtlPath)
    if not content then
        return materials
    end

    for line in content:gmatch("[^\r\n]+") do
        local words = { }
        for word in line:gmatch("([^%s]+)") do
            table.insert(words, word)
        end

        local firstWord = words[1]
        if firstWord == "newmtl" then
            local name = words[2]
            currentMaterial = {
                name = name,
                color = { 1, 1, 1, 1 }, -- default white
            }
            materials[name] = currentMaterial
        elseif currentMaterial and (firstWord == "Ka" or firstWord == "Kd") then
            local r = tonumber(words[2]) or 1
            local g = tonumber(words[3]) or 1
            local b = tonumber(words[4]) or 1
            currentMaterial.color = { r, g, b, 1 }
        end
    end

    return materials
end

-- give path of file
-- returns a lua table representation
return function (path, mtlPath, uFlip, vFlip)
    local positions, uvs, normals = {}, {}, {}
    local result = {}
    local objContent = nil
    
    if love.filesystem.getInfo(path, "file") then
        local content, size = love.filesystem.read(path)
        if not content then
            error("Could not read obj file: "..tostring(size))
        end
        objContent = content
    else
        objContent = path
    end

    if type(objContent) ~= "string" then
        error("Input must be a file path or a string containing OBJ data.")
    end

    local lines = { }
    for line in objContent:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    local materials = loadMTL(mtlPath)
    local currentColor = { 1, 1, 1, 1 }

    -- go line by line through the file
    for _, line in ipairs(lines) do
        local words = {}

        -- split the line into words
        for word in line:gmatch "([^%s]+)" do
            table.insert(words, word)
        end

        local firstWord = words[1]

        if firstWord == "v" then
            -- if the first word in this line is a "v", then this defines a vertex's position

            table.insert(positions, {tonumber(words[2]), tonumber(words[3]), tonumber(words[4])})
        elseif firstWord == "vt" then
            -- if the first word in this line is a "vt", then this defines a texture coordinate

            local u, v = tonumber(words[2]), tonumber(words[3])

            -- optionally flip these texture coordinates
            if uFlip then u = 1 - u end
            if vFlip then v = 1 - v end

            table.insert(uvs, {u, v})
        elseif firstWord == "vn" then
            -- if the first word in this line is a "vn", then this defines a vertex normal
            table.insert(normals, {tonumber(words[2]), tonumber(words[3]), tonumber(words[4])})
        elseif firstWord == "usemtl" then
            local materialName = words[2]
            local material = materials[materialName]
            if material and material.color then
                currentColor = material.color
            else
                currentColor = { 1, 1, 1, 1 }
            end
        elseif firstWord == "f" then

            -- if the first word in this line is a "f", then this is a face
            -- a face takes three point definitions
            -- the arguments a point definition takes are vertex, vertex texture, vertex normal in that order

            local vertices = {}
            for i = 2, #words do
                local v, vt, vn

                local v2, vn2 = words[i]:match "(%d*)//(%d*)"

                if v2 and vn2 then
                    v = tonumber(v2)
                    vt = nil
                    vn = tonumber(vn2)
                else
                    v, vt, vn = words[i]:match "(%d*)/(%d*)/(%d*)"
                    v, vt, vn = tonumber(v), tonumber(vt), tonumber(vn)
                end

                local r, g, b, a = currentColor[1], currentColor[2], currentColor[3], currentColor[4]

                table.insert(vertices, {
                    v and positions[v][1] or 0,
                    v and positions[v][2] or 0,
                    v and positions[v][3] or 0,
                    vt and uvs[vt][1] or 0,
                    vt and uvs[vt][2] or 0,
                    r, g, b, a,
                    vn and normals[vn][1] or 0,
                    vn and normals[vn][2] or 0,
                    vn and normals[vn][3] or 0,
                })
            end

            -- triangulate the face if it's not already a triangle
            if #vertices > 3 then
                -- choose a central vertex
                local centralVertex = vertices[1]

                -- connect the central vertex to each of the other vertices to create triangles
                for i = 2, #vertices - 1 do
                    table.insert(result, centralVertex)
                    table.insert(result, vertices[i])
                    table.insert(result, vertices[i + 1])
                end
            else
                for i = 1, #vertices do
                    table.insert(result, vertices[i])
                end
            end

        end
    end

    return result
end
