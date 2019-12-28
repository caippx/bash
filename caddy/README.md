``
bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/caippx/bash/master/caddy/proxy.sh')
``


##支持Ubuntu16+ debian9+


**手动修改替换内容规则**


```
filter rule {
    path .*
    search_pattern "需要替换内容"
    replacement "内容"
}
```


加到domain{}里面 再运行 'ppxcaddy restart' 就可以了


 演示站：
 https://gg.ppxwo.cf
