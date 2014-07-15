lua-epoll
=========

Lua的epoll模块

epoll module for Lua

eventmask(event掩码)
---

Constant	      Meaning
EPOLLIN	        Available for read
EPOLLOUT	      Available for write
EPOLLPRI	      Urgent data for read
EPOLLERR	      Error condition happened on the assoc. fd
EPOLLHUP	      Hang up happened on the assoc. fd
EPOLLET	        Set Edge Trigger behavior, the default is Level Trigger behavior
EPOLLONESHOT	  Set one-shot behavior. After one event is pulled out, the fd is internally disabled
EPOLLRDNORM	    Equivalent to EPOLLIN
EPOLLRDBAND	    Priority data band can be read.
EPOLLWRNORM	    Equivalent to EPOLLOUT
EPOLLWRBAND	    Priority data may be written.
EPOLLMSG	      Ignored.

API:
---

#### ok,err=epoll.setnonblocking(fd)
set a file descriptor nonblocking.

#### epfd,err=epoll.create()
Returns an epoll file descriptor.

#### ok,err=epoll.register(epfd,fd,eventmask)
Register eventmask of a file descriptor onto epoll file descriptor.

#### ok,err=epoll.modify(epfd,fd,eventmask)
Modify eventmask of a file descriptor.

#### ok,err=epoll.unregister(epfd,fd)
Remove a registered file descriptor from the epoll file descriptor.

#### events,err=epoll.wait(epfd,timeout,max_events)
Wait for events. 

#### ok,err=epoll.close(epfd)
Close epoll file descriptor.

