# ⏱️ pomo.sh — A Minimalist Pomodoro & Timer CLI in Bash

A flexible and dependency-light Pomodoro timer written in pure Bash — customizable, notification-enabled, and perfect for developers and terminal lovers.


---

🚀 Features

🍅 Pomodoro timer with customizable work/break/long break durations

🔁 Configurable number of rounds and long break intervals

🔔 Optional sound and desktop notifications

⏲️ One-shot timer mode (--timer)

🔇 Silent mode for minimalists

💻 Works entirely offline — just Bash



---

# 📦 Installation
```
git clone https://github.com/yourusername/pomo.sh.git
cd pomo.sh
chmod +x pomo.sh
```
To make it globally available:
```
sudo cp pomo.sh /usr/local/bin/pomo
```

---

# 🧪 Usage

Basic Pomodoro
```
./pomo.sh -w 25 -b 5 -r 4
```
One-shot Timer
```
./pomo.sh --timer 10
```
With Notifications & Sound
```
./pomo.sh -w 50 -b 10 -L 20 -l 3 --notify --sound
```

---

# ⚙️ Options

Flag	Description

- -w, --work	Work session duration (minutes) – default: 25
- -b, --break	Short break duration (minutes) – default: 5
- -L, --long-break	Long break duration – default: 15
- -l, --long-every	Long break every N rounds – default: 4
- -r, --rounds	Total Pomodoro rounds – default: 4
- -s, --sound	Enable sound (uses terminal bell or custom file)
- --sound-source FILE	Use a custom audio file (.mp3, .wav, etc.)
- -n, --notify	Show desktop notifications (notify-send)
- -q, --silent	Disable sound and notifications
- -t, --timer	Run a one-shot countdown (ignores rounds)
- -h, --help	Show help message



---

# 🔔 Sound Support

To use sound, you need:

`mpg123` or `aplay` installed

Or rely on terminal bell (\a) as fallback


Example:
```
./pomo.sh -w 25 -b 5 -r 4 --sound --sound-source ~/ding.mp3
```

---

# 📢 Notifications

Requires:

notify-send (from libnotify-bin on most systems)


Example:
```
./pomo.sh --timer 10 --notify
```

---

# 🧘‍♂️ Why Use This?

No distractions — no GUI

Fully offline

Works anywhere Bash runs

Fits perfectly in your productivity toolchain or dotfiles



---

# 📄 License

MIT License © Amirhossein Hosseingholi
