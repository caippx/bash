#coding:utf-8
from flask import Flask
from flask import make_response
import redis
import os
import argparse
app=Flask(__name__)

pool = redis.ConnectionPool(host='localhost', port=6379, decode_responses=True)
emailredis = redis.Redis(db=1)
parser = argparse.ArgumentParser(description="One Mail Web Api")
parser.add_argument('-p','--port', default='80')
args = parser.parse_args()
web_port = args.port

@app.route('/<em>')
def api_mail(em):
    try:
        emdict=eval(emailredis.get(em).decode('utf-8'))
        emdict['bodyhtml']=emdict['bodyhtml']
        emdict['body']=emdict['body']
        if len(emdict['bodyhtml']) > 0 :
            code=emdict['bodyhtml']
        else:
            code=emdict['body']
        return allow_ajax('\n'.join(code))
    except Exception as e:
        return allow_ajax('None')

def allow_ajax(res):
    response=make_response(res)
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'POST'
    response.headers['Access-Control-Allow-Headers'] = 'x-requested-with,content-type'
    return response

if __name__ == '__main__':
    os.system('python3 ./smtp.py &')
    app.run(host='0.0.0.0',port=web_port,use_debugger=False,threaded=True)
