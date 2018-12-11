SET ProjectDir=C:\Users\lelandkwong\Projects\arpg-love
SET SourceDir=%ProjectDir%\assets\sprites\custom-art
SET AsepritePath="C:\Program Files\Aseprite\Aseprite.exe"

DEL %SourceDir%\tiles\"*.png"
%AsepritePath% -b %SourceDir%\tiles\room.aseprite --save-as %SourceDir%\tiles\{slice}.png

REM Build sprite sheet
CALL "%ProjectDir%\src\scripts\texture-packer.bat"
