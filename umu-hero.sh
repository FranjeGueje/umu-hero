#!/bin/bash

##############################################################################################################################################################
# AUTOR: Paco Guerrero <fjgj1@hotmail.com> - FranjeGueje
# LICENSE of file: MIT (haz con él lo que quieras, pero cítame)
# ABOUT: Crea prefix del proyecto UMU. Añade juegos a Steam. Corre juegos sin utilizar heroic.
#           Añade juegos de Ubisoft
#           Complemento perfecto para Heroic.
#        Creates prefixes from UMU project. Add games to Steam. Run games without using heroic.
#           Adds games from Ubisoft
#           Perfect complement for Heroic.
# PARAMETERS:
#   VARIBLE:
#       DEBUG=Y -> verbose output
# SALIDAS/EXITs:
#   0: Todo correcto, llegamos al final. All correct, we have reached the end.
#
##############################################################################################################################################################

#!##############################################################################################################################################################
#!               Application functions
#!####################################
##
# Initialize the script
#
function pre_launch(){
    # Identificación
    NOMBRE="UMU-Hero"
    VERSION=2.0
    # Configuración del usuario
    TOOLOPTIONFILE="${TOOLOPTIONFILE:-$HOME/.config/umu-hero.conf}"
    # Directorios principales
    STEAM_DIR="$HOME/.local/share/Steam"
    UMU_DIR="$HOME/.local/share/umu-hero"
    MOUNT_PATH="$UMU_DIR/mount"
    PROTONFIXES_PATH="$UMU_DIR/umu-protonfixes"
    DATABASE_FILE="$UMU_DIR/umu-database.json"
    LINKS_PATH="/tmp/umu-hero/links"
    # Crear directorios necesarios
    mkdir -p "$UMU_DIR" "$MOUNT_PATH" "$PROTONFIXES_PATH"
    # Paths internos
    TOOL_PATH=$(readlink -f "$(dirname "$0")")
    BIN_PATH="$TOOL_PATH/bin/"
    LAUNCHER_PATH="$TOOL_PATH"/launchers/
    # Binarios requeridos
    JQ="$BIN_PATH"jq
    YAD="$BIN_PATH"yad
    SHORTCUTSNAMEID="$BIN_PATH"shortcutsNameID
    UMULAUNCHER="$BIN_PATH"umu-run
    # Assets
    IMGICON="$TOOL_PATH/assets/icon.png"
    IMGSPLASH_DIR="$TOOL_PATH/assets/splash/"
    OPTION_ICON="$TOOL_PATH/assets/settings.png"
    CREATE_PREFIX_ICON="$TOOL_PATH/assets/glass-cheers.png"
    ADD_ICON="$TOOL_PATH/assets/winux.png"
    EXIT_ICON="$TOOL_PATH/assets/cross.png"
    LIBRARY_ICON="$TOOL_PATH/assets/library.png"
    UMU_ICON="$TOOL_PATH/assets/umu-launcher.png"
    FIXES_ICON="$TOOL_PATH/assets/fixes.png"
    SAVE_ICON="$TOOL_PATH/assets/save.png"
    UPDATE_ICON="$TOOL_PATH/assets/update.png"
    SEARCH_ICON="$TOOL_PATH/assets/search.png"
    ABOUT_ICON="$TOOL_PATH/assets/star.png"
    HEROIC_ICON="$TOOL_PATH/assets/heroic.png"
    UBISOFT_ICON="$TOOL_PATH/assets/ubisoft.png"
    FILE_ICON="$TOOL_PATH/assets/file.png"
    # Parámetros de interfaz
    TITLE="--title=$NOMBRE - v$VERSION"
    ICON="--window-icon=$IMGICON"
    SEM="/tmp/.bar.lock"
    RUNNER_TEMPLATE="$TOOL_PATH/template.bat"
    # Cargar opciones del usuario
    load_options
}

