SET ProjectDir=C:\Users\lelandkwong\Projects\arpg-love
SET SourceDir=%ProjectDir%\assets\sprites\custom-art\characters\player
SET AsepritePath="C:\Program Files\Aseprite\Aseprite.exe"

DEL %SourceDir%\"*.png"
%AsepritePath% -b %SourceDir%\player.aseprite --save-as %SourceDir%\{tag}-{frame}.png

REM Build sprite sheet
CALL "%ProjectDir%\src\scripts\texture-packer.bat"