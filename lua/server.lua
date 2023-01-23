local resp = require('resp')
local ngx_re = require "ngx.re"
local lrucache = require "resty.lrucache"
local cache, err = lrucache.new(1024) 

if not cache then
    ngx.log(ngx.ERR,"failed to create the cache: " .. (err or "unknown"))
end

local M = { _VERSION = "0.01" }

local function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end
local function parse_cmd(packet, remaning_buffer)
    ngx.log(ngx.INFO, "received command : ", packet)
    local consumed, args, typ = resp.decode( packet )
    ngx.log(ngx.INFO, "consumed: ", dump(consumed))
    ngx.log(ngx.INFO, "args: ", dump(args))
    ngx.log(ngx.INFO, "typ: ", dump(typ))
    local packet_len = string.len(packet)
    ngx.log(ngx.INFO, "received command length: ", packet_len)
            
    
    if not args then
        ngx.log(ngx.ERR, "Failed to parse command:", packet)
        return ngx.say("-ERR BAD Command." )
    end
    
    local cmd = string.upper(args[1])
    ngx.log(ngx.INFO, "Command received: ", cmd)

    remaning_buffer = ""
    if consumed < packet_len then  
      ngx.log(ngx.INFO, "Remaining buffer: ", packet_len - consumed)
      remaning_buffer = string.sub(packet, consumed+1, packet_len)
    end

    return cmd, args, consumed, remaning_buffer
end

--- authenticate()
--- read data, parse login command
 function M.authenticate(sock, remaning_buffer)
    ngx.log(ngx.INFO, "Authenticate client")
    local packet, err, args_len
    sock:settimeout(60000)  -- one second timeout
    packet, err = sock:receiveany(16384)
    if not packet then
        ngx.log(ngx.ERR, "failed to read packet content: ", err)
        return ngx.say("failed to read packet content: " .. err)
    end
    local packet = remaning_buffer .. packet
    remaning_buffer = ""
    ngx.log(ngx.INFO, "received command: ", packet)
    local cmd, args, remaning_buffer = parse_cmd(packet, remaning_buffer)
    if args then
      args_len = table.getn(args)
    else
      args_len = 0
    end

    if cmd ~= "AUTH" then
        sock:send("-ERR You must login first")
        return false
    end 
    
    ngx.log(ngx.INFO, "username: ", args[2])
    ngx.log(ngx.INFO, "password: ", args[3])

    if args[2] ~= "rohit" or args[3] ~= "password" then 
        return ngx.say("-WRONGPASS invalid username-password pair or user is disabled.")
    end 
    --local msg = resp.encode('OK')
    sock:send('+OK\r\n')
    --sock:send(msg)
    return true , remaning_buffer

end

local function tokenize(data)
    return string. reverse(data)
end


