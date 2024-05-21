if status is-interactive
    # Commands to run in interactive sessions can go here
end

if status is-interactive
	if type -q atuin
		atuin init fish | source
	end
end

set -U fish_user_paths $HOME/.local/bin $fish_user_paths
set -U fish_user_paths $HOME/.cargo/bin $fish_user_paths

