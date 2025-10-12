local function formatRawHttp(method, url, headers, body)
    local host, path = "unknown", "/"
    
    if url:find("://") then
        local afterProtocol = url:split("://")[2]
        if afterProtocol then
            local parts = afterProtocol:split("/")
            host = parts[1]
            if #parts > 1 then
                path = "/" .. table.concat({table.unpack(parts, 2)}, "/")
            end
        end
    end
    
    local raw = string.format("%s %s HTTP/1.1\nHost: %s\n", method, path, host)
    
    if headers then
        for k, v in pairs(headers) do
            raw = raw .. k .. ": " .. tostring(v) .. "\n"
        end
    end
    
    if body then
        local bodyStr = tostring(body)
        if #bodyStr > 200000 then
            bodyStr = bodyStr:sub(1, 200000) .. "\n\n... [TRUNCATED]"
        end
        raw = raw .. "Content-Length: " .. #body .. "\n\n" .. bodyStr
    end
    
    return raw
end

local function formatResponse(response, responseHeaders, isTooLong)
    if isTooLong then
        return "-- Response too long (" .. #tostring(response) .. " characters)"
    end
    
    local responseStr = tostring(response)
    if responseStr:match("^HTTP/1%.1") and not (responseHeaders and next(responseHeaders)) then
        return responseStr
    end
    
    local raw = "HTTP/1.1 200 OK\n"
    if responseHeaders then
        for k, v in pairs(responseHeaders) do
            raw = raw .. k .. ": " .. tostring(v) .. "\n"
        end
    end
    
    if #responseStr > 200000 then
        responseStr = responseStr:sub(1, 200000) .. "\n\n... [TRUNCATED]"
    end
    
    return raw .. "\n" .. responseStr
end

local function create(class, props)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        if k == "Parent" then continue end
        obj[k] = v
    end
    obj.Parent = props.Parent
    return obj
end

local gui = create("ScreenGui", {Name = "HttpMonitor", Parent = game:GetService("CoreGui")})
local main = create("Frame", {Size = UDim2.new(0, 700, 0, 450), Position = UDim2.new(0.5, -350, 0.5, -225), 
    BackgroundColor3 = Color3.fromRGB(25, 25, 25), BorderSizePixel = 0, Parent = gui})

local header = create("Frame", {Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Color3.fromRGB(35, 35, 35), 
    BorderSizePixel = 0, Parent = main})
    
local title = create("TextLabel", {Size = UDim2.new(1, -200, 1, 0), Position = UDim2.new(0, 10, 0, 0),
    BackgroundTransparency = 1, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold,
    TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Text = "HTTP Monitor", Parent = header})

local interceptBtn = create("TextButton", {Size = UDim2.new(0, 80, 0, 22), Position = UDim2.new(1, -148, 0, 4),
    BackgroundColor3 = Color3.fromRGB(60, 60, 60), TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold,
    TextSize = 12, Text = "Intercept: OFF", BorderSizePixel = 0, Parent = header})

local clearBtn = create("TextButton", {Size = UDim2.new(0, 60, 0, 22), Position = UDim2.new(1, -64, 0, 4),
    BackgroundColor3 = Color3.fromRGB(60, 60, 60), TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold,
    TextSize = 12, Text = "Clear", BorderSizePixel = 0, Parent = header})

local listScroll = create("ScrollingFrame", {Size = UDim2.new(0, 200, 1, -40), Position = UDim2.new(0, 10, 0, 35),
    BackgroundColor3 = Color3.fromRGB(30, 30, 30), ScrollBarThickness = 6, BorderSizePixel = 0, Parent = main})

local tabContainer = create("Frame", {Size = UDim2.new(1, -230, 0, 30), Position = UDim2.new(0, 220, 0, 35),
    BackgroundColor3 = Color3.fromRGB(30, 30, 30), BorderSizePixel = 0, Parent = main})

local requestTab = create("TextButton", {Size = UDim2.new(0.5, -2, 1, 0), BackgroundColor3 = Color3.fromRGB(50, 50, 50),
    TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 12, Text = "Request",
    BorderSizePixel = 0, Parent = tabContainer})

