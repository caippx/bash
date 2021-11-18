#!/bin/bash

#For BtPanel Nginx 1.21.4
mkdir /www/server/nginx/modules
wget -O /www/server/nginx/modules/ngx_http_waf_module.so https://raw.githubusercontent.com/caippx/bash/master/drfytgybhunjoimkol/ngx_http_waf_module.so
cd /www/server/nginx/ 
git clone https://github.com/ADD-SP/ngx_waf
sed -i "1iload_module modules/ngx_http_waf_module.so;" /www/server/nginx/conf/nginx.conf
/www/server/nginx/sbin/nginx -s reload

echo "
示例：
  waf on; # 是否启用模块
  waf_rule_path /www/server/nginx/ngx_waf/assets/rules/; # 模块规则
  waf_mode STD !CC; # 启用普通模式并关闭CC防护
  waf_cache capacity=50; # 缓存配置
  waf_under_attack on uri=/under-attack.html; # 配置5秒盾
"
