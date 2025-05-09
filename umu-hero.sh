#!/bin/bash

##
# Initialize the script
#
function pre_launch(){
    NOMBRE="UMU-Hero"
    VERSION=1.1

    [ -z "$TOOLOPTIONFILE" ] && TOOLOPTIONFILE="$HOME/.config/umu-hero.conf"
    STEAM_DIR="$HOME/.local/share/Steam/"
    mkdir -p "$HOME/.local/share/umu-hero/"
    MOUNT_PATH="$HOME/.local/share/umu-hero/mount/"
    PROTONFIXES_PATH="$HOME/.local/share/umu-hero/umu-protonfixes/"
    DATABASE_FILE="$HOME/.local/share/umu-hero/umu-database.json"
    LINKS_PATH="/tmp/umu-hero/links"

    TOOL_PATH=$(readlink -f "$(dirname "$0")")
    BIN_PATH="$TOOL_PATH/bin/"
    LAUNCHER_PATH="$TOOL_PATH"/launchers/
    JQ="$BIN_PATH"jq
    YAD="$BIN_PATH"yad
    SHORTCUTSNAMEID="$BIN_PATH"shortcutsNameID
    UMULAUNCHER="$BIN_PATH"umu-run

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
    TITLE="--title=$NOMBRE - v$VERSION"
    ICON="--window-icon=$IMGICON"
    SEM="/tmp/.bar.lock"

    RUNNER_TEMPLATE="$TOOL_PATH/template.bat"

    [ -z "$TOOLOPTIONFILE" ] && TOOLOPTIONFILE="$HOME/.config/umu-hero.conf"
    load_options
}