local responseTab = create("TextButton", {Size = UDim2.new(0.5, -2, 1, 0), Position = UDim2.new(0.5, 2, 0, 0),
    BackgroundColor3 = Color3.fromRGB(40, 40, 40), TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold,
    TextSize = 12, Text = "Response", BorderSizePixel = 0, Parent = tabContainer})

local detailScroll = create("ScrollingFrame", {Size = UDim2.new(1, -230, 1, -110), Position = UDim2.new(0, 220, 0, 70),
    BackgroundColor3 = Color3.fromRGB(20, 20, 20), ScrollBarThickness = 6, BorderSizePixel = 0,
    CanvasSize = UDim2.new(2, 0, 2, 0), Parent = main})

local detailText = create("TextBox", {Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 5, 0, 0),
    BackgroundTransparency = 1, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.Code, TextSize = 12,
    MultiLine = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    Text = "Select a request to view details", ClearTextOnFocus = false, TextWrapped = false, 
    ClipsDescendants = false, Parent = detailScroll})

local actionBar = create("Frame", {Size = UDim2.new(1, -230, 0, 35), Position = UDim2.new(0, 220, 1, -40),
    BackgroundColor3 = Color3.fromRGB(30, 30, 30), BorderSizePixel = 0, Visible = false, Parent = main})

local forwardBtn = create("TextButton", {Size = UDim2.new(0, 100, 0, 26), Position = UDim2.new(0.5, 5, 0.5, -13),
    BackgroundColor3 = Color3.fromRGB(80, 150, 80), TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold,
    TextSize = 12, Text = "Forward", BorderSizePixel = 0, Parent = actionBar})

local dropBtn = create("TextButton", {Size = UDim2.new(0, 100, 0, 26), Position = UDim2.new(0.5, -105, 0.5, -13),
    BackgroundColor3 = Color3.fromRGB(150, 80, 80), TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold,
    TextSize = 12, Text = "Drop", BorderSizePixel = 0, Parent = actionBar})

local State = {
    requests = {},
    selectedRequest = nil,
    currentTab = "request",
    interceptEnabled = false,
    interceptQueue = {},
    currentIntercept = nil,
    interceptId = 0
}

