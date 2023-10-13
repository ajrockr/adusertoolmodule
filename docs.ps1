$StageFolder = '.\compiled_docs'

$null = New-Item -Path $StageFolder -ItemType:Directory
Copy-Item -Path '.\*.md' -Destination $StageFolder -Force
Copy-Item -Path '.\docs\*' -Destination $StageFolder -Recurse -Force

Push-Location -Path $StageFolder
gitbook install
gitbook build
Pop-Location

Remove-Item -Path '.\docs\' -Include *.html -Recurse -Force
Copy-Item -Path "$StageFolder\_book\*" -Destination '.\docs\' -Recurse -Force
Remove-Item -Path $StageFolder -Recurse -Force
