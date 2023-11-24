#!/bin/bash

if [ -z "$TMUX"  ]; then
        tmux attach -t XPS-tmux-session || exec tmux new -t XPS-tmux-session
    else
        echo "already in tmux!"
fi
