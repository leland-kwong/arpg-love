SET SourceDir=C:\Users\lelandkwong\Projects\arpg-love
SET DestDir=C:\Users\lelandkwong\Projects\arpg-love\builds
SET GameName=citizen_of_nowhere

CD /D "C:\Program Files\7-Zip"
7z.exe a "%SourceDir%\%GameName%.zip" "%SourceDir%\src\*"
RENAME "%SourceDir%\%GameName%.zip" "%GameName%.love"

copy /b "C:\Program Files (x86)\LOVE\love.exe"+"%SourceDir%\%GameName%.love" "%SourceDir%\game\%GameName%.exe"
del "%SourceDir%\%GameName%.love"

CD /D "C:\Program Files\7-Zip"
7z.exe a "%DestDir%\%GameName%.zip" "%SourceDir%\game"

PAUSE