$ErrorActionPreference = "Continue"
Set-Location "c:\Users\Team Lead Hopper\Downloads\leave-management-system"
& npm run build 2>&1 | Tee-Object -FilePath "build-output-new.txt"