local function updateDetailScroll()
    local lines = string.split(detailText.Text, "\n")
    local maxWidth = 0
    for _, line in ipairs(lines) do 
        maxWidth = math.max(maxWidth, #line) 
    end
    detailScroll.CanvasSize = UDim2.new(0, math.max(maxWidth * 7, detailScroll.AbsoluteSize.X), 0, #lines * 16)
end

local function updateListScroll()
    listScroll.CanvasSize = UDim2.new(0, 0, 0, #State.requests * 52)
end

local function updateDetailView()
    local source = State.selectedRequest and State.requests[State.selectedRequest:GetAttribute("Index")] or State.currentIntercept
    if source then
        detailText.Text = State.currentTab == "request" and source.requestRaw or (source.responseRaw or "No response data")
        detailText.TextEditable = State.currentIntercept and State.currentTab == "response" and not State.currentIntercept.isTooLong
        updateDetailScroll()
    else
        detailText.Text = "Select a request to view details"
        detailText.TextEditable = false
        updateDetailScroll()
    end
end

local function switchTab(tab)
    State.currentTab = tab
    requestTab.BackgroundColor3 = tab == "request" and Color3.fromRGB(50, 50, 50) or Color3.fromRGB(40, 40, 40)
    responseTab.BackgroundColor3 = tab == "response" and Color3.fromRGB(50, 50, 50) or Color3.fromRGB(40, 40, 40)
    updateDetailView()
end

local function createRequestButton(idx, req)
    local bgColor = req.status == "PENDING" and Color3.fromRGB(60, 60, 40) or Color3.fromRGB(40, 40, 40)
    local btn = create("TextButton", {Size = UDim2.new(1, -10, 0, 48), Position = UDim2.new(0, 5, 0, (idx - 1) * 52),
        BackgroundColor3 = bgColor, BorderSizePixel = 0, Text = "", Parent = listScroll})
    btn:SetAttribute("Index", idx)
    
    local statusText = req.status and req.status ~= "PENDING" and " [" .. req.status .. "]" or ""
    local displayUrl = #req.url > 45 and req.url:sub(1, 42) .. "..." or req.url
    
    create("TextLabel", {Size = UDim2.new(0, 50, 0, 20), Position = UDim2.new(0, 5, 0, 5),
        BackgroundTransparency = 1, TextColor3 = req.method == "GET" and Color3.fromRGB(100, 200, 255) or Color3.fromRGB(255, 200, 100),
        Font = Enum.Font.GothamBold, TextSize = 11, Text = req.method, TextXAlignment = Enum.TextXAlignment.Left, Parent = btn})
    
    create("TextLabel", {Size = UDim2.new(1, -60, 0, 38), Position = UDim2.new(0, 5, 0, 25),
        BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(200, 200, 200), Font = Enum.Font.Code, TextSize = 10,
        Text = displayUrl .. statusText, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true, ClipsDescendants = true, Parent = btn})
    
    btn.MouseButton1Click:Connect(function()
        if State.selectedRequest then
            local oldIdx = State.selectedRequest:GetAttribute("Index")
            if oldIdx and State.requests[oldIdx] then
                local oldStatus = State.requests[oldIdx].status
                State.selectedRequest.BackgroundColor3 = oldStatus == "PENDING" and Color3.fromRGB(60, 60, 40) or Color3.fromRGB(40, 40, 40)
            end
        end
        
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        State.selectedRequest = btn
        
        if req.interceptData and req.interceptData.sessionId == State.interceptId then
            State.currentIntercept = req.interceptData
            actionBar.Visible = true
        else
            State.currentIntercept = nil
            actionBar.Visible = false
        end
        
        updateDetailView()
    end)
    
    return btn
end

local function refreshRequestList()
    for _, child in ipairs(listScroll:GetChildren()) do
        if child:IsA("TextButton") then 
            child:Destroy() 
        end
    end
    
    for i, req in ipairs(State.requests) do
        createRequestButton(i, req)
    end
    
    updateListScroll()
end

local function addRequest(method, url, requestRaw, responseRaw, isTooLong, status, interceptData)
    table.insert(State.requests, 1, {
        method = method, 
        url = url, 
        requestRaw = requestRaw, 
        responseRaw = responseRaw, 
        isTooLong = isTooLong or false, 
        status = status, 
        interceptData = interceptData
    })
    
    refreshRequestList()
end

local function updateRequestStatus(interceptData, status)
    for i, req in ipairs(State.requests) do
        if req.interceptData == interceptData then
            State.requests[i].status = status
            State.requests[i].interceptData = nil
            refreshRequestList()
            break
        end
    end
end

local function clearIntercepts()
    for _, item in ipairs(State.interceptQueue) do
        if item.sessionId == State.interceptId then
            updateRequestStatus(item, "CANCELLED")
            if item.callback then 
                task.spawn(item.callback) 
            end
        end
    end
    State.interceptQueue = {}
    State.currentIntercept = nil
    actionBar.Visible = false
    detailText.TextEditable = false
end

local function processNextIntercept()
    while #State.interceptQueue > 0 do
        local nextItem = State.interceptQueue[1]
        if nextItem.sessionId == State.interceptId then
            State.currentIntercept = nextItem
            detailText.Text = State.currentIntercept.responseRaw
            detailText.TextEditable = not State.currentIntercept.isTooLong
            actionBar.Visible = true
            switchTab("response")
            updateDetailScroll()
            return
        else
            table.remove(State.interceptQueue, 1)
            updateRequestStatus(nextItem, "CANCELLED")
            if nextItem.callback then 
                task.spawn(nextItem.callback) 
            end
        end
    end
    
    State.currentIntercept = nil
    actionBar.Visible = false
    detailText.TextEditable = false
    updateDetailView()
end

requestTab.MouseButton1Click:Connect(function() 
    switchTab("request") 
end)

responseTab.MouseButton1Click:Connect(function() 
    switchTab("response") 
end)

clearBtn.MouseButton1Click:Connect(function()
    if #State.interceptQueue > 0 then
        clearIntercepts()
    end
    
    State.requests = {}
    State.selectedRequest = nil
    
    for _, child in ipairs(listScroll:GetChildren()) do
        if child:IsA("TextButton") then 
            child:Destroy() 
        end
    end
    
    detailText.Text = "Select a request to view details"
    updateListScroll()
    updateDetailScroll()
end)

interceptBtn.MouseButton1Click:Connect(function()
    State.interceptEnabled = not State.interceptEnabled
    interceptBtn.Text = State.interceptEnabled and "Intercept: ON" or "Intercept: OFF"
    interceptBtn.BackgroundColor3 = State.interceptEnabled and Color3.fromRGB(80, 150, 80) or Color3.fromRGB(60, 60, 60)
    
    if State.interceptEnabled then
        State.interceptId = State.interceptId + 1
    else
        clearIntercepts()
    end
end)

forwardBtn.MouseButton1Click:Connect(function()
    if not State.currentIntercept or State.currentIntercept.sessionId ~= State.interceptId then 
        return 
    end
    
    local wasModified = false
    if State.currentTab == "response" and not State.currentIntercept.isTooLong then
        local bodyStart = detailText.Text:find("\n\n")
        local newResponse = bodyStart and detailText.Text:sub(bodyStart + 2) or detailText.Text
        if newResponse ~= tostring(State.currentIntercept.originalResponse) then
            State.currentIntercept.modifiedResponse = newResponse
            wasModified = true
        end
    end
    
    updateRequestStatus(State.currentIntercept, wasModified and "MODIFIED" or nil)
    
    if State.currentIntercept.callback then 
        task.spawn(State.currentIntercept.callback) 
    end
    
    table.remove(State.interceptQueue, 1)
    processNextIntercept()
end)

dropBtn.MouseButton1Click:Connect(function()
    if not State.currentIntercept or State.currentIntercept.sessionId ~= State.interceptId then 
        return 
    end
    
    State.currentIntercept.dropped = true
    updateRequestStatus(State.currentIntercept, "DROPPED")
    
    if State.currentIntercept.callback then 
        task.spawn(State.currentIntercept.callback) 
    end
    
    table.remove(State.interceptQueue, 1)
    processNextIntercept()
end)

local function interceptResponse(method, url, requestRaw, response, responseHeaders, currentSessionId)
    if not State.interceptEnabled or currentSessionId ~= State.interceptId then
        local responseLength = #tostring(response)
        local isTooLong = responseLength > 200000
        local responseRaw = formatResponse(response, responseHeaders, isTooLong)
        addRequest(method, url, requestRaw, responseRaw, isTooLong, "CANCELLED")
        return nil
    end
    
    local responseLength = #tostring(response)
    local isTooLong = responseLength > 200000
    local responseRaw = formatResponse(response, responseHeaders, isTooLong)
    
    local interceptData = {
        method = method, 
        url = url, 
        requestRaw = requestRaw, 
        responseRaw = responseRaw,
        originalResponse = response, 
        modifiedResponse = nil, 
        dropped = false, 
        callback = nil, 
        isTooLong = isTooLong,
        sessionId = currentSessionId
    }
    
    addRequest(method, url, requestRaw, responseRaw, isTooLong, "PENDING", interceptData)
    table.insert(State.interceptQueue, interceptData)
    
    if #State.interceptQueue == 1 then
        State.currentIntercept = interceptData
        State.selectedRequest = nil
        actionBar.Visible = true
        switchTab("response")
    end
    
    local thread = coroutine.running()
    interceptData.callback = function() 
        coroutine.resume(thread) 
    end
    coroutine.yield()
    
    return interceptData
end

local UIS = game:GetService("UserInputService")
local dragging, dragStart, startPos

UIS.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.Home then
        main.Visible = not main.Visible
    end
end)

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then 
        dragging = false 
    end
end)

local HttpService = game:GetService("HttpService")

local HttpGet
HttpGet = hookfunction(game.HttpGet, function(self, url, ...)
    local requestRaw = formatRawHttp("GET", url, nil, nil)
    local currentSessionId = State.interceptId
    local shouldIntercept = State.interceptEnabled
    
    local response = HttpGet(self, url, ...)
    local responseLength = #tostring(response)
    local isTooLong = responseLength > 200000
    
    if shouldIntercept then
        local interceptData = interceptResponse("GET", url, requestRaw, response, nil, currentSessionId)
        
        if not interceptData then
            return response
        end
        
        if interceptData.dropped then
            return ""
        end
        
        if interceptData.modifiedResponse then
            response = interceptData.modifiedResponse
        end
    else
        local responseRaw = formatResponse(response, nil, isTooLong)
        addRequest("GET", url, requestRaw, responseRaw, isTooLong)
    end
    
    return response
end)

local HttpPost
HttpPost = hookfunction(game.HttpPost, function(self, url, data, ...)
    local requestRaw = formatRawHttp("POST", url, nil, data)
    local currentSessionId = State.interceptId
    local shouldIntercept = State.interceptEnabled
    
    local response = HttpPost(self, url, data, ...)
    local responseLength = #tostring(response)
    local isTooLong = responseLength > 200000
    
    if shouldIntercept then
        local interceptData = interceptResponse("POST", url, requestRaw, response, nil, currentSessionId)
        
        if not interceptData then
            return response
        end
        
        if interceptData.dropped then
            return ""
        end
        
        if interceptData.modifiedResponse then
            response = interceptData.modifiedResponse
        end
    else
        local responseRaw = formatResponse(response, nil, isTooLong)
        addRequest("POST", url, requestRaw, responseRaw, isTooLong)
    end
    
    return response
end)

local GetAsync
GetAsync = hookfunction(HttpService.GetAsync, function(self, url, ...)
    local requestRaw = formatRawHttp("GET", url, nil, nil)
    local currentSessionId = State.interceptId
    local shouldIntercept = State.interceptEnabled
    
    local response = GetAsync(self, url, ...)
    local responseLength = #tostring(response)
    local isTooLong = responseLength > 200000
    
    if shouldIntercept then
        local interceptData = interceptResponse("GET", url, requestRaw, response, nil, currentSessionId)
        
        if not interceptData then
            return response
        end
        
        if interceptData.dropped then
            return ""
        end
        
        if interceptData.modifiedResponse then
            response = interceptData.modifiedResponse
        end
    else
        local responseRaw = formatResponse(response, nil, isTooLong)
        addRequest("GET", url, requestRaw, responseRaw, isTooLong)
    end
    
    return response
end)

local PostAsync
PostAsync = hookfunction(HttpService.PostAsync, function(self, url, data, contentType, compress, headers, ...)
    local requestRaw = formatRawHttp("POST", url, headers, data)
    local currentSessionId = State.interceptId
    local shouldIntercept = State.interceptEnabled
    
    local response = PostAsync(self, url, data, contentType, compress, headers, ...)
    local responseLength = #tostring(response)
    local isTooLong = responseLength > 200000
    
    if shouldIntercept then
        local interceptData = interceptResponse("POST", url, requestRaw, response, nil, currentSessionId)
        
        if not interceptData then
            return response
        end
        
        if interceptData.dropped then
            return ""
        end
        
        if interceptData.modifiedResponse then
            response = interceptData.modifiedResponse
        end
    else
        local responseRaw = formatResponse(response, nil, isTooLong)
        addRequest("POST", url, requestRaw, responseRaw, isTooLong)
    end
    
    return response
end)

local RequestAsync
RequestAsync = hookfunction(HttpService.RequestAsync, function(self, options, ...)
    local requestRaw = formatRawHttp(options.Method or "GET", options.Url, options.Headers, options.Body)
    local currentSessionId = State.interceptId
    local shouldIntercept = State.interceptEnabled
    
    local response = RequestAsync(self, options, ...)
    
    local responseBody = response and response.Body or nil
    local responseHeaders = response and response.Headers or nil
    local responseLength = responseBody and #tostring(responseBody) or 0
    local isTooLong = responseLength > 200000
    
    if shouldIntercept and response then
        local interceptData = interceptResponse(options.Method or "GET", options.Url, requestRaw, response.Body, response.Headers, currentSessionId)
        
        if not interceptData then
            return response
        end
        
        if interceptData.dropped then
            return {Success = false, Body = "", StatusCode = 0, StatusMessage = "Dropped", Headers = {}}
        end
        
        if interceptData.modifiedResponse then
            response.Body = interceptData.modifiedResponse
        end
    else
        local responseRaw = formatResponse(responseBody, responseHeaders, isTooLong)
        addRequest(options.Method or "GET", options.Url, requestRaw, responseRaw, isTooLong)
    end
    
    return response
end)

local oldHttpCall; oldHttpCall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    if method == "HttpGet" then
        local args = {...}
        local url = args[1]
        local requestRaw = formatRawHttp("GET", url, nil, nil)
        local currentSessionId = State.interceptId
        local shouldIntercept = State.interceptEnabled
        
        local response = oldHttpCall(self, ...)
        local responseLength = #tostring(response)
        local isTooLong = responseLength > 200000
        
        if shouldIntercept then
            local interceptData = interceptResponse("GET", url, requestRaw, response, nil, currentSessionId)
            
            if not interceptData then
                return response
            end
            
            if interceptData.dropped then
                return ""
            end
            
            if interceptData.modifiedResponse then
                response = interceptData.modifiedResponse
            end
        else
            local responseRaw = formatResponse(response, nil, isTooLong)
            addRequest("GET", url, requestRaw, responseRaw, isTooLong)
        end
        
        return response
    elseif method == "HttpPost" then
        local args = {...}
        local url = args[1]
        local data = args[2]
        local requestRaw = formatRawHttp("POST", url, nil, data)
        local currentSessionId = State.interceptId
        local shouldIntercept = State.interceptEnabled
        
        local response = oldHttpCall(self, ...)
        local responseLength = #tostring(response)
        local isTooLong = responseLength > 200000
        
        if shouldIntercept then
            local interceptData = interceptResponse("POST", url, requestRaw, response, nil, currentSessionId)
            
            if not interceptData then
                return response
            end
            
            if interceptData.dropped then
                return ""
            end
            
            if interceptData.modifiedResponse then
                response = interceptData.modifiedResponse
            end
        else
            local responseRaw = formatResponse(response, nil, isTooLong)
            addRequest("POST", url, requestRaw, responseRaw, isTooLong)
        end
        
        return response
    end
    
    return oldHttpCall(self, ...)
end)

