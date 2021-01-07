function go1(){
echo $1
}
function go2(){
echo $2
}
function go3(){
echo $3
}

[[ -n $1 ]] && go1
[[ -n $2 ]] && go2
[[ -n $3 ]] && go3
