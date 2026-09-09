BAO = BAO or {}

BAO.Version = "0.1.0"

function BAO.Log(message)
    print("[BAO] " .. tostring(message))
end

BAO.Log("Bootstrap loaded")