@echo off

if "%PYTHON_VERSION%" == "" (
    echo PYTHON_VERSION must be defined >&2
    exit /b 1
)

if  "%PLATTAG%" == "" (
    echo Missing PLATTAG variable >&2
    exit /b 1
)

"%CONDA%" config --append channels conda-forge  || exit /b %ERRORLEVEL%
"%CONDA%" install --yes conda-build=2.1.15      || exit /b %ERRORLEVEL%

"%CONDA%" build --python %PYTHON_VERSION% ./conda-recipe || exit /b %ERRROLEVEL%

rem Copy the build conda pkg to artifacts dir
rem and the cache\conda-pkgs which is used later by build-conda-installer
rem script

mkdir ..\conda-pkgs        || exit /b %ERRROLEVEL%
mkdir ..\cache             || exit /b %ERRROLEVEL%
mkdir ..\cache\conda-pkgs  || exit /b %ERRROLEVEL%
for /f %%s in ( '"%CONDA%" build --output --python %PYTHON_VERSION% conda-recipe' ) do (
    copy /Y "%%s" ..\conda-pkgs\  || exit /b %ERRROLEVEL%
    copy /Y "%%s" ..\cache\conda-pkgs\  || exit /b %ERRROLEVEL%
)

for /f %%s in ( '"%PYTHON%" setup.py --version' ) do (
    set "VERSION=%%s"
)

echo VERSION = %VERSION%

"%CONDA%" create -n env --yes --use-local ^
             python=%PYTHON_VERSION% ^
             keyring=9.0 ^
             numpy=1.12.* ^
             scipy=0.19.* ^
             scikit-learn=0.18.* ^
             bottleneck=1.2.* ^
             Orange3=%VERSION% ^
    || exit /b %ERRROLEVEL%

"%CONDA%" list -n env --export --explicit --md5 > env-spec.txt

type env-spec.txt

bash -e scripts/windows/build-conda-installer.sh ^
        --platform %PLATTAG% ^
        --cache-dir ../cache ^
        --dist-dir dist ^
        --env-spec ./env-spec.txt ^
        --online no ^
    || exit /b %ERRROLEVEL%


for %%s in ( dist/Orange3-*Miniconda*.exe ) do (
    set "INSTALLER=%%s"
)

for /f %%s in ( 'sha256sum -b dist/%INSTALLER%' ) do (
    set "CHECKSUM=%%s"
)

echo INSTALLER = %INSTALLER%
echo SHA256    = %CHECKSUM%

@echo on
