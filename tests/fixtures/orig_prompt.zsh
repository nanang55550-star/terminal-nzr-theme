#!/bin/zsh
# FIXTURE — salinan persis fungsi prompt NZR v2.0 (sebelum mesin async).
# Dipakai tests/run.zsh untuk membuktikan tampilan tiga baris TIDAK berubah.
# Jangan diedit.

# ─── STATUS BAR ───────────────────────────────────────────────────
_orig_status() {
  local ram disk
  ram=$(free -m 2>/dev/null | awk 'NR==2{printf "%dM/%dM",$3,$2}')
  [[ -z "$ram" ]] && ram="N/A"
  disk=$(df -h "${PWD:-$HOME}" 2>/dev/null | awk 'NR==2{printf "%s/%s",$3,$2}')
  [[ -z "$disk" ]] && disk="N/A"
  echo -n "%{$bg[cyan]%}%{$fg[white]%} %n@%m "
  echo -n "%{$bg[yellow]%}%{$fg[cyan]%}${SEP}%{$fg[black]%} RAM: ${ram} "
  echo -n "%{$bg[magenta]%}%{$fg[yellow]%}${SEP}%{$fg[white]%} DISK: ${disk} "
  echo -n "%{$reset_color%}%{$fg[magenta]%}${SEP}%{$reset_color%}"
}

# ─── DIR + GIT ────────────────────────────────────────────────────
_orig_dir_git() {
  local branch dirty changed
  branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  if [[ -n "$branch" ]]; then
    dirty=$(git status --porcelain 2>/dev/null)
    changed=$(printf '%s' "$dirty" | grep -c . 2>/dev/null || echo 0)
    if [[ -n "$dirty" ]]; then
      echo -n "%{$bg[blue]%}%{$fg[white]%} %~ "
      echo -n "%{$bg[red]%}%{$fg[blue]%}${SEP}%{$fg[white]%}  ${branch} ✗${changed} "
      echo -n "%{$reset_color%}%{$fg[red]%}${SEP}%{$reset_color%}"
    else
      echo -n "%{$bg[blue]%}%{$fg[white]%} %~ "
      echo -n "%{$bg[green]%}%{$fg[blue]%}${SEP}%{$fg[white]%}  ${branch} ✓ "
      echo -n "%{$reset_color%}%{$fg[green]%}${SEP}%{$reset_color%}"
    fi
  else
    echo -n "%{$bg[blue]%}%{$fg[white]%} %~ "
    echo -n "%{$reset_color%}%{$fg[blue]%}${SEP}%{$reset_color%}"
  fi
}

