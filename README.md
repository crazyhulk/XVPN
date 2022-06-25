# XVPN
`XVP` 是一个简单的 iOS 基于 tun 设备的 VPN 客户端.


## 工作原理
```
+---------------+               +---------------+
|               |               |               |
|               |               |               |
+-------+-------+               +-------^-------+
        |                               |
+-------v-------+  works here   +-------+-------+
|Network Layer  <---------------+Network Layer  |
|Tun Interface  +--------------->Tun Interface  |
+-------+-------+               +-------^-------+
        |                               |
+-------v-------+               +-------+-------+
|Data Link Layer|               |Data Link Layer|
|Tap Interface  |               |Tap Interface  |
+-------+-------+               +-------^-------+
        |                               |
+-------v-------+               +-------+-------+
|Physical Layer |               |Physical Layer |
|               |               |               |
+-------+-------+               +-------^-------+
        |                               |
        +-------------------------------+
```

## 对应的其他客户端
 - [tun](https://github.com/CrazyHulk/tun)：服务端
 - [XVPN](https://github.com/CrazyHulk/XVPN)：项目的 iOS 客户端
 - [XVPN-Android](https://github.com/CrazyHulk/XVPN-Android)： Android 客户端
 - [macvpn](https://github.com/CrazyHulk/macvpn)：macOS 客户端
