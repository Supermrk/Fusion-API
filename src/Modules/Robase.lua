--[[
RBLX-Firebase; A wrapper designed for Firebase's Realtime Database RESTful API services.

RBLX-Firebase was made to emulate the native DataStoreService such that all methods, bar Update methods, are alike.
As stated, Update methods are different, and this difference is the added #snapshot# argument to their methods.
The #snapshot# argument is optional and does not need to be supplied, however, when supplied, will prevent the module
from re-downloading from your database and will instead use the data supplied.

All methods have appropriate source-docs and will also be documented on the Github:

]]

local HttpService = game:GetService("HttpService")

--	RobloxFirebase module
--	@module

local RobloxFirebase = { }
RobloxFirebase.DefaultScope = ""
RobloxFirebase.AuthenticationToken = ""
RobloxFirebase.__index = RobloxFirebase

--[[ GetFirebase
@tparam <string> <name> The name of the firebase being fetched
@tparam[opt=RobloxFirebase.DefaultScope] <string> <scope> The scope being accessed, optional if DefaultScope is set

Will setup a Firebase object for use, this method is similar to DataStoreService:GetDataStore(name, scope)
If called with name="" it will simply create a Firebase at the entry to the Real-time Database, allowing you to access top-level data points
for example, if you had multiple containers within the top-level of the database and wanted to act upon them and not their descendants this would
be the way to do it.
    Database:[
    PlayerInformation:[
    Player1:[
    Data: true
    ]
    ],
    ServerInformation:[
    Data: true
    ]
    ]
    Running RobloxFirebase:GetFirebase("") would give you a Firebase object located at/from 'Database' in this example.

    @treturn <Firebase> <Firebase> A firebase object
    ]]
    function RobloxFirebase:GetFirebase(name, scope)
        assert(self.AuthenticationToken~=nil, "AuthenticationToken expected, got nil")
        assert(scope~=nil or self.DefaultScope~=nil, "DefaultScope or Scope expected, got nil")

        scope = scope or self.DefaultScope
        local path = scope .. HttpService:UrlEncode(name)
        local auth = ".json?auth=" .. self.AuthenticationToken

        -- Firebase object
        -- @Object=Firebase
        local Firebase = { }

        --[[ GetAsync
        @tparam <string> <key> The data point / key being accessed and retrieved

        This method is used to fetch data from your database using a key, this method is similar to DataStoreService:GetAsync(key)
        Will return nil upon error or no data found.

        This method will be attempted 3 times before failing.

        @treturn <Dictionary | null> <Response.Body> The data retrieved from the GET request
        ]]
        function Firebase:GetAsync(key)
            assert(type(key) == "string", "Roblox-Firebase GetAsync: Bad Argument #1, string expected got '"..tostring(type(key)).."'")
            key = key:sub(1,1)~="/" and "/"..key or key --> Ensures key is correct form
            local dir = path .. HttpService:UrlEncode(key) .. auth

            local request = { }
            request.Url = dir
            request.Method = "GET"

            local attempts = 0
            local responseInfo

            repeat
                attempts += 1
                local success, error = pcall(function()
                    responseInfo = HttpService:RequestAsync(request)
                end)
                if not success then
                    print("Roblox-Firebase GetAsync failed: " .. tostring(error))
                    wait(3)
                end
            until attempts>=3 or (responseInfo~=nil and responseInfo.Success~=false)

            if responseInfo == nil then
                print("Roblox-Firebase GetAsync failed to fetch data")
                return nil
            end

            return HttpService:JSONDecode(responseInfo.Body)
        end

        --[[ SetAsync
        @tparam <string> <key> The data point / key being modified/set
        @tparam <Variant> <value>
        @tparam[opt="PUT"] <string> <method>

        Akin to DataStoreService:SetAsync(key, value) however, this method takes a third, optional paramater 'method' for use by other methods.
        This paramater will default to "PUT".

        @treturn <boolean> <success> Returns wether or not the SetAsync operation succeeded.
        @treturn <Dictionary> <responseInfo> Returns the ResponseInfo dictionary from HttpService:RequestAsync() useful for debugging/logging.
        ]]
        function Firebase:SetAsync(key, value, method)
            assert(type(key) == "string", "Roblox-Firebase SetAsync: Bad Argument #1, string expected got '"..tostring(type(key)).."'")

            method = method or "PUT"

            key = key:sub(1,1)~="/" and "/"..key or key --> Ensures key is correct form
            local dir = path .. HttpService:UrlEncode(key) .. auth --> Database path to act on

            local responseInfo
            local encoded = HttpService:JSONEncode(value)

            local requestOptions = { }
            requestOptions.Url = dir
            requestOptions.Method = method
            requestOptions.Headers = { }
            requestOptions.Headers["Content-Type"] = "application/x-www-form-urlencoded"
            requestOptions.Body = encoded

            local success, err = pcall(function() 
                local response = HttpService:RequestAsync(requestOptions)
                if response == nil or not response.Success then
                    warn("Roblox-Firebase SetAsync Operation Failure: " .. response.StatusMessage .. " ("..response.StatusCode..")")
                    if method == "PATCH" then -- UpdateAsync Request
                        print("Retrying Update Request until success...")
                        self:SetAsync(key, value, method)
                    end
                else
                    responseInfo = response
                end
            end)

            return success, responseInfo --> did it work, what was the response
        end

        --[[ DeleteAsync
        @tparam <string> <key> The data point / key being deleted

        Will delete the given data point / key from the Database, !!USE WITH CAUTION!!

        @treturn <boolean> <success> Returns wether or not the SetAsync operation succeeded.
        @treturn <Dictionary> <responseInfo> Returns the ResponseInfo dictionary from HttpService:RequestAsync() useful for debugging/logging.
        ]]
        function Firebase:DeleteAsync(key)
            assert(type(key) == "string", "Roblox-Firebase DeleteAsync: Bad Argument #1, string expected got '"..tostring(type(key)).."'")
            return self:SetAsync(key, "", "DELETE")
        end

        --[[ IncrementAsync

        @tparam <string> <key> The data point / key being modified
        @tparam[opt=1] <number> The change in value, must be a number or will default to 1, will default when nil too

        Increments the data at the given key by the provided delta (or 1 if null/NaN)
        If the data at the given Key is NaN this method will throw a warning and won't perform any SetAsync operation

        @treturn <boolean> <success> Returns wether or not the SetAsync operation succeeded.
        @treturn <Dictionary> <responseInfo> Returns the ResponseInfo dictionary from HttpService:RequestAsync() useful for debugging/logging.
        @treturn <null> Will return nil upon a failed operation (Data being NaN)
        ]]
        function Firebase:IncrementAsync(key, delta)
            assert(type(key) == "string", "Roblox-Firebase IncrementAsync: Bad Argument #1, string expected got '"..tostring(type(key)).."'")

            local data = self:GetAsync(key) or 0
            delta = type(delta)=="number" and delta or 1

            if type(data) == "number" then
                data += delta
                return self:SetAsync(key, data)
            else
                warn("RobloxFirebase: Data at key ["..key.."] is not a number, cannot update data at key ["..key.."]")
                return nil
            end
        end

        --[[ UpdateAsync
        @tparam <string> <key> The data point / key being updated
        @tparam <function> <callback> The callback function used to update the key's values
            @tparam[opt=GetAsync(key)] <Dictionary> The snapshot to be used and referred to for old data instead of acquiring the database again
            used primarily for caching and saving on Data Downloads

            This method will simply update the values at the given keys using the provided callback function and will use either the snapshot or 
                GetAsync(key) as a referencing for the old data to update.

                @treturn <boolean> <success> Returns wether or not the SetAsync operation succeeded.
                @treturn <Dictionary> <responseInfo> Returns the ResponseInfo dictionary from HttpService:RequestAsync() useful for debugging/logging.
                ]]
                function Firebase:UpdateAsync(key, callback, snapshot)
                    assert(type(key) == "string", "Roblox-Firebase UpdateAsync: Bad Argument #1, string expected got '"..tostring(type(key)).."'")
                    assert(type(callback) == "function", "Roblox-Firebase UpdateAsync: Callback must be a function")
                        local data = snapshot or self:GetAsync(key) --> Use the snapshot of data supplied instead or Download the database again

                        local updated = callback(data)
                        if updated then
                            return self:SetAsync(key, updated, "PATCH")
                        end
                    end

                    --[[ BatchUpdateAsync
                    @tparam <string> <baseKey> The 'parent' key of the keys being modified. From our previous example this could be "PlayerInformation"

                    @tparam <Dictionary> <keyValues> A dictionary of keys with their respective, current/new values. Player1:[Data=false], for example.
                    The value located here isn't used in updating the data and is more-so a personal structure preference of mine.
                    @tparam <{[string]=function}> A map of functions with string keys representing the key the function acts upon, "Player1" acts on "Player1" from keyValues

                        @tparam[opt=GetAsync(key)] <Dictionary> <snapshot> The snapshot to be used and referred to for old data instead of acquiring the database again
                        used primarily for caching and saving on Data Downloads. The keys of this dictionary must match the keys of keyValues dictionary


                        @treturn <boolean> <success> Returns wether or not the SetAsync operation succeeded.
                        @treturn <Dictionary> <responseInfo> Returns the ResponseInfo dictionary from HttpService:RequestAsync() useful for debugging/logging.
                        ]]
                        function Firebase:BatchUpdateAsync(baseKey, keyValues, callbacks, snapshot)
                            assert(type(baseKey) == "string", "Roblox-Firebase BatchUpdateAsync: Bad Argument #1, string expected got '"..tostring(type(baseKey)).."'")
                            assert(type(keyValues)=="table", "Roblox-Firebase BatchUpdateAsync: Bad Argument #2, table expected got '"..tostring(type(keyValues)).."'")
                            assert(type(callbacks)=="table", "Roblox-Firebase BatchUpdateAsync: Bad Argument #3, table expected got '"..tostring(type(callbacks)).."'")

                            local updatedKeyValues = { }

                            for key, value in pairs(keyValues) do
                                -- make sure that the key has a valid and defined callback method
                                assert(callbacks[key] ~= nil, "Roblox-Firebase BatchUpdateAsync: Key does not have a callback method, inspect callbacks table")
                                assert(type(callbacks[key])=="function", "Roblox-Firebase BatchUpdateAsync: Callback for key ("..key..") is not function, got "..tostring(type(callbacks[key])))

                                    local data = snapshot[key] or self:GetAsync(key)
                                    updatedKeyValues[key] = callbacks[key](data)
                                end

                                if #updatedKeyValues == #keyValues then -- flimsy fail safe
                                    return self:SetAsync(baseKey, updatedKeyValues, "PATCH")
                                end
                            end

                            return Firebase
                        end


                        return function(dbUrl, authToken)
                            local self = setmetatable({}, RobloxFirebase)
                            self.DefaultScope = dbUrl
                            self.AuthenticationToken = authToken
                            return self
                        end