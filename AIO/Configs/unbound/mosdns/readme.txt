#mosdns的逻辑说明。
chinalist.txt文件是指定要走国内的域名表
fakelist.txt文件是指定要走fake的域名表
unboundlist.txt文件是指走unbound判断的表
以上三个文件优先级为：chinalist.txt > unboundlist.txt > fakelist.txt

proxy_ip.txt文件是需要返回真实ip的客户端IP地址表
fake_ip.txt文件是需要返回fake-ip的客户端IP地址表
例如：
       proxy_ip.txt填写10.0.0.10  ，则客户端返回真实ip，包括国内外也是真实ip。
       fake_ip.txt填写10.0.0.11  ，则客户端国内域名返回真实ip，国外域名返回fake-ip。
       不在这两个表内的客户端，    则客户端国内域名返回真实ip，国外域名返回nxmodian。
       切记同一个ip只能填到其中一个表。
       优先级说明： proxy_ip.txt > fake_ip.txt  如只需要fake模式请在fake_ip.txt表填入0.0.0.0/0 proxy_ip.txt表请留空。


下面四个逻辑文件中分别有一个_false，如果改为_true就启用

  - tag: query_is_fallback_primary_domain
    type: sequence
    args:
      - matches: 
        - _false                                   #如设置为true则全局unbound解析域名，223不参与解析。
         

  - tag: query_is_fake_domain
    type: sequence
    args:
      - matches:
        -  _false  #如设置为true则启用cn的域名表，启用后如匹配上将会跳过后面所有流程直接返回结果，否则将进行geoip匹配流程最终走fake还是read就看geoip里面是否判断为中国，用fake模式建议开启。
       - matches:
        -  _false  #如设置为true则启用非cn的域名表，启用后如匹配上将会跳过后面所有流程直接返回结果，否则将进行geoip匹配流程最终走fake还是read就看geoip里面是否判断为中国，用fake模式建议开启。


  - tag: query_is_read_google_domain
    type: sequence
    args:
        -  _false                                   #如设置为true则启用非cn的域名表，对read模式有帮助，对fake没作用。


#注意用O佬新版nftables规则，需要singbox vm主机使用fake模式，不用fake模式本机国外流量无法代理，nftables请看下方,注意nft文件里面的网卡地址要改为自己的网卡地址。
table inet singbox {
	set local_ipv4 {
		type ipv4_addr
		flags interval
		elements = {
			10.0.0.0/8,
			127.0.0.0/8,
			169.254.0.0/16,
			172.16.0.0/12,
			192.168.0.0/16,
			240.0.0.0/4
		}
	}

	set local_ipv6 {
		type ipv6_addr
		flags interval
		elements = {
			::ffff:0.0.0.0/96,
			64:ff9b::/96,
			100::/64,
			2001::/32,
			2001:10::/28,
			2001:20::/28,
			2001:db8::/32,
			2002::/16,
			fc00::/7,
			fe80::/10
		}
	}

	set dns_ipv4 {
		type ipv4_addr
		elements = {
			8.8.8.8,
			8.8.4.4,
			1.1.1.1,
			1.0.0.1
		}
	}

	set dns_ipv6 {
		type ipv6_addr
		elements = {
                  2001:4860:4860::8888,
                  2001:4860:4860::8844,
		        2606:4700:4700::1111,
		        2606:4700:4700::1001
		}
	}

        set fake_ipv4 {
                type ipv4_addr
                flags interval
                elements = {
                        28.0.0.0/8
                }
        }

        set fake_ipv6 {
                type ipv6_addr
                flags interval
                elements = {
                        f2b0::/18
                }
        }

        chain nat-prerouting {
                type nat hook prerouting priority dstnat; policy accept;
                fib daddr type { unspec, local, anycast, multicast } return
                ip daddr @local_ipv4 return
                ip6 daddr @local_ipv6 return
                udp dport { 123 } return
                ip daddr @dns_ipv4 meta l4proto tcp redirect to :7877
                ip6 daddr @dns_ipv6 meta l4proto tcp redirect to :7877
                iifname { lo, enp6s18 } meta l4proto { tcp } redirect to :7877 
        }

        chain nat-output {
                type nat hook output priority filter; policy accept;
                fib daddr type { unspec, local, anycast, multicast } return
                ip daddr @local_ipv4 return
                ip6 daddr @local_ipv6 return
                udp dport { 123 } return
                ip daddr @fake_ipv4 meta l4proto tcp redirect to :7877
                ip6 daddr @fake_ipv6 meta l4proto tcp redirect to :7877
                ip daddr @dns_ipv4 meta l4proto tcp redirect to :7877
                ip6 daddr @dns_ipv6 meta l4proto tcp redirect to :7877
                iifname { lo, enp6s18 } meta l4proto { tcp } redirect to :7877 

        }

	chain singbox-tproxy {
		fib daddr type { unspec, local, anycast, multicast } return
		ip daddr @local_ipv4 return
		ip6 daddr @local_ipv6 return
		udp dport { 123 } return
		meta l4proto { udp } meta mark set 1 tproxy to :7896 accept
	}

	chain singbox-mark {
		fib daddr type { unspec, local, anycast, multicast } return
		ip daddr @local_ipv4 return
		ip6 daddr @local_ipv6 return
		udp dport { 123 } return
		meta mark set 1
	}

	chain mangle-output {
		type route hook output priority mangle; policy accept;
		meta l4proto { udp } skgid != 1 ct direction original goto singbox-mark
	}

	chain mangle-prerouting {
		type filter hook prerouting priority mangle; policy accept;
                ip daddr @dns_ipv4 meta l4proto {  udp } ct direction original goto singbox-tproxy
                ip6 daddr @dns_ipv6 meta l4proto {  udp } ct direction original goto singbox-tproxy
		iifname { lo, enp6s18 } meta l4proto {  udp } ct direction original goto singbox-tproxy
	}
}