package main

import (
	"encoding/json"
	"io/ioutil"
	"net/http"
	"strconv"
	"strings"
	"time"
)

type Config struct {
	Port              int      `json:"port"`
	CertFile          string   `json:"certFile"`
	KeyFile           string   `json:"keyFile"`
	AllowedExtensions []string `json:"allowedExtensions"`
}

func main() {
	// 读配置文件
	cfgData, err := ioutil.ReadFile("config.json")
	if err != nil {
		panic("读取配置文件失败: " + err.Error())
	}

	var cfg Config
	err = json.Unmarshal(cfgData, &cfg)
	if err != nil {
		panic("解析配置文件失败: " + err.Error())
	}

	server := &http.Server{
		Addr: ":" + strconv.Itoa(cfg.Port),
		Handler: http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if r.Method != http.MethodGet {
				disconnect(w)
				return
			}

			path := r.URL.Path
			allowed := false
			for _, ext := range cfg.AllowedExtensions {
				if strings.HasSuffix(path, ext) {
					allowed = true
					break
				}
			}
			if !allowed {
				disconnect(w)
				return
			}

			filePath := path[1:]
			if strings.Contains(filePath, "..") {
				disconnect(w)
				return
			}

			http.ServeFile(w, r, filePath)
		}),
	}

	err = server.ListenAndServeTLS(cfg.CertFile, cfg.KeyFile)
	if err != nil {
		panic(err)
	}
}

func disconnect(w http.ResponseWriter) {
	hj, ok := w.(http.Hijacker)
	if !ok {
		return
	}
	conn, _, err := hj.Hijack()
	if err != nil {
		return
	}
	conn.SetDeadline(time.Now().Add(1 * time.Millisecond))
	conn.Close()
}


#CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o server server.go
