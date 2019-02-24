return function()
  local releaseNotes = love.filesystem.read('release-notes.md')
  return string.sub(
    releaseNotes,
    string.find(releaseNotes, '%d[a-z%-%.0-9]+')
  )
end