##
# update the newest version
#
function update_new_version(){
    if [ -n "$APPIMAGE" ]; then
        to_debug_file "[INFO] Check Updating for new version of $NOMBRE"
        # Es un appimage y si tengo internet
        if curl -s --head https://api.github.com --max-time 3 | grep "HTTP/" 2>/dev/null >/dev/null; then
            local sha_web
            sha_web=$(curl -L "$(curl -s https://api.github.com/repos/FranjeGueje/umu-hero/releases/latest \
            | grep browser_download_url | cut -d '"' -f 4 | grep sha512sum 2>/dev/null)" 2>/dev/null)
            if diff <(sha512sum "$APPIMAGE" | cut -d ' ' -f1) <(echo "$sha_web" | cut -d ' ' -f1) >/dev/null 2>&1; then
                to_debug_file "[INFO] Already latest version"
            else
                if show_question "New version of $NOMBRE available. Download it?"; then
                    to_debug_file "[WARNING] Updating $NOMBRE"
                    local URL
                    URL=$(curl -s https://api.github.com/repos/FranjeGueje/umu-hero/releases/latest \
                    | grep browser_download_url | cut -d '"' -f 4 | grep x86_64| grep ".AppImage")
                    
                    if curl -s -o "$APPIMAGE.bak" "$URL"; then
                        to_debug_file "[INFO] Uploaded to last version."
                        show_info "Uploaded to last version.\nRun again $NOMBRE"
                        mv "$APPIMAGE".bak "$APPIMAGE" && chmod +x "$APPIMAGE"
                        exit 0
                    else
                        to_debug_file "[ERROR] Failed to download latest version"
                        show_info "Failed to download latest version"
                    fi
                fi
            fi
        else
            to_debug_file "[WARNING] No Internet connection"
        fi
    fi
}

##
# Load the options from the file
# return 0 Load ok; 1 default settings
#
function load_options() {
    if [ -f "$TOOLOPTIONFILE" ]; then
        to_debug_file "[INFO] Loading options from $TOOLOPTIONFILE"
        # Leer línea completa y dividir en campos
        local line
        line=$(head -n1 "$TOOLOPTIONFILE")
        # Validar que la línea no esté vacía
        if [ -n "$line" ]; then
            local opt_heroic opt_runners opt_grid
            IFS='|' read -r opt_heroic opt_runners opt_grid <<< "$line"

            HEROIC_CONFIG_DIR="${HEROIC_CONFIG_DIR:-$opt_heroic}"
            RUNNERS_PATH="${RUNNERS_PATH:-$opt_runners}"
            GRIDKEY="${opt_grid:-0}"
            to_debug_file "[INFO] HEROIC_CONFIG_DIR=$HEROIC_CONFIG_DIR"
            to_debug_file "[INFO] RUNNERS_PATH=$RUNNERS_PATH"
            to_debug_file "[INFO] GRIDKEY=XXXX"
            return 0
        else
            to_debug_file "[ERROR] $TOOLOPTIONFILE empty, using default options"
        fi
    else
        to_debug_file "[WARNING] Using default options"
        HEROIC_CONFIG_DIR="${HEROIC_CONFIG_DIR:-$HOME/.var/app/com.heroicgameslauncher.hgl/config/heroic}"
        RUNNERS_PATH="${RUNNERS_PATH:-$HOME/Games/$NOMBRE}"
        GRIDKEY=0
    fi
    return 1
}

##
# Save the options to a file
#
function save_options() {
    printf "%s|%s|%s" "$HEROIC_CONFIG_DIR" "$RUNNERS_PATH" "$GRIDKEY" > "$TOOLOPTIONFILE"
}

#!##############################################################################################################################################################
#!               Support functions
#!####################################
##
# Save a msg to debug
# $1 = Text to Debub file
#
function to_debug_file() {
    [ -n "$DEBUG" ] && printf "%s - %s\n" "$(date +"%Y-%m-%d %H:%M:%S")" "$1" 1>&2
}

##
# Return a random file from dir.
# $1 = source varname ( dir )
# return The random file in dir.
#
function fileRandomInDir() {
    find "$1" -maxdepth 1 -type f | shuf -n 1
}

##
# Add a game to Steam
# $1 = The executable file to add to steam
# return 0 is correct; 1 is game exists ; 252 error in steam
#
function add_steam_game() {
    to_debug_file "[INFO] add_steam_game: *** Entering to add_steam_game."
    # Asegurar protocolo steam:// en mimeapps.list
    local __mimefile="$HOME/.config/mimeapps.list"
    if ! grep -qi "x-scheme-handler/steam=" "$__mimefile" 2>/dev/null; then
        echo "x-scheme-handler/steam=steam.desktop;" >>"$__mimefile"
        to_debug_file "[INFO] add_steam_game: Registered steam:// handler in $__mimefile"
    fi

    # Exist the game on Steam?
    local __name __name_noext
    __name=$(basename "$1")
    __name_noext=$(basename "$1" .bat)

    # Función auxiliar para comprobar existencia en Steam
    check_in_steam() {
        for vdf in "$STEAM_DIR"/userdata/*/config/shortcuts.vdf; do
            "$SHORTCUTSNAMEID" "$vdf"
        done | grep -w "$1" >/dev/null
    }
    
    if check_in_steam "$__name" || check_in_steam "$__name_noext"; then
        to_debug_file "[ERROR] add_steam_game: Game '$__name' already exists in Steam."
        return 1
    fi
    
    local __encodedUrl=
    __encodedUrl="steam://addnonsteamgame/$(python3 -c "import urllib.parse;print(urllib.parse.quote(\"$1\", safe=''))")"
    rm -f "/tmp/addnonsteamgamefile"
    touch /tmp/addnonsteamgamefile
    xdg-open "$__encodedUrl"
    sleep 6

    local __id=
    __id=$(for i in "$STEAM_DIR"/userdata/*/config/shortcuts.vdf; do
        "$SHORTCUTSNAMEID" "$i"
    done | grep -w "$__name" | cut -f2 -d$'\t')
    
    # If __id is a integer then it is the id of game
    if [[ "$__id" =~ ^-?[0-9]+$ ]]; then
        to_debug_file "[INFO] add_steam_game: The id of the new game is $__id ."
        echo "$__id"
        return 0
    else
        to_debug_file "[ERROR] add_steam_game: There are an error ..."
        return 252
    fi
}

##
# Shows a game to Steam
# $1 = The id of game
#
function open_steam_game() {
    if show_question "Would you like to open the properties of the newly added game?";then
        xdg-open "steam://gameproperties/$1"
    fi
}

##
# Download the images (grids) for a game
# $1 = name of game
# $2 = id_steam, name of image files
#
function download_all_grids() {
    local __name=$1 __id_steam=$2
    if [ "$GRIDKEY" != "0" ];then
        to_debug_file "[INFO] download_all_grids: It will download the grid images for $__name."
        local __dir_tmp
        __dir_tmp=$(mktemp -d /tmp/"$NOMBRE".XXXXXX) || {
            to_debug_file "[ERROR] download_all_grids: Could not create temporary directory."
            return 1
        }
        # Descargamos grids
        (cd "$__dir_tmp" && download_grids "$GRIDKEY" "$__name" "$__id_steam"
        for dir in "$STEAM_DIR"/userdata/*/config/grid; do 
            cp "$__dir_tmp"/* "$dir" 
        done
        rm -r "$__dir_tmp"
        ) &

    else
        to_debug_file "[WARNING] download_all_grids: GRIDKEY is 0, skipping download for $__name."
    fi
}

##
# Download the images (grids) for a game
# $1 = gridkey, token
# $2 = name of game
# $3 = id_steam, name of image files
#
function download_grids() {

    local __token="$1" __name="$2" __fichero="$3"
    local json __name_encoded

    json=$(mktemp)
    # shellcheck disable=SC2016
    __name_encoded=$("$JQ" -nr --arg str "$__name" '$str|@uri')
    if ! curl -s -H "Authorization: Bearer $__token" \
            "https://www.steamgriddb.com/api/v2/search/autocomplete/$__name_encoded" > "$json"; then
        to_debug_file "[ERROR] download_grids: Failed to query autocomplete for $__name"
        rm -f "$json"
        return 1
    fi
    if [ "$("$JQ" -r '.data | length' < "$json")" -gt 0 ]; then
        local __id=
        __id=$("$JQ" -r .data[0].id < "$json")

        # GRID_H
        curl -s -H "Authorization: Bearer $__token" "https://www.steamgriddb.com/api/v2/grids/game/$__id?limit=1&dimensions=460x215" > "$json"
        if [ "$("$JQ" -r .success < "$json")" == "true" ] && [ "$("$JQ" -r .total < "$json")" -gt 0 ]; then
            curl -s -o "$__fichero".png "$("$JQ" -r .data[0].url < "$json")"
        fi

        # GRID_V
        curl -s -H "Authorization: Bearer $__token" "https://www.steamgriddb.com/api/v2/grids/game/$__id?limit=1&dimensions=600x900" > "$json"
        if [ "$("$JQ" -r .success < "$json")" == "true" ] && [ "$("$JQ" -r .total < "$json")" -gt 0 ]; then
            curl -s -o "$__fichero"p.png "$("$JQ" -r .data[0].url < "$json")"
        fi

        # HEROES
        curl -s -H "Authorization: Bearer $__token" "https://www.steamgriddb.com/api/v2/heroes/game/$__id?limit=1" > "$json"
        if [ "$("$JQ" -r .success < "$json")" == "true" ] && [ "$("$JQ" -r .total < "$json")" -gt 0 ]; then
            curl -s -o "$__fichero"_hero.png "$("$JQ" -r .data[0].url < "$json")"
        fi

        # LOGOS
        curl -s -H "Authorization: Bearer $__token" "https://www.steamgriddb.com/api/v2/logos/game/$__id?limit=1" > "$json"
        if [ "$("$JQ" -r .success < "$json")" == "true" ] && [ "$("$JQ" -r .total < "$json")" -gt 0 ]; then
            curl -s -o "$__fichero"_logo.png "$("$JQ" -r .data[0].url < "$json")"
        fi

        # ICONS
        curl -s -H "Authorization: Bearer $__token" "https://www.steamgriddb.com/api/v2/icons/game/$__id?limit=1" > "$json"
        if [ "$("$JQ" -r .success < "$json")" == "true" ] && [ "$("$JQ" -r .total < "$json")" -gt 0 ]; then
            curl -s -o "$__fichero"_icon.ico "$("$JQ" -r .data[0].url < "$json")"
        fi
    fi
    rm "$json"
    return 0
}

#!############################################################################################################################################################## 
#!               UMU Functions
#!####################################
##
# Load in memory the umu-database
# $1 = source varname ( [OPTIONAL] text to search)
#
function reload_database() {
    #* REMEMBER: TITLE + UMU_ID + STORE + CODENAME + ACRONYM + NOTES
    local __search=$1
    # shellcheck disable=SC2016
    readarray -t -d '|' DATABASE < <(
        "$JQ" -r -j --arg v "$__search" \
            '.[] | select(.title | ascii_downcase | contains ($v)) | "\(.title)|\(.umu_id)|\(.store)|\(.codename)|\(.acronym)|\(.notes)|"' \
        "$DATABASE_FILE" 2>/dev/null | iconv -c
    )
}

##
# Download the UMU Database
# return 0 OK ; 1 if error
#
function download_database() {
    local __umu_temp="/tmp/umu-database.json.temp"
    # Descargar base de datos
    if ! curl -s -f https://umu.openwinecomponents.org/umu_api.php -o "$__umu_temp"; then
        to_debug_file "[ERROR] download_database: Failed to download database from Internet."
        return 1
    fi

    # Validar tamaño del fichero
    if [[ ! -s "$__umu_temp" ]]; then
        to_debug_file "[WARNING] download_database: Downloaded file is empty."
        rm -f "$__umu_temp"
        return 1
    fi

    # Actualizar protonfixes si git está disponible
    if command -v git >/dev/null 2>&1; then
        if [[ -d "$PROTONFIXES_PATH" ]]; then
            (cd "$PROTONFIXES_PATH" && git pull) || \
                to_debug_file "[WARNING] download_database: git pull failed in $PROTONFIXES_PATH"
        else
            (cd "$HOME/.local/share/umu-hero/" && git clone https://github.com/Open-Wine-Components/umu-protonfixes) || \
                to_debug_file "[WARNING] download_database: git clone failed"
        fi
    else
        to_debug_file "[INFO] download_database: git not available, skipping protonfixes update."
    fi

    # Sustituir base de datos
    mv "$__umu_temp" "$DATABASE_FILE"
    to_debug_file "[INFO] download_database: Database downloaded successfully to $DATABASE_FILE"
    return 0
}

##
# Show the fix for a game
# $1 = source varname ( [OPTIONAL] umu_id to show)
#
function show_fix() {
    local __umu_id=$1

    if [ "$(find "$PROTONFIXES_PATH" "$__umu_id.*" -type f \( -name "$__umu_id.*" -o -name "$(echo "$__umu_id".* | cut -d '-' -f2)" \) | wc -l)" -gt 0 ]; then
        find "$PROTONFIXES_PATH" "$__umu_id.*" -type f \( -name "$__umu_id.*" -o -name "$(echo "$__umu_id".* | cut -d '-' -f2)" \) -exec \
            "$YAD" "$TITLE" "$ICON" --center --on-top --width=200 --height=400 --sticky --no-markup --text-info --text={} --filename={} --button="OK":0 \;
    else
        show_info "Game fix not found.\nConsider that there is no fix for the game and you can launch it without any configuration."
    fi
}

##
# Search a game from umu
# $1 = Store
# $2 = id of game
#
function search_umu-game() {
    to_debug_file "[INFO] search_umu-game: *** Begin the process to search the umu-game on umu-database..."
    if [ $# -ne 2 ]; then
        to_debug_file "[ERROR] search_umu-game: you have called the function wrong. There are TWO parameters."
        return 1
    fi
    local __store=$1 __id=$2
    local __umu_game __nombre __umu_id
    local __result=1
    # Intentar búsqueda en Internet
    if __umu_game=$(curl -s "https://umu.openwinecomponents.org/umu_api.php?store=$__store&codename=$__id" 2>/dev/null);then
        if [[ "$("$JQ" -r 'length' <<<"$__umu_game")" -eq 0 ]]; then
            to_debug_file "[WARNING] search_umu_game: Game NOT found online."
            __result=1
        else
            __nombre=$(echo -e "$__umu_game" | "$JQ" -r '.[].title')
            __umu_id=$(echo -e "$__umu_game" | "$JQ" -r '.[].umu_id')
            to_debug_file "[INFO] search_umu-game: Game FOUND on umu-database: $__nombre | $__umu_id"
            echo -e "$__umu_id"
            __result=0
        fi
    elif [ -f "$DATABASE_FILE" ]; then
        # Busqueda Offline
        # shellcheck disable=SC2016
        __umu_game=$("$JQ" -r --arg store "$__store" --arg codename "$__id" \
            '.[] | select(.store == $store and .codename == $codename) | .umu_id' < "$DATABASE_FILE" )
        if [ -z "$__umu_game" ];then
            to_debug_file "[WARNING] search_umu-game: Game NOT found on umu-database in offline file."
            __result=1
        else
            to_debug_file "[INFO] search_umu-game: Game FOUND on umu-database: $__umu_game"
            echo -e "$__umu_game"
            __result=0
        fi
    else
        to_debug_file "[ERROR] search_umu-game: There are any network problem."
        __result=1
    fi
    to_debug_file "[INFO] search_umu-game: *** End the process to search the umu-game on umu-database..."
    return "$__result"
}

##
# Prepare a prefix 
# $1 = game_id
# $2 = Store
#
function prepare_umu-prefix() {
    to_debug_file "[INFO] prepare_umu-prefix: *** Begin the process to create the PREFIX for the umu-game..."
    if [ $# -ne 2 ]; then
        to_debug_file "[ERROR] prepare_umu-prefix: you have called the function wrong.."
        return 1
    fi
    local __id=$1 __store=$2
    local __prefix __proton
    __prefix=$(get_Heroic_prefix "$__id")
    __proton=$(get_Heroic_protondir "$__id")
    if show_question "$NOMBRE will prepare the prefix. For this, $NOMBRE will search this game in the umu-database. If no result is found, the default prefix will be created.\nWould you like to prepare the prefix?";then
        local __umu_id
        if __umu_id=$(search_umu-game "$__store" "$__id");then
            to_debug_file "[INFO] prepare_umu-prefix: Game found on UMU-DATABASE."
            show_info "Great! Game founded on UMU-DATABASE!"
        else
            to_debug_file "[INFO] prepare_umu-prefix: Game NOT found on UMU-DATABASE. $NOMBRE will create the default prefix."
            __umu_id=0
        fi
        fBarra "Please, wait... YES, be pacient...\n\n$NOMBRE is creating the prefix with the fixes." &  
        sleep 1
        to_debug_file "[INFO] prepare_umu-prefix: WINEPREFIX=$__prefix GAMEID=$__umu_id PROTONPATH=$__proton STORE=$__store $UMULAUNCHER"
        WINEPREFIX="$__prefix" GAMEID="$__umu_id" PROTONPATH="$__proton" STORE="$__store" "$UMULAUNCHER" "exit"
        cp "$LINKS_PATH"/* "$__prefix"/pfx/drive_c/. -Rf

        fBarraStop
        show_info "Done! The prefix was created."
    else
        show_info "Ok. Don't prepare the prefix!"
    fi

    to_debug_file "[INFO] prepare_umu-prefix: *** END the process to create the PREFIX for the umu-game..."
}


#!############################################################################################################################################################## 
#!               YAD functions
#!####################################
##
# Show a message on screen fro 2 seconds
#
# $1 = source varname ( Text to show )
# $2 = source varname ( [OPTIONAL] image to show )
#
function show_tmp_msg() {
    if [ -n "$2" ]; then
        "$YAD" "$TITLE" "$ICON" --center --no-buttons --on-top --align=center --timeout=2 --fixed --text="$1" --image="$2" --no-markup
    else
        "$YAD" "$TITLE" "$ICON" --center --no-buttons --on-top --align=center --timeout=2 --fixed --text="$1" --no-markup
    fi
}

##
# Show a message on screen and show a OK button
# $1 = source varname ( Text to show )
# $2 = source varname ( [OPTIONAL] image to show )
#
function show_info() {
    if [ -n "$2" ]; then
        "$YAD" "$TITLE" "$ICON" --center --on-top --align=center --fixed --text="$1" --image="$2" --no-markup --button="OK:0"
    else
        "$YAD" "$TITLE" "$ICON" --center --on-top --align=center --fixed --text="$1" --no-markup --button="OK:0"
    fi
}

##
# Show a message with a question
# $1 = source varname ( Text to show )
# return 0 OK; 1 Cancel
#
function show_question(){
    "$YAD" "$TITLE" "$ICON" --text="$1" --center --on-top --align=center --no-markup --fixed --button="OK:0" --button="Cancel:1"

    local __respuesta=$?
    return "$__respuesta"
}

##
# Funcion de barra
# $1 = Text to show - OPTIONAL
#
function fBarra() {
    if [ -n "$1" ]; then
        __text="$1"
    else
        local __text="Please, wait... YES, be pacient..."
    fi
    (
    touch "$SEM"
    i=0
    while [ -e "$SEM" ] ; do
        echo $i
        sleep 0.05
        ((i++))
        [ $i -eq 99 ] && i=0
    done
    ) | (
        # Mostrar la ventana de progreso de Yad
        "$YAD" "$TITLE" "$ICON" --text="$__text" --progress --percentage=0 --auto-close --no-buttons --undecorated --fixed
    )
}

##
# Funcion para detener la barra
#
function fBarraStop() {
    rm "$SEM" 
}

#!############################################################################################################################################################## 
#!               Heroic functions
#!####################################
##
# Check if config is correct
# return 0 OK; return 1 ERROR
#
function check_Heroic_config(){
    to_debug_file "[INFO] check_Heroic_config: *** The config is being checked by $NOMBRE"
    if [ ! -d "$HEROIC_CONFIG_DIR" ];then
        to_debug_file "[ERROR] check_Heroic_config: The CONFIG DIR of Heroic not exist."
        echo -e "[ERROR] check_Heroic_config: The CONFIG DIR of Heroic not exist."
        show_tmp_msg "The Config Dir of Heroic not exist. Please, open the option menu and configure the dir property"
        return 1
    else
        if [ ! -f "$HEROIC_CONFIG_DIR"/config.json ];then
            to_debug_file "[ERROR] check_Heroic_config: The CONFIG DIR of Heroic exists but it's NOT valid."
            echo -e "[ERROR] check_Heroic_config: The CONFIG DIR of Heroic exists but it's NOT valid."
            show_tmp_msg "The Config Dir of Heroic exists but it's not valid. Please, open the option menu and configure the dir property"
            return 1
        else
            to_debug_file "[INFO] check_Heroic_config: The CONFIG DIR of Heroic exists and it's valid."
            [ -z "$GAMES_DIR" ] && GAMES_DIR=$("$JQ" -r -c '.defaultSettings.defaultInstallPath' "$HEROIC_CONFIG_DIR"/config.json)
            [ -z "$STEAM_DIR" ] && STEAM_DIR=$("$JQ" -r -c '.defaultSettings.defaultSteamPath' "$HEROIC_CONFIG_DIR"/config.json)
            if [ ! -d "$GAMES_DIR" ];then
                to_debug_file "[ERROR] check_Heroic_config: The DIR of GAMES NOT exist."
                show_tmp_msg "The dir of Games not exist. Please, open the option menu and configure the dir property"
                return 1
            else
                to_debug_file "[INFO] check_Heroic_config: The DIR of GAMES exists and it's valid."
            fi
        fi
    fi
    if [ ! -d "$RUNNERS_PATH" ];then
        if mkdir -p "$RUNNERS_PATH" ;then
            to_debug_file "[INFO] check_Heroic_config: The DIR of RUNNER don't exists but we create a valid dir."
        else
            to_debug_file "[ERROR] check_Heroic_config: The DIR of RUNNER don't exists but we CANNOT create a valid dir."
            echo "[ERROR] check_Heroic_config: The DIR of RUNNER don't exists but we CANNOT create a valid dir."
            exit 1
        fi
    fi
    return 0
}

##
# Transform an Heroic installation to Windows installation
# $1 = mode {legendary,gogdl,nile}
# $2 = file json to read
# return 0 OK; 1 ERROR
#
function windowized_Heroic() {
    to_debug_file "[INFO] windowized_Heroic: *** The config is being windowized_Heroic by $NOMBRE."
    if [ $# -ne 2 ]; then
        to_debug_file "[ERROR] windowized_Heroic: you have called the function wrong. There are two parameters."
        return 1
    fi

    local __archivo=$2 __salida
    __salida="$__archivo".json
    case "$1" in
    l | legendary)
        to_debug_file "[INFO] windowized_Heroic: legendary mode."
        sed -s 's|"install_path":.*/\([^/]\+\)\"|"install_path": \"c:\\\\games\\\\\1\"|' < "$__archivo" > "$__salida"
        ;;
    g | gogdl)
        to_debug_file "[INFO] windowized_Heroic: gogdl mode."
        sed -s 's|"install_path":.*/\([^/]\+\)\"|"install_path": \"c:\\\\games\\\\\1\"|' < "$__archivo" > "$__salida"
        ;;
    n | nile)
        to_debug_file "[INFO] windowized_Heroic: nile mode."
        sed -s 's|"path":.*/\([^/]\+\)\"|"path":\"c:\\\\games\\\\\1\"|' < "$__archivo" > "$__salida"
        ;;
    esac
    return 0
}

