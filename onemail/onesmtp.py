from datetime import datetime
import asyncore
from smtpd import SMTPServer,SMTPChannel
import email
from email.header import decode_header
import chardet
import redis
import re
import os

class EmlParse():
    def __init__(self,emlstring):
        self.data=emlstring
        self.msg = email.message_from_string(self.data)
        self.red = redis.Redis(db=1)
        self.parse()

    def parse(self):
        self.efrom = email.utils.parseaddr(self.msg.get("from"))[1]
        self.etos = self.msg.get("to").split(',')
        self.eto = [ email.utils.parseaddr(i)[1] for i in self.etos ]
        ## self.eto = email.utils.parseaddr(self.msg.get("to"))[1]
        print(str(self.eto))
        subjects=decode_header(self.msg.get('subject'))
        #print(subjects)
        dsubject=''
        for subject in subjects:
            cdt='utf-8' if subject[1] is None else subject[1]
            try:
                dsubject+=subject[0].decode(cdt)
            except AttributeError:
                dsubject+=subject[0]
        #print(dsubject)
        self.subject = dsubject
        self.body=[]
        self.bodyhtml=[]
        self.dict={}

        for par in self.msg.walk():
            try:
                parpld=par.get_payload(decode=True)
                #print(parpld)
                parcdt=chardet.detect(parpld) if parpld is not None else None
                if parpld is None or parcdt is None:
                #    # print('-'*20)
                    continue
                parcdt=parcdt['encoding'] if parcdt['confidence']>0.6 else 'utf-8'
                # print(parcdt)
                # print(parpld.decode(parcdt))
                try:
                    parpld=parpld.decode(parcdt)
                except AttributeError:
                    parpld=parpld 
                if '\\u' in parpld:
                    parpld=parpld.encode('utf-8').decode('unicode_escape') 
                if '</html>' in parpld:# or '<div>' in parpld:
                    self.bodyhtml.append(parpld)  
                else:
                    self.body.append(parpld)
            except Exception as e:
                print(e)            

    def show(self):
        print("from: ", self.efrom)
        print("to: ", self.eto)
        print("subject: ",self.subject)
        print("body: ",str(self.body))  
        print("html_body: ",str(self.bodyhtml))   

    def inred(self):
        self.focus()
        # self.red.setex(self.eto,(self.subject,str(self.body),str(self.bodyhtml)),60) 
        for ieto in self.eto:   
            self.red.setex(ieto,str(self.dict),120) 

            if len(self.bodyhtml) > 0 :
                code=self.bodyhtml
            else:
                code=self.body
            with open('/var/www/html/{}.html'.format(ieto),'wt', encoding='utf-8') as f:
                f.write('\n'.join(code))

    def focus(self):
        self.dict['from']=self.efrom
        self.dict['to']=self.eto
        self.dict['subject']=self.subject
        self.dict['body']=self.body
        self.dict['bodyhtml']=self.bodyhtml
        focus=None
      
        repage=''
        for i in self.body:
            if type(i) is str or type(i) is bytes:
                repage+=i
        print('repage....',repage)
        #repage=repage.strip()

        if 'support@support.digitalocean.com' in self.efrom and 'Confirm' in self.subject:
            focus=re.findall('(https://.*verification.*)',repage)[0]

        if 'noreply@github.com' in self.efrom and 'verify your email address' in self.subject:
            focus=re.findall('(https://.*verification.*)',repage)[0]

        if focus is not None:
            print("from: ", self.efrom)
            print("to: ", self.eto)
            print("focus: ",focus)
        self.dict['focus']=focus

class mySMTPChannel(SMTPChannel):
    def collect_incoming_data(self, data):
        limit = None
        if self.smtp_state == self.COMMAND:
            limit = self.max_command_size_limit
        elif self.smtp_state == self.DATA:
            limit = self.data_size_limit
        if limit and self.num_bytes > limit:
            return
        elif limit:
            self.num_bytes += len(data)
        if self._decode_data:
            #print(data,'.........................................')
            parcdt=chardet.detect(data) if data is not None else {'encoding':'utf-8','confidence':1}
            parcdt=parcdt['encoding'] if parcdt['confidence']>0.6 else 'utf-8'
            self.received_lines.append(str(data, parcdt))
        else:
            self.received_lines.append(data)

class EmlServer(SMTPServer):
    no = 0
    channel_class = mySMTPChannel
    def process_message(self, peer, mailfrom, rcpttos, data, mail_options=None, rcpt_options=None):
        filename = '%s-%d.eml' % (datetime.now().strftime('%Y%m%d%H%M%S'),
                self.no)
        print(filename)
        f = open(filename, 'w')
        #print(data)
        f.write(data)
        f.close()
        print('%s saved.' % filename)
        self.no += 1
        
        eml=EmlParse(data)
        eml.show()
        eml.inred()
    def __repr__(self):  # pragma: no cover
        return '<smtp.Server %s:%s>' % (self.addr[0], self.addr[1])

def run():
    foo = EmlServer(('0.0.0.0', 25), None,decode_data=True)
    try:
        asyncore.loop()
    except KeyboardInterrupt:
        pass


if __name__ == '__main__':
    os.system('mkdir -p /var/www/html')
    run()
