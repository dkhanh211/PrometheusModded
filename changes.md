# 🔄 What’s Changed?

- Replaced Base64 algorithm with Base95 encoding
- Added a new obfuscation step: **Control Flow**
- Converted dec values to hex format

---

# How to Improved Security (Environment Logger Protection)

Added a basic environment integrity check to prevent execution in suspicious environments.

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