##
# Load the config from Heroic
# $1 = Heroic Game launcher config dir
# $2 = output dir. Where the mount dir will be configurated
# return 0 OK; 1 ERROR
#
function load_Heroic_config() {
    to_debug_file "[INFO] Load_Heroic_config: *** The config of Heroic is loading..."
    if [ $# -ne 2 ]; then
        to_debug_file "[ERROR] Load_Heroic_config: you have called the function wrong. There are two parameters."
        return 1
    fi

    local __heroic=$1 __mount=$2

    mkdir -p "$__mount" 2> /dev/null

    if [ ! -d "$__heroic" ] || [ ! -d "$__mount" ]; then
        to_debug_file "[ERROR] Load_Heroic_config: the directory to find heroic config not exist or the mount dir is inaccessible."
        return 1
    fi

    mkdir -p "$MOUNT_PATH"/gog_store "$MOUNT_PATH"/gogdl "$MOUNT_PATH"/legendary "$MOUNT_PATH"/nile "$MOUNT_PATH"/bin 2> /dev/null
    rsync -a "$LAUNCHER_PATH"/* "$MOUNT_PATH"/bin/. > /dev/null 2> /dev/null

    # GOG config directories
    if [ -d "$__heroic/gog_store/" ];then
        rm "$__mount/gog_store/"* -Rf 2> /dev/null
        ln -s "$__heroic/gog_store/"* "$__mount"/gog_store/.
        mv "$__mount"/gog_store/installed.json "$__mount"/gog_store/installed
        windowized_Heroic g "$__mount"/gog_store/installed
        to_debug_file "[INFO] Load_Heroic_config: the gog_store config is created."
    fi
    if [ -d "$__heroic/gogdlConfig/heroic_gogdl/" ];then
        rm "$__mount/gogdl/"* -Rf 2> /dev/null
        ln -s "$__heroic/gogdlConfig/heroic_gogdl/"* "$__mount"/gogdl/.
        to_debug_file "[INFO] Load_Heroic_config: the gogdl config is created."
    fi
    # Legendary config directories
    if [ -d "$__heroic/legendaryConfig/legendary/" ];then
        rm "$__mount/legendary/"* -Rf 2> /dev/null
        ln -s "$__heroic/legendaryConfig/legendary/"* "$__mount"/legendary/.
        mv "$__mount"/legendary/installed.json "$__mount"/legendary/installed
        windowized_Heroic l "$__mount"/legendary/installed
        to_debug_file "[INFO] Load_Heroic_config: the legendary config is created."
    fi
    # Nile config directories
    if [ -d "$__heroic/nile_config/nile/" ];then
        rm "$__mount/nile/"* -Rf 2> /dev/null
        ln -s "$__heroic/nile_config/nile/"* "$__mount"/nile/.
        mv "$__mount"/nile/installed.json "$__mount"/nile/installed
        windowized_Heroic n "$__mount"/nile/installed
        to_debug_file "[INFO] Load_Heroic_config: the legendary config is created."
    fi
    return 0
}

##
# Create the symbolic links for the application
#
function symbolic_Heroic_links() {
    to_debug_file "[INFO] symbolic_Heroic_links: *** $NOMBRE is creating the symbolic links"
    [ -d "$LINKS_PATH" ] && rm "$LINKS_PATH"/* 2> /dev/null
    mkdir -p "$LINKS_PATH"
    ln -s "$MOUNT_PATH" "$LINKS_PATH/heroic"
    ln -s "$GAMES_DIR" "$LINKS_PATH/games"
}

##
# Create the runner for Heoic - the executable file
# $1 = store {l,g,n} (legendary gogdl or nile)
# $2 = id of game
#
function create_Heroic_runner() {
    to_debug_file "[INFO] create_Heroic_runner: *** $NOMBRE is creating a runner."
    if [ $# -ne 2 ]; then
        to_debug_file "[ERROR] create_Heroic_runner: you have called the function wrong. There are two parameters."
        return 1
    fi

    local __store=$1 __id=$2
    case "$__store" in
    l | legendary | EPIC | egs)
        to_debug_file "[INFO] create_Heroic_runner: Creating a runner in legendary mode."
        # Buscar el juego en la configuración de instalados
        printf "@legendary launch %s %%*\n" "$__id"
        ;;
    g | gogdl | GOG | gog)
        to_debug_file "[INFO] create_Heroic_runner: Creating a runner in gogdl mode."
        # Buscar el juego en la configuración de instalados
        # shellcheck disable=SC2016
        game_path=$("$JQ" -r --arg v "$__id" '.installed[] | select(.appName == $v) | .install_path' "$MOUNT_PATH/gog_store/installed.json")
        printf '@gogdl --auth-config-path c:\\heroic\\gog_store\\auth.json launch --platform windows "%s" %s -- %%*\n' "$game_path" "$__id"
        ;;
    n | nile | AMAZON | amazon)
        to_debug_file "[INFO] create_Heroic_runner: Creating a runner in nile mode."
        # Buscar el juego en la configuración de instalados
        printf "@nile launch %s -- %%*\n" "$__id"
        ;;
    esac

    to_debug_file "[INFO] create_Heroic_runner: runner created."
}

##
# Create bat
# $1 = the command line to run
# $2 = name of the game / file
#
function create_Heroic_bat() {
    to_debug_file "[INFO] create_Heroic_bat: *** $NOMBRE is creating a executable to run on Windows (or wine)."
    if [ $# -ne 2 ]; then
        to_debug_file "[ERROR] create_Heroic_bat: you have called the function wrong. There are two parameters."
        return 1
    fi

    local __runner=$1 __name="$RUNNERS_PATH/$2.bat"
    grep -v -w "@rem" < "$RUNNER_TEMPLATE" > "$__name"
    printf "%s\n" "$__runner" >> "$__name"
    to_debug_file "[INFO] create_Heroic_bat: file created with content:\n $(cat "$__name")"
}


##
# The principal process to install a steam game
# $1 = Name of game
# $2 = Store
# $3 = id of game
#
function install_Heroic_game() {
    to_debug_file "[INFO] install_Heroic_game: *** Begin the process to ADD TO STEAM..."
    if [ $# -ne 3 ]; then
        to_debug_file "[ERROR] install_Heroic_game: you have called the function wrong. There are THREE parameters."
        return 1
    fi
    local __name=$1 __store=$2 __id=$3
    local __r __id_steam
    
    if show_question \
"This action will perform the following tasks:\n\
\n\
* Will add the game to Steam.\n\
* \"Windowizer\" the game. Will use third-party launchers in their native Windows versions.\n\
* Link both prefixes (Steam and Heroic).\n\
* Search for the game in UMU-DATABASE to apply the protonfixes.\n\
\n\
Are you sure to continue?";then
        create_Heroic_bat "$(create_Heroic_runner "$__store" "$__id")" "$__name"
        fBarra "Please, wait... YES, be pacient...\n\n$NOMBRE is adding the game to Steam." & 
        sleep 1
        __id_steam=$(add_steam_game "$RUNNERS_PATH"/"$__name".bat)
        fBarraStop
        __r=$?

        case "$__r" in
            # All ok
            0)  download_all_grids "$__name" "$__id_steam"
                # Link the prefix
                local __prefix
                __prefix=$(get_Heroic_prefix "$__id")
                [ -d "$__prefix" ] && [ ! -L "$__prefix" ] && mv "$__prefix" "$STEAM_DIR/steamapps/compatdata/$__id_steam"
                mkdir -p "$STEAM_DIR"/steamapps/compatdata/"$__id_steam"/pfx/drive_c
                ln -s "$STEAM_DIR/steamapps/compatdata/$__id_steam"/ "$__prefix"
                cp "$LINKS_PATH"/* "$STEAM_DIR"/steamapps/compatdata/"$__id_steam"/pfx/drive_c/. -Rf
                show_info "$__name was successfully added to Steam."

                # Search the game in umu-database
                prepare_umu-prefix "$__id" "$__store"
                open_steam_game "$__id_steam"
                ;;
            # Game exists
            1)  show_info "[ERROR] $__name was NOT successfully added to Steam. The game exist with the same name on Steam.\nPlease, check the game on steam or remove it."
                ;;
            # General error
            *)  show_info "[ERROR] $__name was NOT successfully added to Steam. There has been an unexpected error on Steam."
                ;;
        esac
        
    else
        to_debug_file "[INFO] install_Heroic_game: Canceled."
    fi
}

##
# Read installed games
#
function get_Heroic_games() {
    local installed_gog=installed_epic=installed_amz

    to_debug_file "[INFO] get_Heroic_games: *** Searching installed games."
    ##############################
    # GOG
    if [ -f "$MOUNT_PATH"/gog_store/installed.json ]; then
        to_debug_file "[INFO] get_Heroic_games: Searching installed games on GOG."
        mapfile -t installed_gog < <("$JQ" -r '.installed[]  | "gog\n\(.appName)\n\(.install_path)"' "$MOUNT_PATH"/gog_store/installed.json | sed 's/.*\\\(.*\)/\1/' | iconv -c)
    fi

    ##############################
    # EPIC
    if [ -f "$MOUNT_PATH"/legendary/installed.json ]; then
        to_debug_file "[INFO] get_Heroic_games: Searching installed games on EPID."
        mapfile -t installed_epic < <("$JQ" -r '.[] | "egs\n\(.app_name)\n\(.title)"' "$MOUNT_PATH"/legendary/installed.json | iconv -c)
    fi

    ##############################
    # AMAZON
    if [ -f "$MOUNT_PATH"/nile/installed.json ]; then
        to_debug_file "[INFO] get_Heroic_games: Searching installed games on AMAZON."
        mapfile -t installed_amz < <("$JQ" -r '.[] | "amazon\n\(.id)\n\(.path)"' "$MOUNT_PATH"/nile/installed.json | sed 's/.*\\\(.*\)/\1/' | iconv -c)
    fi
    
    INSTALLED_GAMES=("${installed_gog[@]}" "${installed_epic[@]}" "${installed_amz[@]}")

    to_debug_file "[INFO] get_Heroic_games: showing the ALL analyzed installed games:"
    to_debug_file "$(for item in "${INSTALLED_GAMES[@]}"; do echo "$item" ;done)"
    to_debug_file "[INFO] get_Heroic_games: *** Searched installed games."

}

## 
# Get prefix of heroic game
# $1 = id of game
#
function get_Heroic_prefix(){
    local __id=$1
    "$JQ" -r ".\"$__id\".winePrefix" "$HEROIC_CONFIG_DIR/GamesConfig/$__id.json"
}

## 
# Get proton dir of heroic game
# $1 = id of game
#
function get_Heroic_protondir(){
    local __id=$1
    dirname "$("$JQ" -r ".\"$__id\".wineVersion.bin" "$HEROIC_CONFIG_DIR/GamesConfig/$__id.json")"
}


#!############################################################################################################################################################## 
#!               Ubi functions
#!####################################
##
# Create Ubisoft sh file
# $1 = the command line to run
# $2 = name of the game / file
# $3 = id of pfx on Steam
#
function create_Ubi_sh() {
    to_debug_file "[INFO] create_Ubi_sh: *** $NOMBRE is creating a executable to run Ubi games."
    if [ $# -ne 3 ]; then
        to_debug_file "[ERROR] create_Ubi_sh: you have called the function wrong. There are three parameters."
        return 1
    fi

    local __id=$1 __name="$RUNNERS_PATH/$2" __pfx=$3
    printf "#!/bin/bash\nflatpak run com.github.Matoking.protontricks --no-bwrap -c 'wine start %s' %s\nexit \$?\n" \
        "$__id" "$__pfx" > "$__name"
    chmod +x "$__name"
    to_debug_file "[INFO] create_Ubi_sh: file $__name created with content:\n $(cat "$__name")"
    if [ -f "$__name" ];then
        to_debug_file "[INFO] create_Ubi_sh: file $__name created with content:\n $(cat "$__name")"
        return 0
    fi
    to_debug_file "[ERROR] create_Ubi_sh: the file $__name was not created."
    return 2
}

## 
# Find games in a regedit file
# $1 = regedit file
#
function get_Ubi_games() {
    awk '
        # Buscar inicio de bloque con ID
        /^\[Software\\\\Wow6432Node\\\\Ubisoft\\\\Launcher\\\\Installs\\\\[0-9]+\]/ {
            if (match($0, /Installs\\\\([0-9]+)/, m)) {
                id = m[1]
            }
        }

        # Buscar la línea con InstallDir
        /"InstallDir"="/ {
            if (id && match($0, /"InstallDir"="([^"]+)"/, m)) {
                dir = m[1]

                # sacar el último componente
                gsub(/\\+$/, "", dir)   # quitar \ finales
                gsub(/\/+$/, "", dir)   # quitar / finales

                # extraer nombre del juego como basename
                n = split(dir, parts, /[\/\\]/)
                name = parts[n]

                printf "uplay://launch/%s/0|%s\n", id, name

                id = "" # reset
            }
        }
    ' "$1"
}
#!############################################################################################################################################################## 
#!               Menu function
#!####################################
##
# Show the mainMenu Window
#
function mainMenu() {
    to_debug_file "[INFO] mainMenu: *** Entering in Main Menu."

    IMGSPLASH=$(fileRandomInDir "$IMGSPLASH_DIR")

    "$YAD" "$TITLE" "$ICON" --center --width=250 --columns=1 --image="$IMGSPLASH" \
        --button="Add Games!$LIBRARY_ICON!Add your games to Steam":0 \
        --button="UMU Prefix!$UMU_ICON!Prepare an extra Wine Prefix":2 \
        --button="Options!$OPTION_ICON!Set the options":1 \
        --button="Exit!$EXIT_ICON!Exit from $NOMBRE":252 \
        --align=center --buttons-layout=edge --undecorated --fixed
    local __boton=$?
    
    case $__boton in
        0)  addGame ;;
        1)  optionMenu ;;
        2)  umuMenu ;;
        *)  if show_question "Are you sure you want to leave?";then
                __boton=252
            else
                __boton=251
            fi
            ;;
    esac
    to_debug_file "[INFO] mainMenu: *** Exiting from Main Menu."
    return "$__boton"
}

##
# Show the Window to add games
#
function addGame() {
    to_debug_file "[INFO] addGame: *** Entering in add Menu."
    __salida=$("$YAD" "$TITLE" "$ICON" --no-markup \
            --button="From Heroic!$HEROIC_ICON!Add a game to Steam from Heroic":0 \
            --button="From Ubisoft!$UBISOFT_ICON!Add a game to Steam from Ubisoft":10 \
            --button="From a file!$FILE_ICON!Add a game to Steam from Ubisoft":20 \
            --button="Back!$EXIT_ICON!Back to main menu":30 \
            --undecorated --fixed)

    local __boton=$?

    case $__boton in
    0)  HeroicMenu ;;
    10) UbisoftMenu
        ;;
    20) FileMenu
        ;;
    *)  to_debug_file "[INFO] addGame: Canceled." ;;
    esac
    to_debug_file "[INFO] addGame: *** Exiting the menu to add a new game..."
}

##
# Menu for UMU Database
# $1 = source varname ( [OPTIONAL] text to search)
function umuMenu() {
    to_debug_file "[INFO] umuMenu: *** Entering in Database Menu."
    local __search=$1

    
    if [ ! -f "$DATABASE_FILE" ];then
        to_debug_file "[INFO] umuMenu: Database on local is missing. Database will be downloaded from Internet."
        if ! download_database;then
            to_debug_file "[INFO] umuMenu: Database can NOT be downloaded from Internet."
            show_info "Can not download the database file from internet. Please check your network settings."
            return 1
        fi
    fi

    if [ -n "$__search" ]; then
        reload_database "$__search"
    else
        reload_database
    fi

    # Result of YAD dialog
    local __salida=
    local __boton=0

    while [ $__boton -ne 1 ] && [ $__boton -ne 252 ]; do
        __salida=$("$YAD" "$TITLE" "$ICON" --center --on-top --list --width=1280 --height=800 --sticky --no-markup --buttons-layout=spread \
            --button="Search Title!$SEARCH_ICON":3 --button="Update UMU-Database!$UPDATE_ICON":2 \
            --button="Show Fix!$FIXES_ICON":4 \
            --button="Create UMU-Prefix...!$UMU_ICON!Create a prefix":0 --button="Back!$EXIT_ICON":1 \
            --column=TITLE --column=UMU_ID --column=STORE --column=CONDENAME --column=ACRONYM --column=NOTES "${DATABASE[@]}")

        local __boton=$?
        local __title=__umu_id=__store=__codename=__acronym=__notes=0
        __title=$(echo "$__salida" | cut -d'|' -f1)
        __umu_id=$(echo "$__salida" | cut -d'|' -f2)
        __store=$(echo "$__salida" | cut -d'|' -f3)
        __codename=$(echo "$__salida" | cut -d'|' -f4)
        __acronym=$(echo "$__salida" | cut -d'|' -f5)
        __notes=$(echo "$__salida" | cut -d'|' -f6)

        to_debug_file "[INFO] umuMenu: the value of selected item is $__title|$__umu_id|$__store|$__codename|$__acronym|$__notes"

        case $__boton in
        0) 
            prefixMenu "$__title" "$__umu_id" "$__store" "$__codename"
            ;;
        2)
            # Update
            if download_database;then
                show_info "Database downloaded from Internet"
            else
                show_info "Failed  to download the database from the internet."
            fi
            ;;
        3)
            # SearchMenu
            __salida=$("$YAD" "$TITLE" "$ICON" --center --on-top --no-escape --button="OK":0 --form --field="Title:")
            __salida=${__salida::-1} ; __salida=$(echo "$__salida" | tr '[:upper:]' '[:lower:]')
            umuMenu "$__salida"
            break
            ;;
        4)
            # Show Fix
            show_fix "$__umu_id"
            ;;
        *) ;;
        esac
    done
    to_debug_file "[INFO] umuMenu: *** Exiting from Database Menu."
}

##
# Show the optionMenu Window
#
function optionMenu() {
    to_debug_file "[INFO] optionMenu: *** Entering in Option Menu."
    local __salida=

    __salida=$("$YAD" "$TITLE" "$ICON" --columns=1 --form --undecorated \
        --button="Save!$SAVE_ICON!Set options":0 \
        --button="About!$ABOUT_ICON!Version and about":1 \
        --button="Back!$EXIT_ICON!Return to main menu":2 \
        --buttons-layout=edge --align=center \
        --field="Where is the heroic config directory?:LBL" --field="Heroic config dir:DIR" '' "$HEROIC_CONFIG_DIR" \
        --field="Where will save the the exe files for run the games?:LBL" --field="Heroic runner dir:DIR" '' "$RUNNERS_PATH" \
        --field="Steamgriddb key:" "$GRIDKEY" )

    local __boton=$?

    case "$__boton" in
        0)
            HEROIC_CONFIG_DIR=$(echo "$__salida" | cut -d'|' -f2)
            RUNNERS_PATH=$(echo "$__salida" | cut -d'|' -f4)
            GRIDKEY=$(echo "$__salida" | cut -d'|' -f5)
            [ "$GRIDKEY" == "" ] && GRIDKEY=0
            save_options
            to_debug_file "[INFO] optionMenu: Setting the options and save them in $TOOLOPTIONFILE"
            show_info "$NOMBRE will be closed for the changes to take effect."
            exit 0
            ;;
        1)
            aboutMenu
            ;;
        *)
            #exiting
            to_debug_file "[INFO] optionMenu: Canceled."
            ;;
    esac
    to_debug_file "[INFO] optionMenu: *** Exiting from Option Menu."
}

##
# Show the ABOUT Window
#
function aboutMenu() {
    "$YAD" "$TITLE" "$ICON" --about --fixed --pname="$NOMBRE" --pversion="$VERSION" --comments='Plugin, add-on, companion to our Heroic Games Launcher. In addition, a UMU client and a UMU prefix creator.' \
        --authors="Paco Guerrero [fjgj1@hotmail.com]" --website="https://github.com/FranjeGueje"
    show_info "Versions:\n\t*Legendary (Windows) - 0.20.37\n\t*Nile (Windows) - 1.1.2\n\t*GOGDL (Windows) - 1.1.2\n\t*UMU-launcher - version 1.2.6 (3.11.7 (main, Jan 29 2024, 16:03:57) [GCC 13.2.1 20230801])'\n\n\
Thanks to my family for their patience... My wife and children have earned heaven.\nAnd to you, my Elena." 
}

##
# Create the umu-ed prefix
# $1 = title
# $2 = umu-id
# $3 = Store
# $4 = id of game (codename)
#
function prefixMenu() {
    if [ $# -ne 4 ]; then
        to_debug_file "[ERROR] prefixMenu: you have called the function wrong. There are FOUR parameters."
        return 1
    fi
    # Parameters
    local __title=$1 __umu_id=$2 __store=$3 __codename=$4
    local __proton=""
    # Search Proton
    while read -r line; do
        __proton="$__proton$(basename "$line")!"
    done < <(find "$STEAM_DIR/compatibilitytools.d/" -mindepth 1 -maxdepth 1 -type d -iname "*proton*")

    if [ "$__proton" == "" ]; then
        to_debug_file "[ERROR] prefixMenu: you don't have any GE-Proton or equivalent to run and to create the prefix."
        show_info "[ERROR] prefixMenu: you don't have any GE-Proton or equivalent to run and to create the prefix."
        return 2
    fi

    set +H
    # Result of YAD dialog
    local __salida=
    local __boton=0
    __salida=$("$YAD" "$TITLE" "$ICON" --center --on-top --form --width=200 --height=100 --sticky --no-markup --fixed --buttons-layout=spread \
            --field="Title:":RO "$__title" --field="Proton:!Proton to use":CB "${__proton::-1}" --field="Prefix:!Where the prefix will be created":DIR "" \
            --button="Create!$CREATE_PREFIX_ICON!Create a new prefix in this locatio":0 --button="Back!$EXIT_ICON!Return to last menu":1)
    __boton=$?

    if [ -n "$__salida" ];then
        local __prefix
        __proton=$(echo "$__salida" | cut -d'|' -f2)
        __prefix=$(echo "$__salida" | cut -d'|' -f3)
        to_debug_file "[INFO] HeroicMenu: The selected item is:\nTienda: $__store\nID: $__id\nTitle: $__name"
    fi

    if [ -d "$__prefix" ];then
        case $__boton in
            0)
                fBarra "Please, wait... YES, be pacient...\n\n$NOMBRE is creating the prefix with the fixes." & 
                sleep 1
                WINEPREFIX="$__prefix" GAMEID="$__umu_id" PROTONPATH="$STEAM_DIR/compatibilitytools.d/$__proton" STORE="$__store" "$UMULAUNCHER" "exit"
                fBarraStop
                show_info "Done! The prefix was created."
                ;;
            *)
                ;;
        esac
    fi
    to_debug_file "[INFO] prefixMenu: *** Exiting the menu to create umu prefix..."
}

##
# Show the HeroicMenu Window
#
function HeroicMenu() {
    # Result of YAD dialog
    local __salida=
    local __boton=0

    to_debug_file "[INFO] HeroicMenu: *** Entering in the Add Steam Menu."

    if ! check_Heroic_config; then
        optionMenu
        return
    fi

    # Load the heroic config and transform it
    load_Heroic_config "$HEROIC_CONFIG_DIR" "$MOUNT_PATH"
    # Create the dosdosdevices (unit) for games and utils (mount)
    symbolic_Heroic_links
    # Reload the installed games
    get_Heroic_games

    while [ $__boton -ne 1 ] && [ $__boton -ne 252 ]; do
        __salida=$("$YAD" "$TITLE" "$ICON" --center --list --width=640 --height=400 --hide-column=2 --sticky --no-markup --buttons-layout=spread \
            --button="All-in-one!$ADD_ICON!Add a game to Steam using third-party launchers on Windows, search the protonfix in umu-databas, link the prefix, ...":0 \
            --button="Create .bat!$UMU_ICON!Create the bat executable file. NOT add to Steam":20 \
            --button="Create Prefix!$UMU_ICON!Create the prefix applying the fixes on umu-database. NOT add to Steam":10 \
            --button="Cancel!$EXIT_ICON!Cancel this menu":252 \
            --column=Store --column=ID --column=Title "${INSTALLED_GAMES[@]}")

        local __boton=$?
        local __store=__id=__name
        
        if [ -n "$__salida" ];then
            IFS='|' read -r __store __id __name <<< "$__salida"
            to_debug_file "[INFO] HeroicMenu: The selected item is:\nTienda: $__store\nID: $__id\nTitle: $__name"
        fi

        case $__boton in
        0)  install_Heroic_game "$__name" "$__store" "$__id" ;;
        10) to_debug_file "[INFO] HeroicMenu: Start UMU-Prefix."
            prepare_umu-prefix "$__id" "$__store"
            ;;
        20)
            if show_question "$NOMBRE will create the bat file. This file is the executable to run the game on proton.\nWould you like to create the bat file?";then
                create_Heroic_bat "$(create_Heroic_runner "$__store" "$__id")" "$__name"
                show_info "File $__name created"
            fi
            ;;
        *)  to_debug_file "[INFO] HeroicMenu: Canceled." ;;
        esac
    done
    to_debug_file "[INFO] HeroicMenu: *** Exiting from Install Menu."
}

##
# Show the UbisoftMenu Window
#
function UbisoftMenu() {
    # Generamos toda la lista de juegos en __listGames
    to_debug_file "[INFO] UbisoftMenu: *** Entering in the Add Ubisoft game "
    local __pfxID __g __i
    local -a __listGames=()
    for id in "$STEAM_DIR"/steamapps/compatdata/*/ ;do
        if [ -d "$id/pfx/drive_c/Program Files (x86)/Ubisoft" ]  || 
            [ -d "$id/pfx/drive_c/Program Files/Ubisoft" ]; then
            __pfxID=$(basename "$id")
            if [ -f "$id"pfx/system.reg ];then
                while IFS='|' read -r __i __g; do
                    __listGames+=("$__pfxID" "$__i" "$__g")
                done < <(get_Ubi_games "$id/pfx/system.reg")
            fi
        fi
    done
    
    local __salida && __salida=$("$YAD" "$TITLE" "$ICON" --center --list --width=640 --height=400 --hide-column=2 --sticky --no-markup --buttons-layout=spread \
            --button="Add to Steam!$ADD_ICON!":0 \
            --button="Cancel!$EXIT_ICON!Cancel this menu":252 \
            --list --column=PFX --column=ID --column=NAME "${__listGames[@]}")
    local __boton=$?
    
    if [ $__boton == 0 ];then
        local __pfx __id __name __r __id_steam
        IFS='|' read -r __pfx __id __name <<< "$__salida"
        
        if create_Ubi_sh "$__id" "$__name" "$__pfx";then
            fBarra "Please, wait... YES, be pacient...\n\n$NOMBRE is adding the game to Steam." & 
            sleep 1
            __id_steam=$(add_steam_game "$RUNNERS_PATH/$__name")
            fBarraStop
            __r=$?

            case "$__r" in
                # All ok
                0)  download_all_grids "$__name" "$__id_steam"
                    show_info "$__name was successfully added to Steam."
                    ;;
                # Game exists
                1)  show_info "[ERROR] $__name was NOT added. A game with the same name already exists in Steam.\nPlease check or remove it."
                    ;;
                # General error
                *)  show_info "[ERROR] $__name was NOT added due to an unexpected Steam error."
                    ;;
            esac
        fi
    fi
    to_debug_file "[INFO] UbisoftMenu: *** Exiting from Ubisoft Menu."
}

