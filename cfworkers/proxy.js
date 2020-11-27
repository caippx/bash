addEventListener(
  "fetch",event => {
     let url=new URL(event.request.url);
     const { searchParams } = url
     let name = searchParams.get('url')
     if(!name){
       name = "https://p.pstatp.com/origin/ff1200011e53e504c49c"
     }
     url=name;
     if(url == ""){
       url="https://p.pstatp.com/origin/ff1200011e53e504c49c"
     }
     let request=new Request(url,event.request);
     const init = {
        headers: {
         "User-Agent":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.3538.77 Safari/537.36",
         
        },
    }
     event.respondWith(
       fetch(request,init))
  }
)
