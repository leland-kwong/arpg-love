SET ProjectDir=C:\Users\lelandkwong\Projects\arpg-love
SET SourceDir=%ProjectDir%\assets\sprites\custom-art\abilities\swipe
SET AsepritePath="C:\Program Files\Aseprite\Aseprite.exe"

DEL %SourceDir%\"*.png"
%AsepritePath% -b %SourceDir%\swipe.aseprite --save-as %SourceDir%\{slice}.png

REM Build sprite sheet
CALL "%ProjectDir%\src\scripts\texture-packer.bat"