if syn and syn.request then
    local SynRequest
    SynRequest = hookfunction(syn.request, function(dat)
        local requestRaw = formatRawHttp(dat.Method or "GET", dat.Url, dat.Headers, dat.Body)
        local currentSessionId = State.interceptId
        local shouldIntercept = State.interceptEnabled
        
        local response = SynRequest(dat)
        
        local responseBody = response and response.Body or nil
        local responseHeaders = response and response.Headers or nil
        local responseLength = responseBody and #tostring(responseBody) or 0
        local isTooLong = responseLength > 200000
        
        if shouldIntercept and response then
            local interceptData = interceptResponse(dat.Method or "GET", dat.Url, requestRaw, response.Body, response.Headers, currentSessionId)
            
            if not interceptData then
                return response
            end
            
            if interceptData.dropped then
                return {Success = false, Body = "", StatusCode = 0, StatusMessage = "Dropped", Headers = {}}
            end
            
            if interceptData.modifiedResponse then
                response.Body = interceptData.modifiedResponse
            end
        else
            local responseRaw = formatResponse(responseBody, responseHeaders, isTooLong)
            addRequest(dat.Method or "GET", dat.Url, requestRaw, responseRaw, isTooLong)
        end
        
        return response
    end)
end

if http and http.request then
    local HttpRequest
    HttpRequest = hookfunction(http.request, function(dat)
        local requestRaw = formatRawHttp(dat.Method or "GET", dat.Url, dat.Headers, dat.Body)
        local currentSessionId = State.interceptId
        local shouldIntercept = State.interceptEnabled
        
        local response = HttpRequest(dat)
        
        local responseBody = response and response.Body or nil
        local responseHeaders = response and response.Headers or nil
        local responseLength = responseBody and #tostring(responseBody) or 0
        local isTooLong = responseLength > 200000
        
        if shouldIntercept and response then
            local interceptData = interceptResponse(dat.Method or "GET", dat.Url, requestRaw, response.Body, response.Headers, currentSessionId)
            
            if not interceptData then
                return response
            end
            
            if interceptData.dropped then
                return {Success = false, Body = "", StatusCode = 0, StatusMessage = "Dropped", Headers = {}}
            end
            
            if interceptData.modifiedResponse then
                response.Body = interceptData.modifiedResponse
            end
        else
            local responseRaw = formatResponse(responseBody, responseHeaders, isTooLong)
            addRequest(dat.Method or "GET", dat.Url, requestRaw, responseRaw, isTooLong)
        end
        
        return response
    end)
