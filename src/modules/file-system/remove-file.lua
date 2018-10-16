local function recursivelyDelete( item )
    if love.filesystem.getInfo( item ) then
        for _, child in pairs( love.filesystem.getDirectoryItems( item )) do
            recursivelyDelete( item .. '/' .. child )
            love.filesystem.remove( item .. '/' .. child )
        end
    elseif love.filesystem.getInfo( item, 'file' ) then
        love.filesystem.remove( item )
    end
    love.filesystem.remove( item )
end

return recursivelyDelete