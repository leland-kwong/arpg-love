return function()
  local releaseNotes = love.filesystem.read('release-notes.md')
  return string.sub(
    releaseNotes,
    string.find(releaseNotes, '%d.%d.%d%-[a-z]*')
  )
end