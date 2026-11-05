{$bg[${sb[i]}]%}%{$fg[$prev]%}${SEP}"
    out+="%{$bg[${sb[i]}]%}%{$fg[${sf[i]}]%} ${st[i]//\%/%%} "
    prev=${sb[i]}
  done
  out+="%{$reset_color%}%{$fg[$prev]%}${SEP}%{$reset_color%}"
  _NZR_ERRLINE="${out}"$'\n'
}
