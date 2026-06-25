[Setup]
; Unique ID for this app. Don't change it if you want future updates to overwrite correctly!
AppId={{6E4A8D3F-B5C2-4C10-91B6-4A92F13812B2}
AppName=VidyaVerse
AppVersion=1.0.0
AppPublisher=VidyaVerse
AppPublisherURL=https://vidyaverse.me/
AppSupportURL=https://vidyaverse.com/support
AppUpdatesURL=https://vidyaverse.com/updates
DefaultDirName={autopf}\VidyaVerse
DisableProgramGroupPage=yes
; The name of the resulting installer EXE
OutputBaseFilename=VidyaVerse_Windows_Installer
Compression=lzma2/ultra64
SolidCompression=yes
; Use your app's icon for the installer (make sure this path matches where your .ico is)
SetupIconFile=windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\vidyaverse.exe
ArchitecturesInstallIn64BitMode=x64
WizardStyle=modern

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; The main executable
Source: "build\windows\x64\runner\Release\vidyaverse.exe"; DestDir: "{app}"; Flags: ignoreversion

; The Flutter engine DLL
Source: "build\windows\x64\runner\Release\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion

; Any plugin DLLs that might have been compiled (if they exist, ignore error if they don't)
Source: "build\windows\x64\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist

; The data folder (contains your assets and compiled dart code)
Source: "build\windows\x64\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\VidyaVerse"; Filename: "{app}\vidyaverse.exe"
Name: "{autodesktop}\VidyaVerse"; Filename: "{app}\vidyaverse.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\vidyaverse.exe"; Description: "{cm:LaunchProgram,VidyaVerse}"; Flags: nowait postinstall skipifsilent
