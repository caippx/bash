#coding: utf-8
#-------------------------------------------------------------------
# 宝塔Linux面板
#-------------------------------------------------------------------
# Copyright (c) 2015-2099 宝塔软件(http://bt.cn) All rights reserved.
#-------------------------------------------------------------------
# Author: 邹浩文 <627622230@qq.com>
# Maintainer:hezhihong<272267659@qq.com>
#-------------------------------------------------------------------
"""
author: haowen
date: 2020/5/13 15:56
"""
from __future__ import print_function, absolute_import
import sys

if sys.version_info[0] == 2:
    reload(sys)
    sys.setdefaultencoding('utf-8')
import os
import time

from boto3 import client

from s3lib.osclient.osclient import OSClient
import public


class COSClient(OSClient, object):
    _name = "aws_s3"
    _title = "AWS S3对象存储"
    __error_count = 0
    __secret_id = None
    __secret_key =None
    __region_name = None
    __endpoint_url=None
    __bucket_name = None
    __oss_path = None
    __backup_path = 'bt_backup/'
    backup_path = __backup_path
    __error_msg = "ERROR: 无法连接AWS S3对象存储 !"
    reload = False
    _panel_path=public.get_panel_path()
    _aes_status=os.path.join(_panel_path,'plugin/aws_s3/aes_status')
    _a_pass=os.path.join(_panel_path,'data/a_pass.pl')

    def __init__(self, config_file=None):
        super(COSClient, self).__init__(config_file)
        self.init_config()

    def init_config(self):
        _auth = self.auth
        try:
            self.auth = None
            keys = self.get_config()
            self.__secret_id = keys[0].strip()
            self.__secret_key = keys[1].strip()
            # self.__region = keys[2]
            self.__bucket_name = keys[2].strip()
            self.__region_name = keys[3].strip() if len(keys) > 3 and keys[3].strip() else None
            self.__endpoint_url = self.normalize_endpoint_url(keys[4]) if len(keys) > 4 and keys[4].strip() else None
            self.authorize()
            # 设置存储路径和兼容旧版本
            if len(keys) >= 6:
                bp = keys[5].strip()
                if bp != "/":
                    bp = self.get_path(bp)
                if bp:
                    self.__backup_path = bp
                    self.backup_path = bp
                else:
                    self.__backup_path = self.default_backup_path
                    self.backup_path = self.default_backup_path
            else:
                self.__backup_path = self.default_backup_path
                self.backup_path = self.default_backup_path

        except:
            print(self.__error_msg)
            self.auth = _auth

    def set_config(self, conf):
        public.writeFile(self._aes_status,'True')
        if not os.path.isfile(self._a_pass):
            public.writeFile(self._a_pass,'VE508prf'+public.GetRandomString(10))
        aes_key = public.readFile(self._a_pass)
        w_data= public.aes_encrypt(conf,aes_key)

        path = os.path.join(public.get_plugin_path(),'aws_s3/config.conf')
        public.writeFile(path, w_data)
        self.reload = True
        self.init_config()
        return True

    def normalize_endpoint_url(self, endpoint_url):
        endpoint_url = endpoint_url.strip()
        if not endpoint_url:
            return None
        if '://' not in endpoint_url:
            endpoint_url = 'https://' + endpoint_url
        return endpoint_url.rstrip('/')

    def get_config(self):
        path = os.path.join(public.get_plugin_path(),'aws_s3/config.conf')
        default_config = ['', '', '', '', '', self.default_backup_path]
        if not os.path.isfile(path) or not os.path.isfile(self._a_pass): return default_config;

        conf = public.readFile(path)
        if not conf: return default_config
        decrypt_key = public.readFile(self._a_pass)
        if os.path.isfile(self._aes_status):
            try:
                conf=public.aes_decrypt(conf,decrypt_key)
            except:
                return default_config
        result = conf.split(self.CONFIG_SEPARATOR)
        if len(result) == 4:
            result = result[:3] + ['', ''] + [result[3]]
        elif len(result) == 5:
            result = result[:3] + [''] + result[3:]
        while len(result) < 6:
            result.append('')
        if result[4]:
            result[4] = self.normalize_endpoint_url(result[4]) or ''
        if not result[5]: result[5] = self.default_backup_path;
        return result

    def get_decrypt_config(self):
        """
        @name 取加密配置信息
        """
        conf = self.get_config()
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
        conf[5] = self.__backup_path
        return conf

    def re_auth(self):
        if self.auth is None or self.reload:
            self.reload = False
            return True
  
    def build_auth(self):
        kwargs = {
            'aws_access_key_id': self.__secret_id,
            'aws_secret_access_key': self.__secret_key,
        }
        if self.__region_name:
            kwargs['region_name'] = self.__region_name
        if self.__endpoint_url:
            kwargs['endpoint_url'] = self.__endpoint_url
        config = client('s3', **kwargs)
        return config

    def get_list(self, path="/"):
        try:
            data = []
            path = self.get_path(path)
            client = self.authorize()
            max_keys = 1000
            objects = client.list_objects_v2(
                Bucket=self.__bucket_name,
                MaxKeys=max_keys,
                Delimiter=self.delimiter,
                Prefix=path)
            if 'Contents' in objects:
                for b in objects['Contents']:
                    tmp = {}
                    b['Key'] = b['Key'].replace(path, '')
                    if not b['Key']: continue
                    tmp['name'] = b['Key']
                    tmp['size'] = b['Size']
                    tmp['type'] = b['StorageClass']
                    tmp['download'] = ""
                    tmp['time'] = b['LastModified'].timestamp()
                    # tmp['time'] = ""
                    data.append(tmp)

            if 'CommonPrefixes' in objects:
                for i in objects['CommonPrefixes']:
                    if not i['Prefix']: continue
                    dir_dir = i['Prefix'].split('/')[-2] + '/'
                    tmp = {}
                    tmp["name"] = dir_dir
                    tmp["type"] = None
                    data.append(tmp)

            mlist = {}
            mlist['path'] = path
            mlist['list'] = data
            return mlist
        except Exception as e:
            return public.returnMsg(False, '密钥验证失败！')

    def multipart_upload(self,local_file_name,object_name=None):
        """
        分段上传
        :param local_file_name:
        :param object_name:
        :return:
        """
        if int(os.path.getsize(local_file_name)) <= 102400000:
            return self.upload_file1(local_file_name,object_name)
        if object_name is None:
            temp_file_name = os.path.split(local_file_name)[1]
            object_name = self.__backup_path + temp_file_name

        client = self.authorize()
        part_size = 10 * 1024 * 1024
        result = client.create_multipart_upload(Bucket=self.__bucket_name, Key=object_name)
        upload_id = result["UploadId"]
        index = 0
        with open(local_file_name, "rb") as fp:
            while True:
                index += 1
                part = fp.read(part_size)
                if not part:
                    break
                print("上传分段 {}\n大小 {}".format(index, part_size))
                client.upload_part(Bucket=self.__bucket_name, Key=object_name, PartNumber=index, UploadId=upload_id, Body=part)
                # print("上传成功")
        rParts = client.list_parts(Bucket=self.__bucket_name, Key=object_name, UploadId=upload_id)["Parts"]

        partETags = []
        for part in rParts:
            partETags.append({"PartNumber": part['PartNumber'], "ETag": part['ETag']})
        print(partETags)
        client.complete_multipart_upload(Bucket=self.__bucket_name, Key=object_name, UploadId=upload_id,
                                         MultipartUpload={'Parts': partETags})
        # print("上传成功")
        return True

    def upload_file1(self,local_file_name,object_name=None):
        if object_name is None:
            temp_file_name = os.path.split(local_file_name)[1]
            object_name = self.__backup_path + temp_file_name
        client = self.authorize()
        with open(local_file_name, 'rb') as fp:
            body = fp.read()
        try:
            client.put_object(
                Bucket=self.__bucket_name,
                Key=object_name,
                Body=body,
                ContentLength=len(body)
            )
            return True
        except Exception as e:
            try:
                head_info = client.head_object(Bucket=self.__bucket_name, Key=object_name)
                if head_info and int(head_info.get('ContentLength', -1)) == len(body):
                    return True
            except Exception:
                pass
            raise e

    def delete_object_by_os(self, object_name):
        """删除对象"""

        # TODO(Linxiao) 支持目录删除
        client = self.authorize()
        response = client.delete_object(
            Bucket=self.__bucket_name,
            Key=object_name,
        )
        return response is not None

    def download_file(self, object_name,local_file):
        # 连接OSS服务器
        client = self.authorize()
        try:
            with open(local_file,'wb') as f:
                client.download_fileobj(
                    self.__bucket_name,
                    object_name,
                    f
                )
        except:
            print(self.__error_msg, public.get_error_info())
            
    # def get_lib(self):
    #     import json
    #     list = {
    #         "name": "AWS S3",
    #         "type": "Cron job",
    #         "ps": "Package and backup website or database to AWS S3, <a class='link' "
    #               "href='https://portal.qiniu.com/signup?code=3liz7nbopjd5e' "
    #               "target='_blank'>点击申请</a>",
    #         "status": 'false',
    #         "opt": "aws_s3",
    #         "module": "boto3",
    #         "script": "aws_s3",
    #         "help": "https://www.bt.cn/bbs/thread-17442-1-1.html",
    #         "SecretId": "SecretId|请输入SecretId|AWS S3的SecretId",
    #         "SecretKey": "SecretKey|请输入SecretKey|AWS S3 的SecretKey",
    #         "region": "存储地区|请输入对象存储地区|例如 ap-chengdu",
    #         "Bucket": "存储名称|请输入绑定的存储名称",
    #         "check": ["/usr/lib/python2.6/site-packages/boto3/__init__.py",
    #                   "/usr/lib/python2.7/site-packages/boto3/__init__.py",
    #                   "/www/server/panel/pyenv/lib/python3.7/site-packages/boto3/__init__.py"]
    #     }
    #     lib = '/www/server/panel/data/libList.conf'
    #     lib_dic = json.loads(public.readFile(lib))
    #     for i in lib_dic:
    #         if list['name'] in i['name']:
    #             return True
    #         else:
    #             pass
    #     lib_dic.append(list)
    #     public.writeFile(lib, json.dumps(lib_dic))
    #     return lib_dic