end

if http_request then
    local HttpRequestGlobal
    HttpRequestGlobal = hookfunction(http_request, function(dat)
        local requestRaw = formatRawHttp(dat.Method or "GET", dat.Url, dat.Headers, dat.Body)
        local currentSessionId = State.interceptId
        local shouldIntercept = State.interceptEnabled
        
        local response = HttpRequestGlobal(dat)
        
        local responseBody = response and response.Body or nil
        local responseHeaders = response and response.Headers or nil
        local responseLength = responseBody and #tostring(responseBody) or 0
        local isTooLong = responseLength > 200000
        
        if shouldIntercept and response then
            local interceptData = interceptResponse(dat.Method or "GET", dat.Url, requestRaw, response.Body, response.Headers, currentSessionId)
            
            if not interceptData then
                return response
            end
            
            if interceptData.dropped then
                return {Success = false, Body = "", StatusCode = 0, StatusMessage = "Dropped", Headers = {}}
            end
            
            if interceptData.modifiedResponse then
                response.Body = interceptData.modifiedResponse
            end
        else
            local responseRaw = formatResponse(responseBody, responseHeaders, isTooLong)
            addRequest(dat.Method or "GET", dat.Url, requestRaw, responseRaw, isTooLong)
        end
        
        return response
    end)
