#!/bin/zsh
# ╔══════════════════════════════════════════════════════════════════╗
# ║            NZR THEME — lib/privacy.sh                            ║
# ║   Penyaring rahasia untuk log autosuggestions dan HISTFILE       ║
# ╚══════════════════════════════════════════════════════════════════╝
# Dipakai oleh:
#   _nzr_log_cmd        (nzr.zsh)  → log saran autosuggestions
#   _nzr_zshaddhistory  (di bawah) → HISTFILE bila HIST_SCRUB=ON
# Diuji otomatis oleh tests/run.zsh (bagian "Keamanan").

# Perintah yang mengandung pola ini tidak dicatat ke log (huruf kecil semua)
_NZR_SENSITIVE_RE='(pass|secret|token|key|auth|login|sudo|ssh|gpg|openssl|curl.*-u|wget.*--password|bearer|cookie|credential|ghp_|github_pat_|xox[baprs]-|akia[0-9a-z]{16}|sk-[a-z0-9_-]{20,}|://[^/ ]+:[^@ ]+@)'
# Pola lebih sempit untuk HISTFILE (sudo/ssh/key tetap boleh masuk history)
_NZR_HIST_RE='(secret|token|passw|bearer|credential|api[_-]?key|--password|ghp_|github_pat_|xox[baprs]-|akia[0-9a-z]{16}|sk-[a-z0-9_-]{20,}|://[^/ ]+:[^@ ]+@)'

# Perintah berisi rahasia tidak ditulis ke HISTFILE (masih ada di sesi ini
# lewat panah atas). Return 2 = simpan di memori saja, jangan ke file.
_nzr_zshaddhistory() {
  [[ "$HIST_SCRUB" == "ON" ]] || return 0
  [[ "${(L)1}" =~ $_NZR_HIST_RE ]] && return 2
  return 0
}

# Pindahkan log lama (di dalam folder repo) ke lokasi baru yang privat.
# Hanya jika file lama ada DAN file baru belum ada; tidak pernah menimpa.
_nzr_migrate_log() {   # <lama> <baru>
  local old="$1" new="$2"
  [[ -f "$old" && ! -e "$new" ]] || return 0
  ( umask 077; mv "$old" "$new" ) 2>/dev/null || return 0
  chmod 600 "$new" 2>/dev/null
  return 0
}
