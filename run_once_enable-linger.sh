#!/bin/bash
# Keyring unlock at login depends on the user manager running BEFORE GDM
# authentication: sockets.target.wants/gnome-keyring-daemon.socket must be
# listening so pam_gnome_keyring can hand the login password to the
# socket-activated daemon. Linger is what guarantees that ordering, so it is
# a hard prerequisite of the keyring setup, managed here instead of by hand.
loginctl enable-linger "$USER" 2>/dev/null || true
