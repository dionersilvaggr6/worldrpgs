@echo off
setlocal enabledelayedexpansion
title WorldRPGs - verificar tudo

rem ---------------------------------------------------------------
rem  Corre TODAS as verificacoes de uma vez.
rem
rem  Porque e que este ficheiro existe: os agentes comecaram a criar
rem  scripts de teste soltos (`--script ...`) que ninguem corria. Um
rem  teste que ninguem corre nao e um teste, e um ficheiro. Se criares
rem  outro, ACRESCENTA-O AQUI no mesmo acto.
rem ---------------------------------------------------------------

set "GODOT="
for /d %%D in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_*") do (
  for %%F in ("%%D\Godot_v*_win64_console.exe") do set "GODOT=%%F"
)
if not defined GODOT (
  for %%F in (godot.exe) do set "GODOT=%%~$PATH:F"
)
if not defined GODOT (
  echo Nao encontrei o Godot. Instala com: winget install GodotEngine.GodotEngine
  pause
  exit /b 1
)

set FALHOU=0

echo.
echo == 1/9  auto-teste principal (contra a spec e os catalogos) ==
"%GODOT%" --headless --audio-driver Dummy --path . scenes/selftest.tscn || set FALHOU=1

echo.
echo == 2/9  audio e icones das familias de armas ==
"%GODOT%" --headless --audio-driver Dummy --path . --script src/audio/delivery_self_test.gd || set FALHOU=1

echo.
echo == 3/9  abertura jogavel ==
"%GODOT%" --headless --audio-driver Dummy --path . --script src/ui/intro_selftest.gd || set FALHOU=1

echo.
echo == 4/9  arranque real: criar personagem e entrar no jogo ==
"%GODOT%" --headless --audio-driver Dummy --path . scenes/repro-inicio.tscn || set FALHOU=1

echo.
echo == 5/9  descanso real na fogueira (save isolado) ==
set "ORIGINAL_APPDATA=%APPDATA%"
set "ORIGINAL_WORLDRPGS_TEST_USER_ROOT=%WORLDRPGS_TEST_USER_ROOT%"
set "BONFIRE_TEST_PARENT=%TEMP%\worldrpgs-verificar"
for %%I in ("!BONFIRE_TEST_PARENT!") do set "BONFIRE_TEST_PARENT=%%~fI"
set "BONFIRE_TEST_APPDATA=!BONFIRE_TEST_PARENT!\bonfire-!RANDOM!-!RANDOM!"
2>nul md "!BONFIRE_TEST_APPDATA!"
if errorlevel 1 (
  echo Nao foi possivel criar o APPDATA temporario da prova da fogueira.
  set FALHOU=1
) else (
  set "APPDATA=!BONFIRE_TEST_APPDATA!"
  set "WORLDRPGS_TEST_USER_ROOT=!BONFIRE_TEST_APPDATA!"
  "%GODOT%" --headless --audio-driver Dummy --path . src/progression/bonfire_gameplay_repro.tscn || set FALHOU=1
  set "APPDATA=!ORIGINAL_APPDATA!"
  set "WORLDRPGS_TEST_USER_ROOT=!ORIGINAL_WORLDRPGS_TEST_USER_ROOT!"
  if exist "!BONFIRE_TEST_APPDATA!\" rd /s /q "!BONFIRE_TEST_APPDATA!"
  2>nul rd "!BONFIRE_TEST_PARENT!"
)

echo.
echo == 6/9  melhorias de armas ==
"%GODOT%" --headless --audio-driver Dummy --path . --script src/weapons/weapon_progression_selftest.gd || set FALHOU=1

echo.
echo == 7/9  camada de rede (protocolo, interpolacao, latencia) ==
"%GODOT%" --headless --audio-driver Dummy --path . --script src/net/net_selftest.gd || set FALHOU=1

echo.
echo == 8/8  guarda da spec (precisa de node) ==
pushd ..
node tools/check-coerencia.mjs || set FALHOU=1
popd

echo.
if "%FALHOU%"=="1" (
  echo ##  ALGUMA VERIFICACAO FALHOU  ##
) else (
  echo ##  TUDO PASSOU  ##
)
pause
