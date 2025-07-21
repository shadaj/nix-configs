function fish_greeting
  echo -n "Greetings from "
  echo -n (set_color green)
  echo -n (hostname)
  echo -n (set_color normal)
  echo -n "! The time is "
  echo -n (set_color yellow)
  echo -n (date +%T)
  echo -n (set_color normal)
  echo "."
end

function fish_print_sl_root # almost the same as hg
    # If hg isn't installed, there's nothing we can do
    if not command -sq sl
        return 1
    end

    # Find an hg directory above $PWD
    # without calling `hg root` because that's too slow
    set -l root
    set -l dir (pwd -P 2>/dev/null)
    or return 1

    while test $dir != /
        if test -f $dir'/.sl/dirstate'
            echo $dir/.sl
            return 0
        end
        if test -f $dir'/.git/sl/config'
            echo $dir/.git/sl
            return 0
        end
        # Go up one directory
        set dir (string replace -r '[^/]*/?$' '' $dir)
    end

    return 1
end

function __fish_sl_prompt --description 'Write out the hg prompt'
    # If hg isn't installed, there's nothing we can do
    # Return 1 so the calling prompt can deal with it
    if not command -sq sl
        return 1
    end

    set -l root (fish_print_sl_root)
    or return 1

    # Read branch and bookmark
    set -l branch (cat $root/branch 2>/dev/null; or echo default)
    if set -l bookmark (cat $root/bookmarks.current 2>/dev/null)
        set branch "$branch|$bookmark"
    end

    set_color normal
    echo -n " ("
    set_color $__fish_git_prompt_color_branch
    echo -n "$branch"
    set_color normal

    if not set -q fish_prompt_hg_show_informative_status
        echo -n ")"
        return
    end

    echo -n "|"

    # Disabling color and pager is always a good idea.
    set -l repo_status (sl status | string sub -l 2 | sort -u)

    # Show nice color for a clean repo
    if test -z "$repo_status"
        set_color $fish_color_hg_clean
        echo -n "✔"
        set_color normal
    else # Handle modified or dirty (unknown state)
        set -l hg_statuses

        # Take actions for the statuses of the files in the repo
        for line in $repo_status

            # Add a character for each file status if we have one
            # HACK: To allow this to work both with and without '?' globs
            set -l dq '?'
            switch $line
                case 'A '
                    set -a hg_statuses added
                case 'M ' ' M'
                    set -a hg_statuses modified
                case 'C '
                    set -a hg_statuses copied
                case 'D ' ' D'
                    set -a hg_statuses deleted
                case "$dq "
                    set -a hg_statuses untracked
                case 'U*' '*U' DD AA
                    set -a hg_statuses unmerged
            end
        end

        if string match -qr '^[AMCD]' $repo_status
            set_color $fish_color_hg_modified
        else
            set_color $fish_color_hg_dirty
        end

        # Sort status symbols
        for i in $fish_prompt_hg_status_order
            if contains -- $i $hg_statuses
                set -l color_name fish_color_hg_$i
                set -l status_name fish_prompt_hg_status_$i

                set_color $$color_name
                echo -n $$status_name
            end
        end
    end

    set_color normal

    echo -n ')'
end

function __fish_vcs_prompt --description "Print the prompts for all available vcsen"
__fish_hg_prompt # sets global variables we reuse
  # first try sl
  if __fish_sl_prompt
    return 0
  end
  __fish_git_prompt
  __fish_svn_prompt
end

if not set -q PROMPT_COMMAND
function fish_prompt --description 'Write out the prompt'
  if not set -q __fish_git_prompt_show_informative_status
    set -g __fish_git_prompt_show_informative_status 1
  end
  if not set -q __fish_git_prompt_hide_untrackedfiles
    set -g __fish_git_prompt_hide_untrackedfiles 1
  end

  if not set -q __fish_git_prompt_color_branch
    set -g __fish_git_prompt_color_branch magenta --bold
  end
  if not set -q __fish_git_prompt_showupstream
    set -g __fish_git_prompt_showupstream "informative"
  end
  if not set -q __fish_git_prompt_char_upstream_ahead
    set -g __fish_git_prompt_char_upstream_ahead "↑"
  end
  if not set -q __fish_git_prompt_char_upstream_behind
    set -g __fish_git_prompt_char_upstream_behind "↓"
  end
  if not set -q __fish_git_prompt_char_upstream_prefix
    set -g __fish_git_prompt_char_upstream_prefix ""
  end

  if not set -q __fish_git_prompt_char_stagedstate
    set -g __fish_git_prompt_char_stagedstate "●"
  end
  if not set -q __fish_git_prompt_char_dirtystate
    set -g __fish_git_prompt_char_dirtystate "✚"
  end
  if not set -q __fish_git_prompt_char_untrackedfiles
    set -g __fish_git_prompt_char_untrackedfiles "…"
  end
  if not set -q __fish_git_prompt_char_conflictedstate
    set -g __fish_git_prompt_char_conflictedstate "✖"
  end
  if not set -q __fish_git_prompt_char_cleanstate
    set -g __fish_git_prompt_char_cleanstate "✔"
  end

  if not set -q __fish_git_prompt_color_dirtystate
    set -g __fish_git_prompt_color_dirtystate blue
  end
  if not set -q __fish_git_prompt_color_stagedstate
    set -g __fish_git_prompt_color_stagedstate yellow
  end
  if not set -q __fish_git_prompt_color_invalidstate
    set -g __fish_git_prompt_color_invalidstate red
  end
  if not set -q __fish_git_prompt_color_untrackedfiles
    set -g __fish_git_prompt_color_untrackedfiles $fish_color_normal
  end
  if not set -q __fish_git_prompt_color_cleanstate
    set -g __fish_git_prompt_color_cleanstate green --bold
  end

  if not set -q fish_prompt_hg_show_informative_status
    set -g fish_prompt_hg_show_informative_status 1
  end
  if not set -q fish_color_hg_clean
    set -g fish_color_hg_clean green --bold
  end

  set -l last_status $status

  if not set -q __fish_prompt_normal
      set -g __fish_prompt_normal (set_color normal)
  end

  set -l color_cwd
  set -l prefix
  set -l suffix
  switch $USER
    case root toor
      if set -q fish_color_cwd_root
        set color_cwd $fish_color_cwd_root
      else
        set color_cwd $fish_color_cwd
      end
      set suffix '#'
    case '*'
      set color_cwd $fish_color_cwd
      set suffix '$'
  end

  # PWD
  set_color $color_cwd
  echo -n (prompt_pwd)
  set_color normal

  printf '%s ' (__fish_vcs_prompt)

  if not test $last_status -eq 0
    set_color $fish_color_error
  end

  echo -n "$suffix "

  set_color normal
end
end
