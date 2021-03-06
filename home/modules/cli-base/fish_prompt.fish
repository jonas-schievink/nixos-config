# A minimal Fish prompt based on the gitstatus prompt.
# Original gitstatus prompt from https://github.com/godfat/fish_prompt-gitstatus
# Adopted by OMF at https://github.com/oh-my-fish/theme-gitstatus

function _git_branch_name
  echo (command git symbolic-ref HEAD 2> /dev/null | sed -e 's|^refs/heads/||')
end

function _git_status_symbol
  set -l git_status (git status --porcelain 2> /dev/null)
  if test -n "$git_status"
    echo '*' # dirty
  else
    echo ''  # clean
  end
end

function _remote_hostname
  if test -n "$SSH_CONNECTION"
    echo (whoami)@(hostname)
  end
end

function fish_prompt
  set -l cyan (set_color cyan)
  set -l normal (set_color normal)

  set -l cwd (set_color $fish_color_cwd)(prompt_pwd)
  set -l git_status (_git_status_symbol)(_git_branch_name)

  if test -n "$git_status"
    set git_status " $git_status"
  end

  echo -n (_remote_hostname) $cwd$cyan$git_status$normal'> '
end
