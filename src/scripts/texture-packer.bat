SET "PATH=C:/Program Files/CodeAndWeb/TexturePacker/bin;%PATH%"

SET SourceDir=C:\Users\lelandkwong\Projects\arpg-love
SET Destination=C:\Users\lelandkwong\Projects\arpg-love\src\built\sprite.png

TexturePacker --sheet "%Destination%" "%SourceDir%\assets\sprites\sprites.tps"

REM TexturePacker --help
REM PAUSE