import os

# ui
config.source(os.environ["HOME"] + "/.config/qutebrowser/gruvbox.py")

# Use a different color for work container to give visual distinction
if "QUTE_CONTAINER" not in os.environ or os.environ["QUTE_CONTAINER"] == "facebook":
    c.colors.tabs.selected.even.bg = "#B48EAD"
elif os.environ["QUTE_CONTAINER"] == "personal":
    c.colors.tabs.selected.even.bg = "#504955"
    c.colors.tabs.selected.even.fg = "#d79921"
elif os.environ["QUTE_CONTAINER"] == "work":
    c.colors.tabs.selected.even.bg = "#076678"
    c.colors.tabs.selected.even.fg = "#ebdbb2"
elif os.environ["QUTE_CONTAINER"] == "private":
    c.colors.tabs.selected.even.bg = "#282828"
    c.colors.tabs.selected.even.fg = "#cc241d"

c.colors.tabs.selected.odd.bg = c.colors.tabs.selected.even.bg

c.colors.webpage.prefers_color_scheme_dark = True
c.completion.shrink = True
c.completion.use_best_match = True
c.statusbar.widgets = ["progress", "keypress", "url", "history"]
c.scrolling.bar = "always"
c.tabs.position = "left"
c.tabs.width = "15%"
c.tabs.title.format = "{index}: {audio}{current_title}"
c.tabs.title.format_pinned = "{index}: {audio}{current_title}"

# general
c.auto_save.session = True
c.content.default_encoding = "utf-8"
c.content.javascript.can_access_clipboard = True
c.content.notifications = True  # notifications aren't supported now anyway
c.content.pdfjs = True
c.editor.command = ["kitty", "kak", "-e", "exec {line}g{column0}l", "{file}"]
c.downloads.location.prompt = False
c.input.insert_mode.auto_load = True
c.spellcheck.languages = ["en-US", "de-DE"]
c.tabs.background = True
c.tabs.last_close = "close"
c.tabs.mousewheel_switching = False
c.qt.args += ["enable-gpu-rasterization", "enable-features=WebRTCPipeWireCapturer"]

# per-domain settings
config.set("content.register_protocol_handler", True, "*://calendar.google.com")
config.set("content.register_protocol_handler", True, "*://teams.microsoft.com")
config.set("content.register_protocol_handler", True, "*://app.slack.com")
config.set("content.media_capture", True, "*://app.wire.com")
config.set("content.media_capture", True, "*://teams.microsoft.com")
config.set("content.media_capture", True, "*://app.slack.com")

# privacy
c.content.cookies.accept = "no-3rdparty"
c.content.webrtc_ip_handling_policy = "default-public-interface-only"
c.content.site_specific_quirks = False
c.content.headers.user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.121 Safari/537.36"

# urls
c.url.searchengines = {
    "DEFAULT": "https://google.com/search?q={}",
    "?": "https://google.com/search?q={}",
}
c.url.default_page = "~/.config/qutebrowser/blank.html"
c.url.start_pages = ["~/.config/qutebrowser/blank.html"]

# keys
bindings = {
    ",m": "spawn --userscript view_in_mpv",
    ",M": "hint links spawn mpv {hint-url}",
    ",p": "spawn --userscript qute-pass --username-target secret --username-pattern 'user: (.+)' --dmenu-invocation 'dmenu -p credentials'",
    ",P": "spawn --userscript qute-pass --username-target secret --username-pattern 'user: (.+)' --dmenu-invocation 'dmenu -p password' --password-only",
    ",b": "config-cycle colors.webpage.bg '#32302f' 'white'",
    "<Ctrl-Shift-J>": "tab-move +",
    "<Ctrl-Shift-K>": "tab-move -",
    "M": "nop",
    "co": "nop",
}

for key, bind in bindings.items():
    config.bind(key, bind)
