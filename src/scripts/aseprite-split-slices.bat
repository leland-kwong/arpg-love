REM copy and paste this into the command line.
REM The aseprite path should be relative to the folder you're running this command in

SET ProjectDir=C:\Users\lelandkwong\Projects\arpg-love
SET SourceDir=%ProjectDir%\assets\sprites\custom-art
SET AsepritePath="C:\Program Files\Aseprite\Aseprite.exe"

%AsepritePath% -b %SourceDir%\tiles\room.aseprite --save-as %SourceDir%\tiles\{slice}.png

REM Build sprite sheet
CALL "%ProjectDir%\src\scripts\texture-packer.bat"