##
# Initialize the script
#
function update_new_version(){
    if [ -n "$APPIMAGE" ]; then
        to_debug_file "[INFO] Check Updating for new version of $NOMBRE"
        # Es un appimage y si tengo internet
        if curl -s --head --request GET https://api.github.com --max-time 3 | grep "HTTP/" 2>/dev/null >/dev/null; then
            local sha_web
            sha_web=$(curl -L "$(curl -s https://api.github.com/repos/FranjeGueje/umu-hero/releases/latest | grep browser_download_url | cut -d '"' -f 4 | grep sha512sum 2>/dev/null)" 2>/dev/null)
            if diff <(sha512sum "$APPIMAGE" | cut -d ' ' -f1) <(echo "$sha_web" | cut -d ' ' -f1) >/dev/null 2>&1; then
                to_debug_file "[INFO] Is the same version"
            else
                if show_question "There is a new version of $NOMBRE. Do you want download it?" ; then
                    to_debug_file "[WARING] Updating $NOMBRE"
                    local URL
                    URL=$(curl -s https://api.github.com/repos/FranjeGueje/umu-hero/releases/latest | grep browser_download_url | cut -d '"' -f 4 | grep x86_64| grep ".AppImage")
                    wget -O "$APPIMAGE".bak -q --show-progress "$URL" >/dev/null 2>&1
                    # shellcheck disable=SC2181
                    if [ $? -eq 0 ]; then
                        to_debug_file "[INFO] Uploaded to last version."
                        show_info "Uploaded to last version.\nRun again $NOMBRE"
                        mv "$APPIMAGE".bak "$APPIMAGE" && chmod +x "$APPIMAGE"
                        exit 0
                    else
                        to_debug_file "[ERROR] Cannot download the latest version."
                        show_info "Cannot download the latest version."
                    fi
                fi
            fi
        else
            to_debug_file "[WARNING] You don't have Internet"
        fi
    fi
}

#!#################################### Support function
##
# Save a msg to debug
#
#* PARAMETERS
# $1 = Text to Debub file
#
function to_debug_file() {
    [ -n "$DEBUG" ] && printf "%s - %s\n" "$(date +"%Y-%m-%d %H:%M:%S")" "$1" 1>&2
}

##
# fileRandomInDir
# Return a random file from dir.
#
# $1 = source varname ( dir )
# return The random file in dir.
#
function fileRandomInDir() {
    local __dir=$1

    find "$__dir" -mindepth 0 -maxdepth 1 -type f | shuf -n 1
}


##
# load_options
# Load the options from the file
#
function load_options() {
    if [ -f "$TOOLOPTIONFILE" ]; then
        to_debug_file "[INFO] Load_options: using the options of file $TOOLOPTIONFILE"
        [ -z "$HEROIC_CONFIG_DIR" ] && HEROIC_CONFIG_DIR=$(cut -d '|' -f1 <"$TOOLOPTIONFILE")
        [ -z "$RUNNERS_PATH" ] && RUNNERS_PATH=$(cut -d '|' -f2 <"$TOOLOPTIONFILE")
        GRIDKEY=$(cut -d '|' -f3 <"$TOOLOPTIONFILE")
    else
        to_debug_file "[WARNING] Load_options: Using the default options"
        [ -z "$HEROIC_CONFIG_DIR" ] && HEROIC_CONFIG_DIR="$HOME/.var/app/com.heroicgameslauncher.hgl/config/heroic/"
        [ -z "$RUNNERS_PATH" ] && RUNNERS_PATH="$HOME/Games/$NOMBRE/"
        GRIDKEY=0
    fi
}

##
# save_options
# Save the options to a file
#
function save_options() {
    printf "%s|%s|%s" "$HEROIC_CONFIG_DIR" "$RUNNERS_PATH" "$GRIDKEY" > "$TOOLOPTIONFILE"
}


##
# add_steam_game
# Add a game to Steam
#
# $1 = source varname ( The executable of game )
# return 0 is correct
# return 1 is game exists
# return 252 error in steam
#
function add_steam_game() {
    to_debug_file "[INFO] add_steam_game: *** Entering to add_steam_game."
    # Exist "the steam:// protocol?"
    if ! grep -i "x-scheme-handler/steam=" <"$HOME"/.config/mimeapps.list >/dev/null 2>/dev/null; then
        echo "x-scheme-handler/steam=steam.desktop;" >>"$HOME"/.config/mimeapps.list
    fi

    # Exist the game on Steam?
    local __name
    __name=$(basename "$1")
    for i in "$STEAM_DIR"/userdata/*/config/shortcuts.vdf; do "$SHORTCUTSNAMEID" "$i" ; done | grep -w "$__name" >/dev/null
    local __resultado=$?
    if [ $__resultado -eq 0 ];then
        # The game exists :(
        to_debug_file "[ERROR] add_steam_game: ****The game exists. $NOMBRE cannot add to Steam this game."
        return 1
    fi

    local __name_without_extension
    __name_without_extension=$(basename "$1" .bat)
    for i in "$STEAM_DIR"/userdata/*/config/shortcuts.vdf; do "$SHORTCUTSNAMEID" "$i" ; done | grep -w "$__name_without_extension" >/dev/null
    local __resultado=$?
    if [ $__resultado -eq 0 ];then
        # The game exists :(
        to_debug_file "[ERROR] add_steam_game: ****The game exists. $NOMBRE cannot add to Steam this game."
        return 1
    fi
    
    local __encodedUrl=
    __encodedUrl="steam://addnonsteamgame/$(python3 -c "import urllib.parse;print(urllib.parse.quote(\"$1\", safe=''))")"
    [ -f "/tmp/addnonsteamgamefile" ] && rm -Rf "/tmp/addnonsteamgamefile"
    touch /tmp/addnonsteamgamefile
    xdg-open "$__encodedUrl"
    sleep 6

    local __id=
    __id=$(for i in "$STEAM_DIR"/userdata/*/config/shortcuts.vdf; do "$SHORTCUTSNAMEID" "$i" ; done | grep -w "$__name" | cut -f2 -d$'\t')
    
    # If __id is a integer then it is the id of game
    if [[ "$__id" =~ ^-?[0-9]+$ ]]; then
        to_debug_file "[INFO] add_steam_game: The id of the new game is $__id ."
        echo -e "$__id"
        __id=0
    else
        to_debug_file "[ERROR] add_steam_game: There are an error ..."
        __id=252
    fi
    
    to_debug_file "[INFO] add_steam_game: *** Exiting from add_steam_game."

    return "$__id"

}

##
# download_grids
# Download the images (grids) for a game
# 
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
    curl -s -X GET -H "Authorization: Bearer $__token" "https://www.steamgriddb.com/api/v2/search/autocomplete/$__name_encoded" > "$json"
    if [ "$("$JQ" -r '.data | length' < "$json")" -gt 0 ]; then
        local __id=
        __id=$("$JQ" -r .data[0].id < "$json")

        # GRID_H
        curl -s -X GET -H "Authorization: Bearer $__token" "https://www.steamgriddb.com/api/v2/grids/game/$__id?limit=1&dimensions=460x215" > "$json"
        if [ "$("$JQ" -r .success < "$json")" == "true" ] && [ "$("$JQ" -r .total < "$json")" -gt 0 ]; then
            curl -s -o "$__fichero".png "$("$JQ" -r .data[0].url < "$json")"
        fi

        # GRID_V
        curl -s -X GET -H "Authorization: Bearer $__token" "https://www.steamgriddb.com/api/v2/grids/game/$__id?limit=1&dimensions=600x900" > "$json"
        if [ "$("$JQ" -r .success < "$json")" == "true" ] && [ "$("$JQ" -r .total < "$json")" -gt 0 ]; then
            curl -s -o "$__fichero"p.png "$("$JQ" -r .data[0].url < "$json")"
        fi

        # HEROES
        curl -s -X GET -H "Authorization: Bearer $__token" "https://www.steamgriddb.com/api/v2/heroes/game/$__id?limit=1" > "$json"
        if [ "$("$JQ" -r .success < "$json")" == "true" ] && [ "$("$JQ" -r .total < "$json")" -gt 0 ]; then
            curl -s -o "$__fichero"_hero.png "$("$JQ" -r .data[0].url < "$json")"
        fi

        # LOGOS
        curl -s -X GET -H "Authorization: Bearer $__token" "https://www.steamgriddb.com/api/v2/logos/game/$__id?limit=1" > "$json"
        if [ "$("$JQ" -r .success < "$json")" == "true" ] && [ "$("$JQ" -r .total < "$json")" -gt 0 ]; then
            curl -s -o "$__fichero"_logo.png "$("$JQ" -r .data[0].url < "$json")"
        fi

        # ICONS
        curl -s -X GET -H "Authorization: Bearer $__token" "https://www.steamgriddb.com/api/v2/icons/game/$__id?limit=1" > "$json"
        if [ "$("$JQ" -r .success < "$json")" == "true" ] && [ "$("$JQ" -r .total < "$json")" -gt 0 ]; then
            curl -s -o "$__fichero"_icon.ico "$("$JQ" -r .data[0].url < "$json")"
        fi

    fi
    rm "$json"
}
#!#################################### UMU Function

##
# reload_database
# Load in memory the umu-database
#
# $1 = source varname ( [OPTIONAL] text to search)
#
function reload_database() {
    #* REMEMBER: TITLE + UMU_ID + STORE + CODENAME + ACRONYM + NOTES
    __search=$1
    # Requisite of jq
    # shellcheck disable=SC2016
    readarray -t -d '|' \
        DATABASE < <("$JQ" -r -j --arg v "$__search" '.[] | select(.title | ascii_downcase | contains ($v)) | "\(.title)|\(.umu_id)|\(.store)|\(.codename)|\(.acronym)|\(.notes)|"' \
        "$DATABASE_FILE"  | iconv -c)

}

##
# download_database
#
function download_database() {
    local __umu_temp="/tmp/umu-database.json.temp"
    wget https://umu.openwinecomponents.org/umu_api.php -q -O "$__umu_temp"

    if which git > /dev/null 2>&1; then
        if [ -d "$PROTONFIXES_PATH" ];then
            (cd "$PROTONFIXES_PATH" && git pull)
        else
            (cd "$HOME/.local/share/umu-hero/" && git clone https://github.com/Open-Wine-Components/umu-protonfixes)
        fi
    fi

    if [ "$(stat -c %s "$__umu_temp")" -eq 0 ];then
        to_debug_file "[WARNING] download_database-game: database NOT downloaded from Internet"
        return 1
    else
        to_debug_file "[INFO] download_database-game: database downloaded from Internet"
        mv "$__umu_temp" "$DATABASE_FILE"
        return 0
    fi
}

##
# show_fix
#
# $1 = source varname ( [OPTIONAL] umu_id to show)
#
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
# search_umu-game
#
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
    local __umu_game __result=1
    if __umu_game=$(curl -s "https://umu.openwinecomponents.org/umu_api.php?store=$__store&codename=$__id");then
        if echo "$__umu_game" | grep -w "\[\]"; then
            to_debug_file "[WARNING] search_umu-game: Game NOT found on umu-database."
            __result=1
        else
            __nombre=$(echo -e "$__umu_game" | "$JQ" -r '.[].title')
            __umu_id=$(echo -e "$__umu_game" | "$JQ" -r '.[].umu_id')
            to_debug_file "[INFO] search_umu-game: Game FOUND on umu-database: $__nombre | $__umu_id"
            echo -e "$__umu_id"
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
# prepare_umu-prefix
#
# $1 = game_id
# $2 = Store
#
function prepare_umu-prefix() {
    to_debug_file "[INFO] prepare_umu-prefix: *** Begin the process to create the PREFIX for the umu-game..."
    if [ $# -ne 2 ]; then
        to_debug_file "[ERROR] prepare_umu-prefix: you have called the function wrong.."
        return 1
    fi
    local __game_id=$1 __store=$2
    local __prefix __proton
    __prefix=$(get_prefix_hg "$__id")
    __proton=$(get_protondir_hg "$__id")
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
        WINEPREFIX="$__prefix" GAMEID="$__game_id" PROTONPATH="$__proton" STORE="$__store" "$UMULAUNCHER" "exit"
        cp "$LINKS_PATH"/* "$__prefix"/pfx/drive_c/. -Rf

        fBarraStop
        show_info "Done! The prefix was created."
    else
        show_info "Ok. Don't prepare the prefix!"
    fi

    to_debug_file "[INFO] prepare_umu-prefix: *** END the process to create the PREFIX for the umu-game..."
}

##
# Progress bar
#
# Funcion de barra
# $1 = source varname ( Text to show - OPTIONAL)
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
        "$YAD" "$TITLE" "$ICON" --text="$__text" --progress --percentage=0 --auto-close --no-buttons
    )
}
# Funcion para detener la barra
function fBarraStop() {
    rm "$SEM" 
}

#!#################################### YAD function
##
# show_tmp_msg
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
# show_info
# Show a message on screen and show a OK button
#
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
# show_question
# Show a message with a question
#
# $1 = source varname ( Text to show )
#
function show_question(){
    "$YAD" "$TITLE" "$ICON" --text="$1" --center --on-top --align=center --no-markup --fixed --button="OK:0" --button="Cancel:1"

    local __respuesta=$?
    return "$__respuesta"
}

#!#################################### APP function
##
# check_config
#
function check_config(){
    to_debug_file "[INFO] check_config: *** The config is being checked by $NOMBRE"
    if [ ! -d "$HEROIC_CONFIG_DIR" ];then
        to_debug_file "[ERROR] check_config: The CONFIG DIR of Heroic not exist."
        echo -e "[ERROR] check_config: The CONFIG DIR of Heroic not exist."
        show_tmp_msg "The Config Dir of Heroic not exist. Please, open the option menu and configure the dir property"
        return 1
    else
        if [ ! -f "$HEROIC_CONFIG_DIR"/config.json ];then
            to_debug_file "[ERROR] check_config: The CONFIG DIR of Heroic exists but it's NOT valid."
            echo -e "[ERROR] check_config: The CONFIG DIR of Heroic exists but it's NOT valid."
            show_tmp_msg "The Config Dir of Heroic exists but it's not valid. Please, open the option menu and configure the dir property"
            return 1
        else
            to_debug_file "[INFO] Pre_laucheck_confignch: The CONFIG DIR of Heroic exists and it's valid."
            [ -z "$GAMES_DIR" ] && GAMES_DIR=$("$JQ" -r -c '.defaultSettings.defaultInstallPath' "$HEROIC_CONFIG_DIR"/config.json)
            [ -z "$STEAM_DIR" ] && STEAM_DIR=$("$JQ" -r -c '.defaultSettings.defaultSteamPath' "$HEROIC_CONFIG_DIR"/config.json)
            if [ ! -d "$GAMES_DIR" ];then
                to_debug_file "[ERROR] check_config: The DIR of GAMES NOT exist."
                show_tmp_msg "The dir of Games not exist. Please, open the option menu and configure the dir property"
                return 1
            else
                to_debug_file "[INFO] check_config: The DIR of GAMES exists and it's valid."
            fi
        fi
    fi
    if [ ! -d "$RUNNERS_PATH" ];then
        if mkdir -p "$RUNNERS_PATH" ;then
            to_debug_file "[INFO] check_config: The DIR of RUNNER don't exists but we create a valid dir."
        else
            to_debug_file "[ERROR] check_config: The DIR of RUNNER don't exists but we CANNOT create a valid dir."
            echo "[ERROR] check_config: The DIR of RUNNER don't exists but we CANNOT create a valid dir."
            exit 1
        fi
    fi
    return 0
}

##
# Windowized config
#
#* PARAMETERS
# $1 = mode {legendary,gogdl,nile}
# $2 = file json to read
#
function windowized() {
    to_debug_file "[INFO] Windowized: *** The config is being windowized by $NOMBRE."
    if [ $# -ne 2 ]; then
        to_debug_file "[ERROR] Windowized: you have called the function wrong. There are two parameters."
        return 1
    fi

    local __archivo=$2 __salida
    __salida="$__archivo".json
    case "$1" in
    l | legendary)
        to_debug_file "[INFO] Windowized: legendary mode."
        sed -s 's|"install_path":.*/\([^/]\+\)\"|"install_path": \"c:\\\\games\\\\\1\"|' < "$__archivo" > "$__salida"
        ;;
    g | gogdl)
        to_debug_file "[INFO] Windowized: gogdl mode."
        sed -s 's|"install_path":.*/\([^/]\+\)\"|"install_path": \"c:\\\\games\\\\\1\"|' < "$__archivo" > "$__salida"
        ;;
    n | nile)
        to_debug_file "[INFO] Windowized: nile mode."
        sed -s 's|"path":.*/\([^/]\+\)\"|"path":\"c:\\\\games\\\\\1\"|' < "$__archivo" > "$__salida"
        ;;
    esac
}

##
# load heroic config
#
#* PARAMETERS
# $1 = Heroic Game launcher config dir
# $2 = output dir. Where the mount dir will be configurated
#
function load_heroic_config() {
    to_debug_file "[INFO] Load_heroic_config: *** The config of Heroic is loading..."
    if [ $# -ne 2 ]; then
        to_debug_file "[ERROR] Load_heroic_config: you have called the function wrong. There are two parameters."
        return 1
    fi

    local __heroic=$1 __mount=$2

    mkdir -p "$__mount" 2> /dev/null

    if [ ! -d "$__heroic" ] || [ ! -d "$__mount" ]; then
        to_debug_file "[ERROR] Load_heroic_config: the directory to find heroic config not exist or the mount dir is inaccessible."
        return 1
    fi

    mkdir -p "$MOUNT_PATH"/gog_store "$MOUNT_PATH"/gogdl "$MOUNT_PATH"/legendary "$MOUNT_PATH"/nile "$MOUNT_PATH"/bin 2> /dev/null
    rsync -a "$LAUNCHER_PATH"/* "$MOUNT_PATH"/bin/. > /dev/null 2> /dev/null

    # GOG config directories
    if [ -d "$__heroic/gog_store/" ];then
        rm "$__mount/gog_store/"* -Rf 2> /dev/null
        ln -s "$__heroic/gog_store/"* "$__mount"/gog_store/.
        mv "$__mount"/gog_store/installed.json "$__mount"/gog_store/installed
        windowized g "$__mount"/gog_store/installed
        to_debug_file "[INFO] Load_heroic_config: the gog_store config is created."
    fi
    if [ -d "$__heroic/gogdlConfig/heroic_gogdl/" ];then
        rm "$__mount/gogdl/"* -Rf 2> /dev/null
        ln -s "$__heroic/gogdlConfig/heroic_gogdl/"* "$__mount"/gogdl/.
        to_debug_file "[INFO] Load_heroic_config: the gogdl config is created."
    fi
    # Legendary config directories
    if [ -d "$__heroic/legendaryConfig/legendary/" ];then
        rm "$__mount/legendary/"* -Rf 2> /dev/null
        ln -s "$__heroic/legendaryConfig/legendary/"* "$__mount"/legendary/.
        mv "$__mount"/legendary/installed.json "$__mount"/legendary/installed
        windowized l "$__mount"/legendary/installed
        to_debug_file "[INFO] Load_heroic_config: the legendary config is created."
    fi
    # Nile config directories
    if [ -d "$__heroic/nile_config/nile/" ];then
        rm "$__mount/nile/"* -Rf 2> /dev/null
        ln -s "$__heroic/nile_config/nile/"* "$__mount"/nile/.
        mv "$__mount"/nile/installed.json "$__mount"/nile/installed
        windowized n "$__mount"/nile/installed
        to_debug_file "[INFO] Load_heroic_config: the legendary config is created."
    fi

}

##
# Create symbolic links
#
function create_symbolic_links() {
    to_debug_file "[INFO] Create_symbolic_links: *** $NOMBRE is creating the symbolic links"
    [ -d "$LINKS_PATH" ] && rm "$LINKS_PATH"/* 2> /dev/null
    mkdir -p "$LINKS_PATH"
    ln -s "$MOUNT_PATH" "$LINKS_PATH/heroic"
    ln -s "$GAMES_DIR" "$LINKS_PATH/games"
}

##
# Create runner
#
#* PARAMETERS
# $1 = store {l,g,n} (legendary gogdl or nile)
# $2 = id of game
#
function create_runner() {
    to_debug_file "[INFO] Create_runner: *** $NOMBRE is creating a runner."
    if [ $# -ne 2 ]; then
        to_debug_file "[ERROR] Create_runner: you have called the function wrong. There are two parameters."
        return 1
    fi

    local __store=$1 __id=$2
    case "$__store" in
    l | legendary | EPIC)
        to_debug_file "[INFO] Create_runner: Creating a runner in legendary mode."
        # Buscar el juego en la configuración de instalados
        printf "@legendary launch %s\n" "$__id"
        ;;
    g | gogdl | GOG)
        to_debug_file "[INFO] Create_runner: Creating a runner in gogdl mode."
        # Buscar el juego en la configuración de instalados
        # shellcheck disable=SC2016
        game_path=$("$JQ" -r --arg v "$__id" '.installed[] | select(.appName == $v) | .install_path' "$MOUNT_PATH/gog_store/installed.json")
        printf '@gogdl --auth-config-path c:\\heroic\\gog_store\\auth.json launch --platform windows "%s" %s\n' "$game_path" "$__id"
        ;;
    n | nile | AMAZON)
        to_debug_file "[INFO] Create_runner: Creating a runner in nile mode."
        # Buscar el juego en la configuración de instalados
        printf "@nile launch %s\n" "$__id"
        ;;
    esac

    to_debug_file "[INFO] Create_runner: runner created."
}

##
# Create bat
#
#* PARAMETERS
# $1 = the command line to run
#
function create_bat() {
    to_debug_file "[INFO] Create_bat: *** $NOMBRE is creating a executable to run on Windows (or wine)."
    if [ $# -ne 2 ]; then
        to_debug_file "[ERROR] Create_bat: you have called the function wrong. There are two parameters."
        return 1
    fi

    local __runner=$1 __name=$2
    grep -v -w "@rem" < "$RUNNER_TEMPLATE" > "$RUNNERS_PATH"/"$__name".bat
    printf "%s\n" "$__runner" >> "$RUNNERS_PATH"/"$__name".bat
    to_debug_file "[INFO] Create_bat: file created with content:\n $(cat "$RUNNERS_PATH"/"$__name".bat)"
}

##
# ALL process to install a steam game
#
#* PARAMETERS
# $1 = Name of game
# $2 = Store
# $3 = id of game
#
function do_install_game() {
    to_debug_file "[INFO] do_install_game: *** Begin the process to ADD TO STEAM..."
    if [ $# -ne 3 ]; then
        to_debug_file "[ERROR] do_install_game: you have called the function wrong. There are THREE parameters."
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
        __r=$(create_runner "$__store" "$__id")
        create_bat "$__r" "$__name"
        __id_steam=$(add_steam_game "$RUNNERS_PATH"/"$__name".bat)
        __r=$?

        case "$__r" in
            0) # All ok
                # Link the prefix
                if [ "$GRIDKEY" != "0" ];then
                    to_debug_file "[INFO] InstallMenu: It will download the grid images for $__name."
                    local __dir_tmp=
                    __dir_tmp=$(mktemp -d /tmp/"$NOMBRE".XXXXXX)
                    
                    (cd "$__dir_tmp" && download_grids "$GRIDKEY" "$__name" "$__id_steam"
                    for dir in "$STEAM_DIR"/userdata/*/config/grid; do 
                        cp "$__dir_tmp"/* "$dir" 
                    done
                    rm -r "$__dir_tmp"
                    ) &

                fi
                local __prefix
                __prefix=$(get_prefix_hg "$__id")
                [ ! -d "$__prefix" ] && mkdir -p "$__prefix"
                ln -s "$__prefix"/ "$STEAM_DIR/steamapps/compatdata/$__id_steam"
                mkdir -p "$STEAM_DIR"/steamapps/compatdata/"$__id_steam"/pfx/drive_c
                cp "$LINKS_PATH"/* "$STEAM_DIR"/steamapps/compatdata/"$__id_steam"/pfx/drive_c/. -Rf
                show_info "$__name was successfully added to Steam."
                # Search the game in umu-database
                prepare_umu-prefix umu-"$__id" "$__store"
                if show_question "Would you like to open the properties of the newly added game?";then
                    xdg-open "steam://gameproperties/$__id_steam"
                fi
                ;;
            1) # Game exists
                show_info "[ERROR] $__name was NOT successfully added to Steam. The game exist with the same name on Steam.\nPlease, check the game on steam or remove it."
                ;;
            *) # General error
                show_info "[ERROR] $__name was NOT successfully added to Steam. There has been an unexpected error on Steam."
                ;;
        esac
        
    else
        to_debug_file "[INFO] do_install_game: Canceled."
    fi
}
##
# Read installed games
#
function read_installed_games() {
    local installed_gog=installed_epic=installed

    to_debug_file "[INFO] read_installed_games: *** Searching installed games."
    ##############################
    # GOG
    if [ -f "$MOUNT_PATH"/gog_store/installed.json ]; then
        to_debug_file "[INFO] read_installed_games: Searching installed games on GOG."
        mapfile -t installed_gog < <("$JQ" -r '.installed[]  | "GOG\n\(.appName)\n\(.install_path)"' "$MOUNT_PATH"/gog_store/installed.json | sed 's/.*\\\(.*\)/\1/' | iconv -c)
    fi

    ##############################
    # EPIC
    if [ -f "$MOUNT_PATH"/legendary/installed.json ]; then
        to_debug_file "[INFO] read_installed_games: Searching installed games on EPID."
        mapfile -t installed_epic < <("$JQ" -r '.[] | "EPIC\n\(.app_name)\n\(.title)"' "$MOUNT_PATH"/legendary/installed.json | iconv -c)
    fi

    ##############################
    # AMAZON
    if [ -f "$MOUNT_PATH"/nile/installed.json ]; then
        to_debug_file "[INFO] read_installed_games: Searching installed games on AMAZON."
        mapfile -t installed_amz < <("$JQ" -r '.[] | "AMAZON\n\(.id)\n\(.path)"' "$MOUNT_PATH"/nile/installed.json | sed 's/.*\\\(.*\)/\1/' | iconv -c)
    fi
    
    INSTALLED_GAMES=("${installed_gog[@]}" "${installed_epic[@]}" "${installed_amz[@]}")

    to_debug_file "[INFO] read_installed_games: showing the ALL analyzed installed games:"
    to_debug_file "$(for item in "${INSTALLED_GAMES[@]}"; do echo "$item" ;done)"
    to_debug_file "[INFO] read_installed_games: *** Searched installed games."

}

## 
# Get prefix of heroic game
#
# $1 = id of game
#
function get_prefix_hg(){
    local __id=$1 __result
    "$JQ" -r ".\"$__id\".winePrefix" "$HEROIC_CONFIG_DIR/GamesConfig/$__id.json"
}

## 
# Get proton dir of heroic game
#
# $1 = id of game
#
function get_protondir_hg(){
    local __id=$1 __result
    dirname "$("$JQ" -r ".\"$__id\".wineVersion.bin" "$HEROIC_CONFIG_DIR/GamesConfig/$__id.json")"
}

## 
# Get alternative executable of heroic game
#
# $1 = id of game
#
# function get_altexec_hg(){
#     local __id=$1 __result
#     "$JQ" -r ".\"$__id\".targetExe" "$HEROIC_CONFIG_DIR/GamesConfig/$__id.json"
# }

#!#################################### Menu function
##
# Show the mainMenu Window
#
function mainMenu() {
    to_debug_file "[INFO] mainMenu: *** Entering in Main Menu."

    IMGSPLASH=$(fileRandomInDir "$IMGSPLASH_DIR")

    "$YAD" "$TITLE" "$ICON" --center --width=250 --columns=1 --image="$IMGSPLASH" \
        --button="Heroic Games!$LIBRARY_ICON!Tasks for your installed Heroic Games":0 \
        --button="UMU Prefix!$UMU_ICON!Prepare an extra Wine Prefix":2 \
        --button="Options!$OPTION_ICON!Set the options":1 \
        --button="Exit!$EXIT_ICON!Exit from $NOMBRE":252 \
        --align=center --buttons-layout=edge --undecorated
    local __boton=$?
    
    case $__boton in
        0)  installMenu ;;
        1)  optionMenu ;;
        2)  umu_databaseMenu ;;
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

#
##
# Create the umu-ed prefix
#
#* PARAMETERS
# $1 = title
# $2 = umu-id
# $3 = Store
# $4 = id of game (codename)
#
function create_prefixMenu() {
    if [ $# -ne 4 ]; then
        to_debug_file "[ERROR] create_prefixMenu: you have called the function wrong. There are FOUR parameters."
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
        to_debug_file "[ERROR] create_prefixMenu: you don't have any GE-Proton or equivalent to run and to create the prefix."
        show_info "[ERROR] create_prefixMenu: you don't have any GE-Proton or equivalent to run and to create the prefix."
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
        to_debug_file "[INFO] InstallMenu: The selected item is:\nTienda: $__store\nID: $__id\nTitle: $__name"
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
    to_debug_file "[INFO] create_prefixMenu: *** Exiting the menu to create umu prefix..."
}

#
##
# Show the installMenu Window
#
function installMenu() {
    # Result of YAD dialog
    local __salida=
    local __boton=0

    to_debug_file "[INFO] InstallMenu: *** Entering in the Add Steam Menu."

    if ! check_config; then
        optionMenu
        return
    fi

    # Load the heroic config and transform it
    load_heroic_config "$HEROIC_CONFIG_DIR" "$MOUNT_PATH"
    # Create the dosdosdevices (unit) for games and utils (mount)
    create_symbolic_links
    # Reload the installed games
    read_installed_games

    while [ $__boton -ne 1 ] && [ $__boton -ne 252 ]; do
        __salida=$("$YAD" "$TITLE" "$ICON" --center --list --width=640 --height=400 --hide-column=2 --sticky --no-markup --buttons-layout=spread \
            --button="Hyper-Connect to Steam!$ADD_ICON!Add a game to Steam using third-party launchers on Windows, search the protonfix in umu-databas, link the prefix, ...":0 \
            --button="Only Create UMU-Prefix!$UMU_ICON!Create the prefix applying the fixes on umu-database. NOT add to Steam":10 \
            --button="Cancel!$EXIT_ICON!Cancel this menu":252 \
            --column=Store --column=ID --column=Title "${INSTALLED_GAMES[@]}")

        local __boton=$?
        local __store=__id=__name
        
        if [ -n "$__salida" ];then
            __store=$(echo "$__salida" | cut -d'|' -f1)
            __id=$(echo "$__salida" | cut -d'|' -f2)
            __name=$(echo "$__salida" | cut -d'|' -f3)
            to_debug_file "[INFO] InstallMenu: The selected item is:\nTienda: $__store\nID: $__id\nTitle: $__name"
        fi

        case $__boton in
        0)  do_install_game "$__name" "$__store" "$__id" ;;
        10) to_debug_file "[INFO] InstallMenu: Start UMU-Prefix."
            prepare_umu-prefix umu-"$__id" "$__store"
            ;;
        *)  to_debug_file "[INFO] InstallMenu: Canceled." ;;
        esac
    done
    to_debug_file "[INFO] InstallMenu: *** Exiting from Install Menu."
}

##
# Show the optionMenu Window
#
function optionMenu() {
    to_debug_file "[INFO] optionMenu: *** Entering in Option Menu."
    local __salida=

    __salida=$("$YAD" "$TITLE" "$ICON" --columns=1 --form --image="$(fileRandomInDir "$IMGSPLASH_DIR")" \
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
# aboutMenu
# Show the ABOUT Window
#
function aboutMenu() {
    "$YAD" "$TITLE" "$ICON" --about --fixed --pname="$NOMBRE" --pversion="$VERSION" --comments='Plugin, add-on, companion to our Heroic Games Launcher. In addition, a UMU client and a UMU prefix creator.' \
        --authors="Paco Guerrero [fjgj1@hotmail.com]" --website="https://github.com/FranjeGueje"
    show_info "Versions:\n\t*Legendary (Windows) - 0.20.34\n\t*Nile (Windows) - 1.1.2\n\t*GOGDL (Windows) - 2.15.2\n\t*UMU-launcher - version 1.2.6 (3.11.7 (main, Jan 29 2024, 16:03:57) [GCC 13.2.1 20230801])'\n\n\
Thanks to my family for their patience... My wife and children have earned heaven.\nAnd to you, my Elena." 
}

##
# umu_databaseMenu
#
# $1 = source varname ( [OPTIONAL] text to search)
function umu_databaseMenu() {
    to_debug_file "[INFO] umu_databaseMenu: *** Entering in Database Menu."
    local __search=$1

    
    if [ ! -f "$DATABASE_FILE" ];then
        to_debug_file "[INFO] umu_databaseMenu: Database on local is missing. Database will be downloaded from Internet."
        if ! download_database;then
            to_debug_file "[INFO] umu_databaseMenu: Database can NOT be downloaded from Internet."
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

        to_debug_file "[INFO] umu_databaseMenu: the value of selected item is $__title|$__umu_id|$__store|$__codename|$__acronym|$__notes"

        case $__boton in
        0) 
            create_prefixMenu "$__title" "$__umu_id" "$__store" "$__codename"
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
            umu_databaseMenu "$__salida"
            break
            ;;
        4)
            # Show Fix
            show_fix "$__umu_id"
            ;;
        *) ;;
        esac
    done
    to_debug_file "[INFO] umu_databaseMenu: *** Exiting from Database Menu."
}

#!####################################
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
