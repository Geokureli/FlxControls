# Same as release.bat but for unix
#7z a -tzip -i!assets -i!flixel -i!images -i!CHANGELOG.md -i!LICENSE.md -i!README.md -i!include.xml -i!hxformat.json -i!haxelib.json -i!run.n flixel.zip
7z a -tzip \
 -i!lib \
 -i!images \
 -i!haxelib.json \
 -i!hxformat.json \
 -i!LICENSE \
 -i!README.md \
 flixel-controls.zip