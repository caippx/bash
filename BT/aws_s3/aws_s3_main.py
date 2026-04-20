#!/usr/bin/python
#coding: utf-8
# -------------------------------------------------------------------
# 宝塔Linux面板
# -------------------------------------------------------------------
# Copyright (c) 2015-2099 宝塔软件(http://bt.cn) All rights reserved.
# -------------------------------------------------------------------
# Author: zhwen <zhw@bt.cn>
# Maintainer:hezhihong<272267659@qq.com>
# -------------------------------------------------------------------

# -------------------------------------------------------------------
# AWSS3存储
# -------------------------------------------------------------------
from __future__ import absolute_import, print_function
import sys

from s3lib.osclient.itools import switch_environment
from s3lib.client.aws_s3 import COSClient
from boto3 import client
if sys.version_info[0] == 2:
    reload(sys)
    sys.setdefaultencoding('utf-8')

switch_environment()
import public
import types



# 腾讯云oss 的类
class aws_s3_main:
    __client = None
    __before_error_msg="ERROR: 检测到有*号，输入信息为加密信息或者信息输入不正确！请检查[" \
                  "SecretId/SecretKey/Bucket]设置是否正确!"


    def __init__(self):
        self.get_lib()

    @property
    def client(self):
        if self.__client:
            return self.__client
        self.__client = COSClient()
        # 使用 types.MethodType 将 new_get_decrypt_config 绑定到 self.__client 实例上
        self.__client.get_decrypt_config = types.MethodType(self.new_get_decrypt_config, self.__client)
        self.__client.init_config = types.MethodType(self.new_init_config, self.__client)
        self.__client.build_auth = types.MethodType(self.new_build_auth, self.__client)
        return self.__client
    # 定义新的 get_decrypt_config 方法
    def new_get_decrypt_config(self, client_instance):
        """
        更新后的加密配置信息获取逻辑
        """
        conf = client_instance.get_config()  # 使用 client_instance 调用
        if not conf[0] or not conf[1] or not conf[2]:
            return conf
        conf[0] = conf[0][:5] + '*' * 10 + conf[0][-5:]
        conf[1] = conf[1][:5] + '*' * 10 + conf[1][-5:]
        conf[2] = conf[2][:2] + '*' * 10 + conf[2][-2:]

        if conf[4] and '.' in conf[4] and not conf[4].endswith('/'):
            conf[4] = conf[4][:8] + '*' * 10 + conf[4][-8:]
        else:
            conf[4] = ""
        while len(conf) < 6:
            conf.append("")
        # 访问名称修饰后的 __backup_path
        conf[5] = client_instance._COSClient__backup_path
        return conf
    # 新的 init_config 方法
    def new_init_config(self, client_instance):
        _auth = client_instance.auth
        try:
            client_instance.auth = None
            keys = client_instance.get_config()
            client_instance._COSClient__secret_id = keys[0].strip()
            client_instance._COSClient__secret_key = keys[1].strip()
            client_instance._COSClient__bucket_name = keys[2].strip()
            client_instance._COSClient__region_name = keys[3].strip() if len(keys) > 3 and keys[3].strip() else None
            client_instance._COSClient__endpoint_url = client_instance.normalize_endpoint_url(keys[4]) if len(keys) > 4 and keys[4].strip() else None
            client_instance.authorize()

            # 设置存储路径和兼容旧版本
            if len(keys) >= 6:
                bp = keys[5].strip()
                if bp != "/":
                    bp = client_instance.get_path(bp)
                if bp:
                    client_instance._COSClient__backup_path = bp
                    client_instance.backup_path = bp
                else:
                    client_instance._COSClient__backup_path = client_instance.default_backup_path
                    client_instance.backup_path = client_instance.default_backup_path
            else:
                client_instance._COSClient__backup_path = client_instance.default_backup_path
                client_instance.backup_path = client_instance.default_backup_path

        except:
            client_instance.auth = _auth

    # 新的 build_auth 方法
    def new_build_auth(self, client_instance):
        kwargs = {
            'aws_access_key_id': client_instance._COSClient__secret_id,
            'aws_secret_access_key': client_instance._COSClient__secret_key,
        }
        if client_instance._COSClient__region_name:
            kwargs['region_name'] = client_instance._COSClient__region_name
        if client_instance._COSClient__endpoint_url:
            kwargs['endpoint_url'] = client_instance._COSClient__endpoint_url
        config = client('s3', **kwargs)
        return config


    def get_config(self, get):
        return self.client.get_decrypt_config()

    def set_config(self, get):
        try:
            secret_id = get.secret_id.strip()
            secret_key = get.secret_key.strip()
            bucket_name = get.Bucket.strip()
            region_name = get.region.strip() if hasattr(get, 'region') else ''
            backup_path = get.backup_path.strip()
            endpoint_url = self.client.normalize_endpoint_url(get.endpoint_url) if hasattr(get, 'endpoint_url') and get.endpoint_url.strip() else None
            if not backup_path:
                backup_path = 'bt_backup/'
            # 验证前端输入
            values = [secret_id,
                      secret_key,
                      bucket_name,
                      backup_path]
            for v in values:
                if not v:
                    return public.returnMsg(False, 'API资料校验失败，请核实!')
            if secret_id.find('*') != -1 or secret_key.find('*') != -1 or bucket_name.find('*') != -1 or (endpoint_url and endpoint_url.find('*') != -1):
                 return public.returnMsg(False, self.__before_error_msg)
            conf = self.client.CONFIG_SEPARATOR.join([
                secret_id,
                secret_key,
                bucket_name,
                region_name,
                endpoint_url or '',
                backup_path
            ])
            if self.client.set_config(conf):
                if self.client.get_list():
                    return public.returnMsg(True, '设置成功!')
            return public.returnMsg(False, 'API资料校验失败，请核实!')
        except Exception as e:
            print(e)
            return public.returnMsg(False, 'API资料校验失败，请核实!')

    # 上传文件
    def upload_file(self, filename):
        return self.client.resumable_upload(filename)

    # 创建目录
    # def create_dir(self, get):
    #     path = get.path + get.dirname;
    #     if self.client.create_dir(path):
    #         return public.returnMsg(True, '目录{}创建成功!'.format(path));
    #     else:
    #         return public.returnMsg(False, "创建失败！")

    # 取回文件列表
    def get_list(self, get):
        return self.client.get_list(get.path)

    # 删除文件
    def delete_file(self, get):
        try:
            filename = get.filename
            path = get.path
            if path != "/":
                if path[0] == "/":
                    path = path[1:]

            if path[-1] != "/":
                file_name = path + "/" + filename
            else:
                file_name = path + filename

            if file_name[-1] == "/":
                return public.returnMsg(False, "暂时不支持目录删除！")

            if file_name[:1] == "/":
                file_name = file_name[1:]
            if self.client.delete_object(file_name):
                return public.returnMsg(True, '删除成功')
            return public.returnMsg(False, '文件{}删除失败, path:{}'.format(file_name,
                                                                      get.path))
        except:
            return public.get_error_info()

    def download_file(self, get):
        # 连接OSS服务器
        print('开始下载文件')
        self.client.download_file(get.object_name,get.local_file)
        print('下载成功')

    def get_lib(self):
        import json
        info = {
            "name": "AWS S3对象存储",
            "type": "计划任务",
            "ps": "将网站或数据库打包备份到腾讯云COS对象存储空间,, <a class='link' "
                  "href='https://portal.qiniu.com/signup?code=3liz7nbopjd5e' "
                  "target='_blank'>点击申请</a>",
            "status": 'false',
            "opt": "aws_s3",
            "module": "boto3",
            "script": "aws_s3",
            "help": "https://www.bt.cn/bbs/thread-17442-1-1.html",
            "SecretId": "SecretId|请输入SecretId|AWS S3的SecretId",
            "SecretKey": "SecretKey|请输入SecretKey|AWS S3 的SecretKey",
            "region": "存储地区|请输入对象存储地区|例如 ap-chengdu",
            "Bucket": "存储名称|请输入绑定的存储名称",
            "check": ["/usr/lib/python2.6/site-packages/boto3/__init__.py",
                      "/usr/lib/python2.7/site-packages/boto3/__init__.py",
                      "/www/server/panel/pyenv/lib/python3.7/site-packages/boto3/__init__.py"]
        }
        lib = '/www/server/panel/data/libList.conf'
        lib_dic = json.loads(public.readFile(lib))
        for i in lib_dic:
            if info['name'] in i['name']:
                return True
            else:
                pass
        lib_dic.append(info)
        public.writeFile(lib, json.dumps(lib_dic))
        return lib_dic


if __name__ == "__main__":
    import json

    import panelBackup

    new_version = True if panelBackup._VERSION >= 1.2 else False
    if not new_version:
        data = None
        client = COSClient()
        type = sys.argv[1]
        if type == 'site':
            if sys.argv[2] == 'ALL':
                client.backupSiteAll(sys.argv[3])
            else:
                client.backupSite(sys.argv[2], sys.argv[3])
            exit()
        elif type == 'database':
            if sys.argv[2] == 'ALL':
                client.backupDatabaseAll(sys.argv[3])
            else:
                client.backupDatabase(sys.argv[2], sys.argv[3])
            exit()
        elif type == 'path':
            client.backupPath(sys.argv[2], sys.argv[3])
        elif type == 'upload':
            data = client.upload_file(sys.argv[2])
        elif type == 'download':
            data = client.generate_download_url(sys.argv[2])
        elif type == 'get':
            data = client.get_object_info(sys.argv[2])
        elif type == 'list':
            data = client.get_list("/")
        elif type == 'delete_file':
            data = client.delete_file(sys.argv[2])
        elif type == 'lib':
            data = client.get_lib()
        else:
            data = 'ERROR: 参数不正确!'
    else:
        client = COSClient()
        client.execute_by_comandline(sys.argv)