end

if request then
    local RequestGlobal
    RequestGlobal = hookfunction(request, function(dat)
        local requestRaw = formatRawHttp(dat.Method or "GET", dat.Url, dat.Headers, dat.Body)
        local currentSessionId = State.interceptId
        local shouldIntercept = State.interceptEnabled
        
        local response = RequestGlobal(dat)
        
        local responseBody = response and response.Body or nil
        local responseHeaders = response and response.Headers or nil
        local responseLength = responseBody and #tostring(responseBody) or 0
        local isTooLong = responseLength > 200000
        
        if shouldIntercept and response then
            local interceptData = interceptResponse(dat.Method or "GET", dat.Url, requestRaw, response.Body, response.Headers, currentSessionId)
            
            if not interceptData then
                return response
            end
            
            if interceptData.dropped then
                return {Success = false, Body = "", StatusCode = 0, StatusMessage = "Dropped", Headers = {}}
            end
            
            if interceptData.modifiedResponse then
                response.Body = interceptData.modifiedResponse
            end
        else
            local responseRaw = formatResponse(responseBody, responseHeaders, isTooLong)
            addRequest(dat.Method or "GET", dat.Url, requestRaw, responseRaw, isTooLong)
        end
        
        return response
    end)
end

print("HTTP Monitor active")
