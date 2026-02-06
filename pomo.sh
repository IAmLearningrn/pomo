#!/usr/bin/env bash
set -euo pipefail

DEBUG=false

if $DEBUG;then
  set -x
fi

WORK=25
BREAK=5
ROUNDS=4 #default
SOUND=false
SOUND_PATH="" # instead of having another var , empty SOUND_PATH means default bell sound... is that good?!
NOTIF=false
NOTIF_TITLE="POMO Timer"
MODE=WORK #default
LONG_BREAK=15
LONG_EVERY=4
TIMER_S=false

print_help(){
cat <<'EOF'
USAGE: pomo.sh [OPTIONS]

  -w, --work MIN          	Work minutes (default 25)
  -b, --break MIN         	Short break minutes (default 5)
  -L, --long-break MIN    	Long break minutes (default 15)
  -l, --long-every N      	Long break every N rounds (default 4)
  -r, --rounds N, --round N     Total rounds (default 4)

  -s, --sound             	Enable sound at transitions
      --sound-source FILE 	Use this audio file (.mp3/.wav/.ogg/.m4a)
  -n, --notify	        	Desktop notifications (notify-send)
  -q, --silent  	        No sound, no notifications

  -t, --timer MIN         	One-shot timer (no rounds , Only -w , -b , -s , -n work with this flag)
  -h, --help             	Show this help

Examples:
  pomo.sh -w 30 -b 5 -r 6 -n -s
  pomo.sh --timer 10 -n
  pomo.sh -w 50 -b 10 -L 20 -l 3 --sound --sound-source ~/ding.mp3
EOF
}

#--helpers--
have(){
  command -v "$1" >/dev/null 2>&1
}
is_posint(){ [[ $1 =~ ^[1-9][0-9]*$ ]]; }
is_nonneg(){ [[ $1 =~ ^[0-9]+$ ]]; }
can_notify() { $NOTIF && have notify-send; }

fmt_hms() { #sec_tr
  local s=$1
  local h=$(( s/3600 ))
  local m=$(( (s%3600)/60 ))
  local sec=$(( s%60 ))
  printf '%02d:%02d:%02d' "$h" "$m" "$sec"
}

timer() {
  local mins=${1:?need minutes}
  local secs=$(( mins * 60 ))
  tput civis 2>/dev/null || true
  trap 'tput cnorm 2>/dev/null || true; echo; echo "Aborted.";  printf "\n"; exit' INT TERM
  trap 'tput cnorm 2>/dev/null' EXIT

  while (( secs > 0 )); do
    printf "%s\r" "--$MODE--> $(fmt_hms "$secs")"
    sleep 1
    ((secs--))
  done

  tput cnorm 2>/dev/null || true
}

play_sound(){
  if have mpg123; then
    mpg123 -q "$SOUND_PATH" 2>/dev/null || printf '\a'
  elif have aplay; then
    aplay -q "$SOUND_PATH" 2>/dev/null || printf '\a'
  else
    printf '\a'
  fi
}

notifier(){
  local round="$1"
  if $SOUND;then
    if [[ -n $SOUND_PATH ]];then
      play_sound
    else
      printf '\a'
    fi
  fi
  if can_notify;then
    notify-send "$NOTIF_TITLE" "ROUND: $round -- $MODE time!"
  else
    echo "ROUND: $round -- $MODE time!"
  fi
}

while (($#)); do
  case "$1" in
    -w|--work) WORK=${2:? need time(min)}; shift 2;;
    -b|--break) BREAK=${2:? need time(min)}; shift 2;;
    -r|--round) ROUNDS=${2:? need rounds}; shift 2;;
    -h|--help) print_help ; exit 0 ;;
    --sound-source) SOUND_PATH=${2:? need a path for notif sound}; shift 2 ;;
    -s|--sound) SOUND=true ; shift ;;
    --no-sound) SOUND=false ; shift ;;
    -n|--notify) NOTIF=true ; shift ;;
    --no-notify) NOTIF=false ; shift ;;
    -q|--silent) NOTIF=false ; SOUND=false ; shift ;;
    -t|-T|--timer) TIMER_ONCE=${2:? Need a positive integer for timer} ; TIMER_S=true ; shift 2 ;;
    -l|--long-every) LONG_EVERY=${2:? Need positive integer} ; shift 2 ;;
    -L|--long-break) LONG_BREAK=${2:? Need minutes} ; shift 2 ;;
    *) echo "Unknown arg">&2 ; print_help ; exit 1 ;;
  esac
done

#--sanitize--
case "${MODE,,}" in
  work|w) MODE=WORK ;;
  break|b) MODE=BREAK ;;
  *) echo "MODE must be work,W,w or break,B,b">&2; exit 1 ;;
esac
is_posint "$WORK"        || { echo "WORK must be >0" >&2; exit 2; }
is_posint "$BREAK"       || { echo "BREAK must be >0" >&2; exit 2; }
is_posint "$ROUNDS"      || { echo "ROUNDS must be >0" >&2; exit 2; }
is_posint "$LONG_BREAK"  || { echo "LONG_BREAK must be >0" >&2; exit 2; }
is_posint "$LONG_EVERY"  || { echo "LONG_EVERY must be >0" >&2; exit 2; }
if $TIMER_S;then
  is_posint "$TIMER_ONCE" || { echo "Timer must be >0" >&2; exit 2; }
fi

if $TIMER_S;then
  if [[ "$TIMER_ONCE" =~ ^[0-9]+$ ]];then
    timer "$TIMER_ONCE"
    can_notify && notify-send "$NOTIF_TITLE" "TIMER DONE" || echo "TIMER DONE"
    play_sound #$SOUND && mpg123 -q "$SOUND_PATH" 2>/dev/null || printf '\a'
    exit 0
  else
    echo "Timer should be a positive integer">&2;exit 1
  fi
fi

sound_check() {
  [[ -z $SOUND_PATH ]] && return

  if [[ ! -f $SOUND_PATH ]]; then
    echo "WARNING: SOUND_SOURCE is not a file. Using terminal bell." >&2
    SOUND_PATH=""; return
  fi

  case "$SOUND_PATH" in
    *.mp3|*.wav|*.ogg|*.m4a) ;;
    *) echo "WARNING: Unsupported sound type. Using terminal bell." >&2
       SOUND_PATH=""; return ;;
  esac

  if ! have mpg123 && ! have aplay; then
    echo "WARNING: mpg123 and aplay not found. Using terminal bell." >&2
    SOUND_PATH=""; return
  fi
}
sound_check

main(){
  echo "POMO started W:${WORK}m / B:${BREAK}m / LB:${LONG_BREAK}m every ${LONG_EVERY} rounds / R:${ROUNDS}"
  for ((i=1;i<=ROUNDS;i++)); do
    MODE=WORK
    notifier "$i"
    timer "$WORK"

    (( i == ROUNDS )) && break

    if (( i % LONG_EVERY == 0 )); then
      MODE=LONG_BREAK
      notifier "$i"
      timer "$LONG_BREAK"
    else
      MODE=BREAK
      notifier "$i"
      timer "$BREAK"
    fi
  done
  can_notify && notify-send "$NOTIF_TITLE" "DONE" || echo "DONE"
  $SOUND && { [[ -n $SOUND_PATH ]] && play_sound || printf '\a'; }
}
main
