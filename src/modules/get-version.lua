return function()
  local releaseNotes = love.filesystem.read('release-notes.md')
  local idx1, idx2 = string.find(releaseNotes, '%d.%d.%d%-[a-z]*')
  return string.sub(
    releaseNotes,
    string.find(releaseNotes, '%d.%d.%d%-[a-z]*')
  )
end