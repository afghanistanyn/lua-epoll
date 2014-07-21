local socket=require("socket")
local epoll=require("epoll")
local bit = require("bit")
local http = require("socket.http")
local ltn12 = require("ltn12")

function http.get()
    local t={}
    local ok,code,headers,status=http.request{
        url="http://www.baidu.com",
        sink = ltn12.sink.table(t)
    }
    coroutine.yield(ok,code,headers,status,table.concat(t))
end

function create_nonblocking_socket(args)
    port=args.port
    if not port then
        return nil,"argument port is needed"
    end
    local listen_num=args.listen_num or 10000

    local s=socket.tcp()
    s:setoption("reuseaddr",true)
    local ok,err=s:bind("*",port)
    if not ok then
        return nil,err
    end
    s:listen(listen_num)
    s:settimeout(0)
    local sfd=s:getfd()
    epoll.setnonblocking(sfd)

    return sfd,s
end

local sfd,s=create_nonblocking_socket{port=6333}
if not sfd then print(s) end

epfd=epoll.create()
epoll.register(epfd,sfd,bit.bor(epoll.EPOLLIN,epoll.EPOLLET))

local map_fd_sock={}
local coroutines={}
while true do
    local events=epoll.wait(epfd,-1,512)
    for fd,event in pairs(events) do
        if fd==sfd then
            while true do
                local c,err=s:accept()
                if not c then
                    if err=="timeout" then 
                        break
                    else
                        print(err)
                        break
                    end
                end
                c:settimeout(0)
                local cfd=c:getfd()
                map_fd_sock[cfd]=c
                epoll.setnonblocking(cfd)
                epoll.register(epfd,cfd,bit.bor(epoll.EPOLLIN,epoll.EPOLLET))
            end
        elseif bit.band(event,epoll.EPOLLIN) ~= 0 then
            while true do
                local buf,err=map_fd_sock[fd]:receive("*l")
                if not buf then
                    epoll.modify(epfd,fd,bit.bor(epoll.EPOLLOUT,epoll.EPOLLET))
                    break
                end
                print(buf)
            end
        elseif bit.band(event,epoll.EPOLLOUT) ~= 0 then
            local co=coroutine.create(http.get)
            local t,ok,code,headers,status,text=coroutine.resume(co)
            if not t then
                print(t,ok,code,headers,status,text)
            end
            
            local ok,err=map_fd_sock[fd]:send("HTTP/1.0 200 OK\r\n\r\n"..text.."\n")
            if not ok then print(err) end
            epoll.unregister(epfd,fd)
            map_fd_sock[fd]:close()
            map_fd_sock[fd]=nil
        elseif bit.band(event,epoll.EPOLLHUP) ~= 0 then
            print("HUP")
            epoll.unregister(epfd,fd)
            map_fd_sock[fd]:close()
            map_fd_sock[fd]=nil
        end
    end
end

epoll.unregister(epfd,sfd)
epoll.close(epfd)
s:close()