local function process_cmd(sock, cmd, args)
            ngx.log(ngx.INFO, "in process_cmd:", cmd)
            if cmd == "QUIT" or cmd == "BYE" then
                sock:send('+OK\r\n')
                ngx.flush(true)
                -- sock:close()
                return false
            end
            if cmd == "AUTH" then
                if args[2] ~= "rohit" or args[3] ~= "password" then 
                    sock:send("-WRONGPASS invalid username-password pair or user is disabled.\r\n")
                    cache:delete(authenticated_key)
                    return true
                end 
                local authenticated_key = ngx.var.remote_addr .. ':' .. ngx.var.remote_port
                cache:set(authenticated_key, true)
                local authenticated_val = cache:get(key)
                ngx.log(ngx.INFO, "Client authenticated_val from cache:", authenticated )
                ngx.log(ngx.INFO, "Authenticated successfully:", authenticated_val)
                ngx.log(ngx.WARN, "Command AUTH, Resp: +OK")
                return sock:send('+OK\r\n')
            elseif cmd == "PING" then 
                if args[2] then 
                    local resp_msg  = '+"' .. tostring(args[2] .. '"\r\n')
                    ngx.log(ngx.INFO, "Sending PING response with message:" , resp_msg)
                    ngx.log(ngx.WARN, "Command PING, Resp:",  resp_msg)
                    sock:send(resp_msg)
                    return true
                else 
                   ngx.log(ngx.INFO, "Sending PONG")
                   ngx.log(ngx.WARN, "Command PING, Resp:+PONG")
                    sock:send('+PONG\r\n')
                    return true
                end
            end
            -- commands requires authentication
            -- local authenticated_key = ngx.var.remote_addr .. ':' .. ngx.var.remote_port
            -- local authenticated_val = cache:get(authenticated_key)
            -- ngx.log(ngx.INFO, "Client authenticated:", authenticated_val )
            -- if not authenticated_val then 
            --      ngx.log(ngx.INFO, "Client not authenticated:", authenticated_key )
            --      sock:send("-ERR You must login first\r\n")
            --      return true
            -- end
            if cmd == "CONFIG" then 
                ngx.log(ngx.WARN, "Command CONFIG, Resp:-ERR Not Supported")
                sock:send('-ERR Not Supported\r\n')
                return true
            elseif cmd == "GET" then 
                ngx.log(ngx.WARN, "Command GET, Resp:+GETVAL")
                sock:send("+GETVAL\r\n")
                return true
            elseif cmd == "SET" or cmd == "DEL" then 
                ngx.log(ngx.WARN, "Command " .. cmd .. "Resp:+OK")
                sock:send('+OK\r\n')
                return true
            end
            if cmd == "HGET" then
                ngx.log(ngx.INFO, "HGET command received")
                 if args[2] == nil or args[3] == nil  then
                    return sock:send("-ERR must pass key and field\r\n")
                 end
                 ngx.log(ngx.INFO, "key: ", args[2])
                 ngx.log(ngx.INFO, "field: ", args[3])
                 local msg = resp.encode(tokenize(args[3]))
                 sock:send(msg)
                 return true
            elseif cmd == "TOKENIZE" then
                ngx.log(ngx.INFO, "HGET command received")
                 if args[2] == nil or args[3] == nil  then
                    sock:send("-ERR must pass key and field\r\n")
                    return true
                 end
                 ngx.log(ngx.INFO, "key: ", args[2])
                 ngx.log(ngx.INFO, "field: ", args[3])
                 local msg = resp.encode(tokenize(args[3]))
                 sock:send(msg)
                 return true
            else 
                return sock:send("-ERR unknown command '" .. cmd .. "'\r\n")
            end
            
            sock:send('+OK\r\n')
            return true
            
    
end

function M.run()
    local sock = assert(ngx.req.socket(true))
    sock:settimeout(60000)  -- one second timeout
    ngx.log(ngx.WARN, "**Connection received from:", tostring(ngx.var.remote_addr) .. ":" .. tostring(ngx.var.remote_port))
            
    ngx.log(ngx.INFO, "$connection: ", tostring(ngx.var.connection))
    ngx.log(ngx.INFO, "$remote_addr: ", tostring(ngx.var.remote_addr))
    ngx.log(ngx.INFO, "$remote_port: ", tostring(ngx.var.remote_port))
    local buffer = ""
    while true do
        
         ngx.log(ngx.DEBUG, "In main loop")
         local packet, err, args_len
         sock:settimeout(60000)  -- one second timeout
          packet, err = sock:receiveany(16384)
          if not packet or err then
            ngx.log(ngx.WARN, "**Connection closed from:", tostring(ngx.var.remote_addr) .. ":" .. tostring(ngx.var.remote_port) .. ". Reason:", err)
    
            --ngx.log(ngx.WARN, "failed to read packet content: ", err)
            sock:send("failed to read packet content: " .. err)
            return false
          end
           -- local packet = tostring(packet)
          --ngx.log(ngx.INFO, "received command: ", packet)

          local packet = buffer .. packet
          buffer = ""
          local cmd, args, consumed, buffer = parse_cmd(packet, buffer)
          if not process_cmd(sock, cmd, args) then
              ngx.flush(true)
              ngx.log(ngx.INFO, "Exiting loop");
             return
         end
          --ngx.flush(true)
          ngx.log(ngx.INFO, "consumed:", consumed);
           ngx.log(ngx.INFO, "remaning buffer:", buffer);
          ngx.log(ngx.INFO, "remaning buffer length:", string.len(buffer));
          
         while consumed > 0 and string.len(buffer) > 0 do 
            ngx.log(ngx.INFO, "Still ");
            local remaning_buffer = buffer
            buffer = ""
            cmd, args, consumed, buffer = parse_cmd(remaning_buffer, buffer)
            if not process_cmd(sock, cmd, args) then
              ngx.flush(true)
              ngx.log(ngx.INFO, "Exiting loop");
             return
            end 
            ngx.log(ngx.INFO, "consumed:", consumed);
             ngx.log(ngx.INFO, "remaning buffer:", buffer);
            ngx.log(ngx.INFO, "remaning buffer length:", string.len(buffer));
        end
        
       
    end
     
end


return M