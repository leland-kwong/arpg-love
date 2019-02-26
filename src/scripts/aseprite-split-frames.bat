SET ProjectDir=C:\Users\lelandkwong\Projects\arpg-love
SET SourceDir=%ProjectDir%\assets\sprites\custom-art\characters\player
SET AsepritePath="C:\Program Files\Aseprite\Aseprite.exe"

DEL %SourceDir%\"*.png"
%AsepritePath% -b %SourceDir%\player.aseprite --save-as %SourceDir%\{tag}-{frame}.png
PAUSE
REM %AsepritePath% -b %SourceDir%\room.aseprite --scale 1 --save-as %SourceDir%\{slice}.png
REM %AsepritePath% -b %SourceDir%\cursors.aseprite --scale 2 --save-as %SourceDir%\{slice}-2x.png
REM %AsepritePath% -b %SourceDir%\cursors.aseprite --scale 3 --save-as %SourceDir%\{slice}-3x.png

REM Build sprite sheet
CALL "%ProjectDir%\src\scripts\texture-packer.bat"