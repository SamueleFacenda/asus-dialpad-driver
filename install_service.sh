#!/usr/bin/env bash

source non_sudo_check.sh

# ENV VARS
if [ -z "$CONFIG_FILE_DIR_PATH" ]; then
    CONFIG_FILE_DIR_PATH="/usr/share/asus-dialpad-driver"
fi
if [ -z "$LAYOUT_NAME" ]; then
    LAYOUT_NAME="default"
fi
if [ -z "$LOGS_DIR_PATH" ]; then
    LOGS_DIR_PATH="/var/log/asus-dialpad-driver"
fi
if [ -z "$SERVICE_INSTALL_DIR_PATH" ]; then
    SERVICE_INSTALL_DIR_PATH="/usr/lib/systemd/user"
fi

echo "Systemctl service"
echo

read -r -p "Do you want install systemctl service? [y/N]" RESPONSE
case "$RESPONSE" in [yY][eE][sS]|[yY])

    SERVICE=1

    SERVICE_FILE_PATH=asus_dialpad_driver.service
    SERVICE_WAYLAND_FILE_PATH=asus_dialpad_driver.wayland.service
    SERVICE_X11_FILE_PATH=asus_dialpad_driver.x11.service
    SERVICE_INSTALL_FILE_NAME="asus_dialpad_driver@.service"

    XDG_RUNTIME_DIR=$(echo $XDG_RUNTIME_DIR)
    DBUS_SESSION_BUS_ADDRESS=$(echo $DBUS_SESSION_BUS_ADDRESS)
    XAUTHORITY=$(echo $XAUTHORITY)
    DISPLAY=$(echo $DISPLAY)
    WAYLAND_DISPLAY=$(echo $WAYLAND_DISPLAY)
    XDG_SESSION_TYPE=$(echo $XDG_SESSION_TYPE)
    ERROR_LOG_FILE_PATH="$LOGS_DIR_PATH/error.log"

    echo
    echo "LAYOUT_NAME: $LAYOUT_NAME"
    echo "CONFIG_FILE_DIR_PATH: $CONFIG_FILE_DIR_PATH"
    echo
    echo "env var DISPLAY: $DISPLAY"
    echo "env var WAYLAND_DISPLAY: $WAYLAND_DISPLAY"
    echo "env var AUTHORITY: $XAUTHORITY"
    echo "env var XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"
    echo "env var DBUS_SESSION_BUS_ADDRESS: $DBUS_SESSION_BUS_ADDRESS"
    echo "env var XDG_SESSION_TYPE: $XDG_SESSION_TYPE"
    echo
    echo "ERROR LOG FILE: $ERROR_LOG_FILE_PATH"

    # with no gdm is env var XDG_SESSION_TYPE tty - https://github.com/asus-linux-drivers/asus-numberpad-driver/issues/185
    if [ "$XDG_SESSION_TYPE" == "tty" ] || [ "$XDG_SESSION_TYPE" == "" ]; then

        echo
        echo "Env var XDG_SESSION_TYPE is: `$XDG_SESSION_TYPE`"
        echo
        echo "Please, select your display manager:"
        echo
        PS3="Please enter your choice "
        OPTIONS=("x11" "wayland" "Quit")
        select SELECTED_OPT in "${OPTIONS[@]}"; do
            if [ "$SELECTED_OPT" = "Quit" ]; then
                exit 0
            fi

            XDG_SESSION_TYPE=$SELECTED_OPT

            echo
            echo "(SET UP FOR DRIVER ONLY) env var XDG_SESSION_TYPE: $XDG_SESSION_TYPE"
            echo

            if [ -z "$LAYOUT_NAME" ]; then
                echo "invalid option $REPLY"
            else
                break
            fi
        done
    fi

    echo

    if [ "$XDG_SESSION_TYPE" == "x11" ]; then
        cat "$SERVICE_X11_FILE_PATH" | INSTALL_DIR_PATH=$INSTALL_DIR_PATH LAYOUT_NAME=$LAYOUT_NAME CONFIG_FILE_DIR_PATH="$CONFIG_FILE_DIR_PATH/" DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR XDG_SESSION_TYPE=$XDG_SESSION_TYPE DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS ERROR_LOG_FILE_PATH=$ERROR_LOG_FILE_PATH envsubst '$INSTALL_DIR_PATH $LAYOUT_NAME $CONFIG_FILE_DIR_PATH $DISPLAY $XAUTHORITY $XDG_RUNTIME_DIR $XDG_SESSION_TYPE $DBUS_SESSION_BUS_ADDRESS $ERROR_LOG_FILE_PATH' | sudo tee "$SERVICE_INSTALL_DIR_PATH/$SERVICE_INSTALL_FILE_NAME" >/dev/null
    else
        echo "Unfortunatelly you will not be able use feature: Disabling Touchpad (e.g. Fn+special key) disables DialPad aswell, at this moment is supported only X11"
        # DISPLAY=$DISPLAY for Xwayland
        cat "$SERVICE_WAYLAND_FILE_PATH" | INSTALL_DIR_PATH=$INSTALL_DIR_PATH LAYOUT_NAME=$LAYOUT_NAME CONFIG_FILE_DIR_PATH="$CONFIG_FILE_DIR_PATH/" DISPLAY=$DISPLAY WAYLAND_DISPLAY=$WAYLAND_DISPLAY XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR XDG_SESSION_TYPE=$XDG_SESSION_TYPE DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS ERROR_LOG_FILE_PATH=$ERROR_LOG_FILE_PATH envsubst '$INSTALL_DIR_PATH $LAYOUT_NAME $CONFIG_FILE_DIR_PATH $DISPLAY $WAYLAND_DISPLAY $XDG_RUNTIME_DIR $XDG_SESSION_TYPE $DBUS_SESSION_BUS_ADDRESS $ERROR_LOG_FILE_PATH' | sudo tee "$SERVICE_INSTALL_DIR_PATH/$SERVICE_INSTALL_FILE_NAME" >/dev/null
    fi

    if [[ $? != 0 ]]; then
        echo "Something went wrong when moving the asus_dialpad_driver.service"
        exit 1
    else
        echo "Asus DialPad Driver service placed"
    fi

    systemctl --user daemon-reload

    if [[ $? != 0 ]]; then
        echo "Something went wrong when was called systemctl daemon reload"
        exit 1
    else
        echo "Systemctl daemon reloaded"
    fi

    systemctl enable --user asus_dialpad_driver@$USER.service

    if [[ $? != 0 ]]; then
        echo "Something went wrong when enabling the asus_dialpad_driver.service"
        exit 1
    else
        echo "Asus DialPad driver service enabled"
    fi

    systemctl restart --user asus_dialpad_driver@$USER.service
    if [[ $? != 0 ]]; then
        echo "Something went wrong when starting the asus_dialpad_driver.service"
        exit 1
    else
        echo "Asus DialPad driver service started"
    fi
esac