##
# Show the FileMenu Window
#
function FileMenu() {
    to_debug_file "[INFO] FileMenu: *** Entering in the Add file game "
    local __salida && __salida=$("$YAD" "$TITLE" "$ICON" --center\
            --file --width=640 --height=400 --sticky --no-markup --buttons-layout=spread \
            --button="Add to Steam!$ADD_ICON!":0 \
            --button="Cancel!$EXIT_ICON!Cancel this menu":252 \
            )
    local __boton=$?

    if [ $__boton == 0 ];then
        if show_question "$NOMBRE will add the file to Steam like a game.\nWould you like to add the file?";then
            local __id_steam __r
            fBarra "Please, wait... YES, be pacient...\n\n$NOMBRE is adding the game to Steam." & 
            sleep 1
            __id_steam=$(add_steam_game "$__salida")
            fBarraStop
            __r=$?

            case "$__r" in
                # All ok
                0)  show_info "The file was successfully added to Steam."
                    open_steam_game "$__id_steam"
                    ;;
                # Game exists
                1)  show_info "[ERROR] The file was NOT added. A game with the same name already exists in Steam.\nPlease check or remove it."
                    ;;
                # General error
                *)  show_info "[ERROR] The file was NOT added due to an unexpected Steam error."
                    ;;
            esac
        fi
    fi
    to_debug_file "[INFO] FileMenu: *** Exiting from File Menu."
}

#!##############################################################################################################################################################
#!               Begin
#!####################################
# Preload de APP
pre_launch
# Show the app info
to_debug_file "******************************************"
to_debug_file "[INFO] *** Starting... $NOMBRE - v$VERSION"

# Check new version
update_new_version

# Main_menu loop
while true; do
    mainMenu
    resultado=$?
    [ "$resultado" -eq 252 ] && break
done

to_debug_file "[INFO] *** Finishing... $NOMBRE - v$VERSION"

exit 0
