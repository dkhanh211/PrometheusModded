# 🔄 What’s Changed?

- Replaced Base64 algorithm with Base95 encoding
- Added a new obfuscation step: **Control Flow**
- Converted dec values to hex format

---

# How to Improved Security (Environment Logger Protection)

Added a basic environment integrity check to prevent execution in suspicious environments.
You can use popular Compress Alogorimth if output is so big
```lua
if string.dump
   or io
   or not game
   or not getgenv
   or not task
   or not wait
   or not game.GetService
   or game:GetService("HttpService") ~= game.HttpService then
    return
end
```
# Test (output.lua)
 - [Modded - output.lua](https://github.com/dkhanh211/PrometheusModded/blob/main/output.lua)
 - [Original - output.raw.lua](https://github.com/dkhanh211/PrometheusModded/blob/main/output.raw.lua)
 - [Raw](https://github.com/dkhanh211/PrometheusModded/blob/main/raw_input.lua)
---
# Enjoy XD
